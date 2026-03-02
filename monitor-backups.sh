#!/bin/bash
# Script to monitor backups and send alerts if they fail
# This should be run regularly (e.g., daily) to check backup health

set -e

LOG_FILE="/var/log/backup-monitor.log"
ALERT_EMAIL="${BACKUP_ALERT_EMAIL:-}"  # Set this to receive email alerts
MAX_BACKUP_AGE_DAYS=8  # Alert if last backup is older than this

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

send_alert() {
    local message="$1"
    log_message "ALERT: $message"
    
    if [ -n "$ALERT_EMAIL" ]; then
        echo "$message" | mail -s "Production Backup Alert" "$ALERT_EMAIL" 2>/dev/null || true
    fi
}

log_message "=== Backup Monitoring Started ==="

ALERTS=0

# Check docker-compose backup age
if [ -f "/root/isle-dc-production-backup/docker-compose.yml" ]; then
    LAST_BACKUP=$(stat -c %Y /root/isle-dc-production-backup/docker-compose.yml 2>/dev/null || echo "0")
    CURRENT_TIME=$(date +%s)
    AGE_DAYS=$(( (CURRENT_TIME - LAST_BACKUP) / 86400 ))
    
    if [ $AGE_DAYS -gt $MAX_BACKUP_AGE_DAYS ]; then
        send_alert "Docker Compose backup is $AGE_DAYS days old (max: $MAX_BACKUP_AGE_DAYS days)"
        ALERTS=$((ALERTS + 1))
    else
        log_message "Docker Compose backup is $AGE_DAYS days old (OK)"
    fi
else
    send_alert "Docker Compose backup file not found"
    ALERTS=$((ALERTS + 1))
fi

# Check codebase backup age
if [ -d "/root/isle-dc-production-codebase-backup/.git" ]; then
    LAST_COMMIT=$(cd /root/isle-dc-production-codebase-backup && git log -1 --format=%ct 2>/dev/null || echo "0")
    if [ "$LAST_COMMIT" != "0" ]; then
        CURRENT_TIME=$(date +%s)
        AGE_DAYS=$(( (CURRENT_TIME - LAST_COMMIT) / 86400 ))
        
        if [ $AGE_DAYS -gt $MAX_BACKUP_AGE_DAYS ]; then
            send_alert "Codebase backup is $AGE_DAYS days old (max: $MAX_BACKUP_AGE_DAYS days)"
            ALERTS=$((ALERTS + 1))
        else
            log_message "Codebase backup is $AGE_DAYS days old (OK)"
        fi
    else
        send_alert "Codebase backup has no commits"
        ALERTS=$((ALERTS + 1))
    fi
else
    send_alert "Codebase backup repository not found"
    ALERTS=$((ALERTS + 1))
fi

# Check remote sync status
cd /root/isle-dc-production-codebase-backup
if git remote get-url origin >/dev/null 2>&1; then
    if ! git ls-remote origin >/dev/null 2>&1; then
        send_alert "Codebase backup remote is not accessible"
        ALERTS=$((ALERTS + 1))
    fi
fi

cd /root/isle-dc-production-backup
if git remote get-url origin >/dev/null 2>&1; then
    if ! git ls-remote origin >/dev/null 2>&1; then
        send_alert "Docker Compose backup remote is not accessible"
        ALERTS=$((ALERTS + 1))
    fi
fi

# Run verification
if /root/isle-dc-production/verify-backups.sh >> "$LOG_FILE" 2>&1; then
    log_message "Backup verification passed"
else
    send_alert "Backup verification failed - check logs"
    ALERTS=$((ALERTS + 1))
fi

log_message "=== Backup Monitoring Complete (Alerts: $ALERTS) ==="

if [ $ALERTS -gt 0 ]; then
    exit 1
else
    exit 0
fi
