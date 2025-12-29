#!/usr/bin/env bash
set -euo pipefail

# Complete OpenMemory backup: SQLite DB + Qdrant vector storage
# Usage: ./backup_all.sh [backup-name]

BACKUP_NAME="${1:-openmemory-backup-$(date +%Y%m%d-%H%M%S)}"
BACKUP_DIR="./backups/${BACKUP_NAME}"

echo "🔄 Creating backup: ${BACKUP_NAME}"

# Create backup directory
mkdir -p "${BACKUP_DIR}"

# 1. Backup SQLite database
echo "📦 Backing up SQLite database..."
if [ -f "./api/openmemory.db" ]; then
  cp "./api/openmemory.db" "${BACKUP_DIR}/openmemory.db"
  echo "✅ SQLite database backed up"
else
  echo "⚠️  SQLite database not found at ./api/openmemory.db"
fi

# 2. Backup config.json
echo "📦 Backing up configuration..."
if [ -f "./api/config.json" ]; then
  cp "./api/config.json" "${BACKUP_DIR}/config.json"
  echo "✅ Configuration backed up"
fi

# 3. Backup Qdrant vector storage
echo "📦 Backing up Qdrant vector storage..."
docker run --rm \
  -v openmemory_mem0_storage:/data:ro \
  -v "$(pwd)/${BACKUP_DIR}:/backup" \
  alpine tar czf /backup/qdrant-storage.tar.gz -C /data .

echo "✅ Qdrant storage backed up"

# 4. Create metadata file
cat > "${BACKUP_DIR}/backup-info.txt" <<EOF
Backup Name: ${BACKUP_NAME}
Created: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
Contents:
  - openmemory.db (SQLite database)
  - config.json (Configuration)
  - qdrant-storage.tar.gz (Vector embeddings)
EOF

echo "✅ Backup complete: ${BACKUP_DIR}"
echo ""
echo "Backup contents:"
ls -lh "${BACKUP_DIR}"

