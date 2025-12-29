# Backup and Restore Guide

This guide explains how to backup and restore your OpenMemory data, including SQLite database, configuration, and Qdrant vector storage.

---

## Quick Start

### Create a Backup

```bash
./backup-scripts/backup_all.sh
```

This creates a timestamped backup in `./backups/` containing:
- SQLite database (`openmemory.db`)
- Configuration (`config.json`)
- Qdrant vector storage (embeddings)

### Restore from Backup

```bash
# List available backups
./backup-scripts/restore_all.sh

# Restore specific backup
./backup-scripts/restore_all.sh openmemory-backup-20231215-143022
```

---

## What Gets Backed Up

OpenMemory stores data in three locations:

| Component | Location | Contains | Backed Up |
|-----------|----------|----------|-----------|
| **SQLite Database** | `./api/openmemory.db` | Memory metadata, users, apps, categories | ✅ Yes |
| **Qdrant Storage** | Docker volume `openmemory_mem0_storage` | Vector embeddings for semantic search | ✅ Yes |
| **Configuration** | `./api/config.json` | LLM/embedder settings | ✅ Yes |
| **Environment** | `./api/.env` | API keys (sensitive) | ❌ No (security) |

**Note:** API keys in `.env` are **not** backed up for security reasons. You must set them manually after restore.

---

## Backup Methods

### Method 1: Automated Script (Recommended)

```bash
# Backup with auto-generated timestamp
./backup-scripts/backup_all.sh

# Backup with custom name
./backup-scripts/backup_all.sh my-important-backup
```

**Output:**
```
backups/
└── openmemory-backup-20231215-143022/
    ├── openmemory.db              # SQLite database
    ├── config.json                # Configuration
    ├── qdrant-storage.tar.gz      # Vector embeddings (compressed)
    └── backup-info.txt            # Backup metadata
```

### Method 2: Manual Backup

```bash
# Create backup directory
mkdir -p backups/manual-backup

# Backup SQLite database
cp ./api/openmemory.db backups/manual-backup/

# Backup configuration
cp ./api/config.json backups/manual-backup/

# Backup Qdrant storage
docker run --rm \
  -v openmemory_mem0_storage:/data:ro \
  -v $(pwd)/backups/manual-backup:/backup \
  alpine tar czf /backup/qdrant-storage.tar.gz -C /data .
```

---

## Restore Methods

### Method 1: Automated Script (Recommended)

```bash
# List available backups
./backup-scripts/restore_all.sh

# Restore specific backup (with confirmation prompt)
./backup-scripts/restore_all.sh openmemory-backup-20231215-143022
```

**The script will:**
1. ⚠️  Warn you about data overwrite
2. Ask for confirmation (`yes/no`)
3. Stop containers
4. Restore all components
5. Restart containers

### Method 2: Manual Restore

```bash
# Stop containers
docker compose stop

# Restore SQLite database
cp backups/your-backup-name/openmemory.db ./api/openmemory.db

# Restore configuration
cp backups/your-backup-name/config.json ./api/config.json

# Restore Qdrant storage
docker run --rm \
  -v openmemory_mem0_storage:/data \
  -v $(pwd)/backups/your-backup-name:/backup:ro \
  alpine sh -c "rm -rf /data/* && tar xzf /backup/qdrant-storage.tar.gz -C /data"

# Restart containers
docker compose start
```

---

## Best Practices

### Regular Backups

Create a cron job for automated backups:

```bash
# Edit crontab
crontab -e

# Add daily backup at 2 AM
0 2 * * * cd /path/to/openmemory && ./backup-scripts/backup_all.sh daily-backup-$(date +\%Y\%m\%d)
```

### Backup Retention

Keep multiple backups with different retention periods:

```bash
# Daily backups (keep 7 days)
./backup-scripts/backup_all.sh daily-$(date +%Y%m%d)

# Weekly backups (keep 4 weeks)
./backup-scripts/backup_all.sh weekly-$(date +%Y-W%V)

# Monthly backups (keep 12 months)
./backup-scripts/backup_all.sh monthly-$(date +%Y-%m)
```

### Off-site Backups

Copy backups to external storage:

```bash
# Compress entire backup directory
tar czf openmemory-backup.tar.gz backups/

# Upload to cloud storage (example with AWS S3)
aws s3 cp openmemory-backup.tar.gz s3://my-bucket/openmemory/

# Or use rsync to remote server
rsync -avz backups/ user@remote-server:/backups/openmemory/
```

---

## Troubleshooting

### Backup Fails: "Volume not found"

**Problem:** Docker volume doesn't exist.

**Solution:**
```bash
# Check if volume exists
docker volume ls | grep mem0_storage

# If missing, start containers first
docker compose up -d
```

### Restore Fails: "Permission denied"

**Problem:** Insufficient permissions to access Docker volumes.

**Solution:**
```bash
# Run with sudo (Linux) or ensure Docker Desktop is running (macOS)
sudo ./backup-scripts/restore_all.sh backup-name
```

### Data Mismatch After Restore

**Problem:** SQLite and Qdrant data are out of sync.

**Solution:** Always restore **both** components from the same backup. Never mix SQLite from one backup with Qdrant from another.

---

## Migration to New Server

### Export from Old Server

```bash
# Create backup
./backup-scripts/backup_all.sh migration-backup

# Compress for transfer
tar czf migration.tar.gz backups/migration-backup/

# Transfer to new server
scp migration.tar.gz user@new-server:/tmp/
```

### Import on New Server

```bash
# On new server
cd /path/to/openmemory

# Extract backup
tar xzf /tmp/migration.tar.gz

# Restore
./backup-scripts/restore_all.sh migration-backup

# Set API keys in .env
echo "ZAI_API_KEY=your-key" >> api/.env

# Start containers
docker compose up -d
```

---

## Advanced: Qdrant Snapshots API

For large datasets, use Qdrant's native snapshot feature:

### Create Snapshot

```bash
# Create snapshot via API
curl -X POST http://localhost:6333/collections/mem0/snapshots

# List snapshots
curl http://localhost:6333/collections/mem0/snapshots

# Download snapshot
curl http://localhost:6333/collections/mem0/snapshots/snapshot-2023-12-15-14-30-22 \
  -o qdrant-snapshot.snapshot
```

### Restore Snapshot

```bash
# Upload snapshot
curl -X PUT http://localhost:6333/collections/mem0/snapshots/upload \
  -H 'Content-Type: multipart/form-data' \
  -F 'snapshot=@qdrant-snapshot.snapshot'

# Recover from snapshot
curl -X PUT http://localhost:6333/collections/mem0/snapshots/recover \
  -H 'Content-Type: application/json' \
  -d '{"location": "snapshot-2023-12-15-14-30-22"}'
```

---

## FAQ

**Q: How often should I backup?**  
A: Depends on usage. Daily for active use, weekly for light use.

**Q: Can I backup while containers are running?**  
A: Yes, but stopping containers ensures data consistency.

**Q: What happens to my data when I rebuild containers?**  
A: Data persists in Docker volumes and mounted directories. Only lost if you run `docker compose down -v`.

**Q: Can I restore to a different machine?**  
A: Yes! Just copy the backup directory and run the restore script.

**Q: How much disk space do backups use?**  
A: Depends on data size. Qdrant storage is compressed. Check with `du -sh backups/`.

---

## See Also

- [USAGE_GUIDE.md](./USAGE_GUIDE.md) - Using OpenMemory
- [LLM_SETUP.md](./LLM_SETUP.md) - Configuring LLM providers
- [ARCHITECTURE.md](./ARCHITECTURE.md) - System architecture

