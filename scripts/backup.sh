#!/usr/bin/env bash
# Respaldo comprimido de la base. Uso: ./scripts/backup.sh [carpeta_destino]
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; . ./.env; set +a
dest="${1:-backups}"; mkdir -p "$dest"
file="$dest/portalert-$(date +%Y%m%d-%H%M%S).sql.gz"
docker compose exec -T db pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --no-owner | gzip > "$file"
echo "Respaldo guardado en $file"
