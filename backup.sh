#!/bin/bash

set -euo pipefail

# -----------------------------
# CARGAR CONFIGURACIÓN
# -----------------------------
# En Docker viene por environment variables
: "${POSTGRES_HOST:?Missing POSTGRES_HOST}"
: "${POSTGRES_DB:?Missing POSTGRES_DB}"
: "${POSTGRES_USER:?Missing POSTGRES_USER}"
: "${POSTGRES_PASSWORD:?Missing POSTGRES_PASSWORD}"

export PGPASSWORD="$POSTGRES_PASSWORD"

BACKUP_DIR="/backups"
REMOTE="${RCLONE_REMOTE}:${RCLONE_PATH}"

DATE=$(date +%Y-%m-%d_%H-%M)
FILE="backup_${POSTGRES_DB}_${DATE}.sql.gz"

TMP_FILE="${BACKUP_DIR}/${FILE}.tmp"
FINAL_FILE="${BACKUP_DIR}/${FILE}"

echo "[INFO] $(date -u) Starting backup"

# -----------------------------
# ESPERAR A POSTGRES
# -----------------------------
until pg_isready -h "$POSTGRES_HOST" -U "$POSTGRES_USER"; do
  echo "[INFO] Waiting for PostgreSQL..."
  sleep 2
done

# -----------------------------
# BACKUP SEGURO (ATÓMICO)
# -----------------------------
# Se usa archivo temporal para evitar backups corruptos
pg_dump -h "$POSTGRES_HOST" -U "$POSTGRES_USER" "$POSTGRES_DB" \
  | gzip -c > "$TMP_FILE"

mv "$TMP_FILE" "$FINAL_FILE"

echo "[INFO] Backup created: $FINAL_FILE"

# =========================================================
# 🧹 LIMPIEZA LOCAL (SOLO 7 BACKUPS)
# =========================================================
echo "[INFO] Cleaning local backups (keep last 7)"

find "$BACKUP_DIR" -type f -name "*.gz" -printf "%T@ %p\n" 2>/dev/null \
  | sort -nr \
  | tail -n +8 \
  | awk '{print $2}' \
  | xargs -r rm -f

echo "[INFO] Local cleanup done"

# =========================================================
# ☁️ SINCRONIZACIÓN A GOOGLE DRIVE
# =========================================================
echo "[INFO] Uploading backups to Drive"

if rclone copy "$BACKUP_DIR" "$REMOTE" --transfers 2 --checkers 4; then
  echo "[INFO] Upload OK"
else
  echo "[ERROR] Upload failed"
  exit 1
fi

echo "[INFO] Remote sync completed"

# =========================================================
# 🧹 RETENCIÓN REMOTA (7 DÍAS)
# =========================================================
echo "[INFO] Cleaning remote backups older than 7 days"

rclone delete "$REMOTE" \
  --min-age 7d

echo "[INFO] Done"