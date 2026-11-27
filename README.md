<p align="center">
  <img src="logo.png" alt="Logo de PortAlert" width="140">
</p>

<h1 align="center">PortAlert · Base de datos</h1>

<p align="center">
  Esquema PostgreSQL, reglas de detección y herramientas de respaldo de PortAlert.
</p>

<p align="center">
  <img alt="PostgreSQL 16" src="https://img.shields.io/badge/PostgreSQL-16-336791?logo=postgresql&logoColor=white">
  <img alt="Docker Compose" src="https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white">
  <img alt="Licencia MIT" src="https://img.shields.io/badge/Licencia-MIT-green">
</p>

![Panel de PortAlert](preview.png)

## Acerca de PortAlert
PortAlert monitorea los puertos abiertos y los ejecutables de un equipo personal, y avisa cuando algo cambia o luce sospechoso. Un agente en el equipo envía reportes periódicos al backend, que los compara contra un conjunto de reglas y genera alertas por severidad (baja, media, alta y crítica) que se revisan desde el panel web.

Este repositorio contiene **solo la capa de datos**: PostgreSQL 16 con el esquema y las reglas iniciales. Vive sola: no necesita el backend, el front ni el agente para levantarse.

## Estructura
```
database/
├── init/                 # Se ejecuta al crear el volumen por primera vez
│   ├── 01_schema.sql
│   └── 02_seed_rules.sql
├── migrations/           # Cambios de esquema para bases que ya existen
│   ├── 001_totp_enroll.sql
│   ├── 002_primera_revision.sql
│   └── 003_alertas_detalle.sql
├── scripts/              # backup.sh y restore.sh
├── docker-compose.yml
├── .env.example
├── LICENSE
└── README.md
```

## Levantar en local
```bash
cp .env.example .env        # cambia POSTGRES_PASSWORD
docker compose up -d
docker compose ps           # espera a que diga "healthy"
```
Al crear el volumen por primera vez, Postgres ejecuta en orden lo que haya en `init/`:

| Archivo | Qué hace |
|---|---|
| `init/01_schema.sql` | Crea tipos, tablas e índices (`users`, `hosts`, `reports`, `processes`, `ports`, `rules`, `alerts`, `baseline`, `file_reputations`) |
| `init/02_seed_rules.sql` | Inserta las 6 reglas de detección; se puede repetir sin duplicar (`ON CONFLICT DO NOTHING`) |

Esos scripts **solo corren con el volumen vacío**. Para empezar de cero: `docker compose down -v && docker compose up -d` (borra los datos).

### Variables de entorno
| Variable | Descripción | Valor de ejemplo |
|---|---|---|
| `POSTGRES_USER` | Usuario dueño de la base | `portalert` |
| `POSTGRES_PASSWORD` | Contraseña (cámbiala) | `cambia-esta-clave` |
| `POSTGRES_DB` | Nombre de la base | `portalert` |
| `DB_PORT` | Puerto en el host (solo escucha en `127.0.0.1`) | `5433` |

## Conectar el backend
El backend necesita únicamente `DATABASE_URL`:
```
postgresql+psycopg2://portalert:TU_CLAVE@localhost:5433/portalert
```
Si la base se despliega aparte, usa el host y puerto del servicio. Para producción conviene que el backend se conecte con un rol propio sin permisos de administrador, no con el usuario dueño de la base.

## Migraciones (bases que ya existen)
`create_all` del ORM no modifica tablas existentes, así que los cambios de esquema van como archivos numerados en `migrations/`. Ejecútalos **en orden** con `psql`:
```bash
set -a; . ./.env; set +a
for f in migrations/*.sql; do
  echo "Aplicando $f"
  docker compose exec -T db psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" < "$f"
done
```
Si ya aplicaste alguna, ejecuta solo las que faltan (por ejemplo, un solo archivo: `... < migrations/003_alertas_detalle.sql`). Una base nueva creada con `init/` ya incluye todas.

| Migración | Qué hace |
|---|---|
| `001_totp_enroll.sql` | `totp_secret` pasa a `VARCHAR(255)` (guarda el secreto **cifrado por la aplicación**; lo hace el backend, la base nunca lo ve en claro). Agrega `totp_last_used_step`, los campos de vinculación de Telegram y del agente, `hosts.os_version`, y hace único `hosts.user_id` (un usuario, un equipo). **Falla** si algún usuario ya tiene 2 o más equipos: borra los sobrantes antes. Los secretos TOTP que hubiera se ponen en NULL y el 2FA queda desactivado. |
| `002_primera_revision.sql` | Agrega `hosts.review_completed_at` (se llena al pulsar "Terminar revisión") y la tabla `baseline` (lo que la persona marca como "es normal en este equipo"). Los equipos que ya tenían reportes se marcan como revisados. Aplícala **después** de la 001. |
| `003_alertas_detalle.sql` | Agrega a `alerts` los campos `report_id`, `process_id`, `event_type` (tipo `ENUM`) y `fingerprint`. Las alertas anteriores quedan con esos campos en NULL y el detalle se reconstruye con el último reporte. Aplícala **después** de la 002. |

Cada cambio nuevo: agrega `migrations/00N_nombre.sql` **y** actualiza `init/01_schema.sql` para que una base nueva quede igual que una migrada.

## Respaldos
```bash
./scripts/backup.sh                           # genera backups/portalert-AAAAMMDD-HHMMSS.sql.gz
./scripts/backup.sh /ruta/destino             # carpeta de destino opcional
./scripts/restore.sh backups/ARCHIVO.sql.gz   # sobre una base vacía
```
La carpeta `backups/` está en `.gitignore`; no subas respaldos al repositorio.

## Notas
- `init/01_schema.sql` se generó a partir de los modelos del backend, así que hoy el backend y esta carpeta describen el mismo esquema por dos lados. Hay que decidir cuál manda; lo más simple es que el backend use Alembic y este repo conserve el esquema como referencia y para levantar bases nuevas.
- Las reglas de `02_seed_rules.sql` también existen en el backend (`REGLAS`, que se siembra al arrancar). Si cambias una, cámbiala en los dos sitios.
- `hosts.review_completed_at` no forma parte del diagrama original; se agregó para saber si la primera revisión ya terminó.
- `severity`, `alert_status` y `event_type` son tipos `ENUM` de Postgres: agregar un valor nuevo requiere `ALTER TYPE ... ADD VALUE` en una migración.
- Nunca subas el archivo `.env` (ya está en `.gitignore`); usa `.env.example` como plantilla.

## Licencia
Distribuido bajo la licencia MIT. Consulta el archivo [LICENSE](LICENSE) para más detalles.

© 2026 Paola Esmeralda Valencia Aguilar
