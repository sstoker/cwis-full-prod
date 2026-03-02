#!/bin/bash
# Script to backup production docker-compose.yml
# Since docker-compose.yml is in .gitignore, we'll create a timestamped backup

set -e

cd /root/isle-dc-production

BACKUP_DIR="backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/docker-compose.yml.${TIMESTAMP}"

echo "=== Production docker-compose.yml Backup ==="
echo ""

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Create backup
if [ -f docker-compose.yml ]; then
    cp docker-compose.yml "$BACKUP_FILE"
    echo "✓ Backup created: $BACKUP_FILE"
    
    # Also create a 'latest' symlink for easy access
    LATEST="${BACKUP_DIR}/docker-compose.yml.latest"
    rm -f "$LATEST"
    ln -s "$(basename $BACKUP_FILE)" "$LATEST"
    echo "✓ Latest backup symlink created: $LATEST"
    
    # Show file info
    echo ""
    echo "Backup details:"
    ls -lh "$BACKUP_FILE"
    
    # Count backups
    BACKUP_COUNT=$(ls -1 "${BACKUP_DIR}/docker-compose.yml."* 2>/dev/null | wc -l)
    echo ""
    echo "Total backups: $BACKUP_COUNT"
    
    # Keep only last 10 backups
    if [ "$BACKUP_COUNT" -gt 10 ]; then
        echo "Cleaning up old backups (keeping last 10)..."
        ls -1t "${BACKUP_DIR}/docker-compose.yml."* | tail -n +11 | xargs rm -f
        echo "✓ Cleanup complete"
    fi
else
    echo "Error: docker-compose.yml not found!"
    exit 1
fi

echo ""
echo "=== Backup Complete ==="
