#!/usr/bin/env bash
# Restaura un respaldo sobre una base VACÍA. Uso: ./scripts/restore.sh backups/archivo.sql.gz
set -euo pipefail
[ $# -eq 1 ] || { echo "Uso: $0 archivo.sql.gz" >&2; exit 1; }
cd "$(dirname "$0")/.."
set -a; . ./.env; set +a
gunzip -c "$1" | docker compose exec -T db psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB"
