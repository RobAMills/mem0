#!/usr/bin/env bash
set -euo pipefail

# Restore OpenMemory from backup
# Usage: ./restore_all.sh <backup-name>

if [ $# -eq 0 ]; then
  echo "Usage: $0 <backup-name>"
  echo ""
  echo "Available backups:"
  ls -1 ./backups/ 2>/dev/null || echo "  (no backups found)"
  exit 1
fi

BACKUP_NAME="$1"
BACKUP_DIR="./backups/${BACKUP_NAME}"

if [ ! -d "${BACKUP_DIR}" ]; then
  echo "❌ Backup not found: ${BACKUP_DIR}"
  exit 1
fi

echo "⚠️  WARNING: This will overwrite current data!"
echo "Restoring from: ${BACKUP_NAME}"
echo ""
read -p "Continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "Cancelled."
  exit 0
fi

# Stop containers
echo "🛑 Stopping containers..."
docker compose stop

# 1. Restore SQLite database
if [ -f "${BACKUP_DIR}/openmemory.db" ]; then
  echo "📦 Restoring SQLite database..."
  cp "${BACKUP_DIR}/openmemory.db" "./api/openmemory.db"
  echo "✅ SQLite database restored"
fi

# 2. Restore config.json
if [ -f "${BACKUP_DIR}/config.json" ]; then
  echo "📦 Restoring configuration..."
  cp "${BACKUP_DIR}/config.json" "./api/config.json"
  echo "✅ Configuration restored"
fi

# 3. Restore Qdrant vector storage
if [ -f "${BACKUP_DIR}/qdrant-storage.tar.gz" ]; then
  echo "📦 Restoring Qdrant vector storage..."
  docker run --rm \
    -v openmemory_mem0_storage:/data \
    -v "$(pwd)/${BACKUP_DIR}:/backup:ro" \
    alpine sh -c "rm -rf /data/* && tar xzf /backup/qdrant-storage.tar.gz -C /data"
  echo "✅ Qdrant storage restored"
fi

# Restart containers
echo "🚀 Starting containers..."
docker compose start

echo "✅ Restore complete!"

