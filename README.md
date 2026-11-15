# PortAlert · Base de datos

PostgreSQL 16 con el esquema y las reglas iniciales de PortAlert. Vive sola: no necesita el backend, el front ni el agente para levantarse.

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

## Conectar el backend
El backend necesita únicamente `DATABASE_URL`:
```
postgresql+psycopg2://portalert:TU_CLAVE@localhost:5433/portalert
```
Si la base se despliega aparte, usa el host y puerto del servicio. Para producción conviene que el backend se conecte con un rol propio sin permisos de administrador, no con el usuario dueño de la base.

## Migraciones (bases que ya existen)
`create_all` del ORM no modifica tablas existentes, así que los cambios de esquema van como archivos numerados en `migrations/`; ejecútalos en orden con `psql`:
```bash
docker compose exec -T db psql -U $POSTGRES_USER -d $POSTGRES_DB < migrations/001_totp_enroll.sql
```
- `003_alertas_detalle.sql`: agrega a `alerts` los campos del diagrama `report_id`, `process_id`, `event_type` (tipo `ENUM`) y `fingerprint`. Las alertas anteriores quedan con esos campos en NULL y el detalle se reconstruye con el último reporte. Aplícala **después** de la 002.
- `002_primera_revision.sql`: agrega `hosts.review_completed_at` (se llena al pulsar "Terminar revisión") y la tabla `baseline` (lo que la persona marca como "es normal en este equipo"). Los equipos que ya tenían reportes se marcan como revisados. Aplícala **después** de la 001.
- `001_totp_enroll.sql`: `totp_secret` pasa a `VARCHAR(255)` (guarda el secreto **cifrado por la aplicación**; lo hace el backend, la base nunca lo ve en claro), agrega `totp_last_used_step`, los campos de vinculación de Telegram y del agente, `hosts.os_version`, y hace único `hosts.user_id` (un usuario, un equipo). Falla si algún usuario ya tiene 2 o más equipos: borra los sobrantes antes. Los secretos TOTP que hubiera se ponen en NULL y el 2FA queda desactivado.

Cada cambio nuevo: agrega `migrations/00N_nombre.sql` **y** actualiza `init/01_schema.sql` para que una base nueva quede igual que una migrada.

## Respaldos
```bash
./scripts/backup.sh                 # genera backups/portalert-AAAAMMDD-HHMMSS.sql.gz
./scripts/restore.sh backups/ARCHIVO.sql.gz   # sobre una base vacía
```

## Notas
- `init/01_schema.sql` se generó a partir de los modelos del backend, así que hoy el backend y esta carpeta describen el mismo esquema por dos lados. Hay que decidir cuál manda; lo más simple es que el backend use Alembic y este repo conserve el esquema como referencia y para levantar bases nuevas.
- Las reglas de `02_seed_rules.sql` también existen en el backend (`REGLAS`, que se siembra al arrancar). Si cambias una, cámbiala en los dos sitios.
- `hosts.review_completed_at` no está en el diagrama: la agregué para saber si la primera revisión ya se terminó.
- `severity` y `alert_status` son tipos `ENUM` de Postgres: agregar un valor nuevo requiere `ALTER TYPE ... ADD VALUE` en una migración.
