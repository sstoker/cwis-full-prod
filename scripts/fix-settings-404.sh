#!/bin/bash
# Emergency fix for corrupted settings.php (404 error)
# Restores settings.php with correct DB password from secrets

set -e
SITE_DIR="/var/www/drupal/web/sites/default"
SETTINGS="${SITE_DIR}/settings.php"
DEFAULT_SETTINGS="/var/www/drupal/web/core/assets/scaffold/files/default.settings.php"
DEFAULT_PATCH="/var/www/drupal/assets/patches/default_settings.txt"
PASSWORD_FILE="/run/secrets/DRUPAL_DEFAULT_DB_PASSWORD"

# Ensure password file exists for nginx
if [ -f "$PASSWORD_FILE" ]; then
    mkdir -p /var/run
    cat "$PASSWORD_FILE" > /var/run/drupal_db_password
    chmod 640 /var/run/drupal_db_password
    chown root:101 /var/run/drupal_db_password 2>/dev/null || true
fi

# Use /var/run/drupal_db_password for password (nginx can read it)
PASS_REF='trim(file_get_contents("/var/run/drupal_db_password"))'
[ ! -f /var/run/drupal_db_password ] && PASS_REF='trim(file_get_contents("/run/secrets/DRUPAL_DEFAULT_DB_PASSWORD"))'

# Create fixed patch - replace password with secret file reference
grep -v "content_directories" "$DEFAULT_PATCH" | \
  sed "s|file_get_contents(\$path \. 'DRUPAL_DEFAULT_DB_PASSWORD')|$PASS_REF|g" > /tmp/default_patch_fixed.txt

# Restore settings: default.settings.php + fixed patch
cat "$DEFAULT_SETTINGS" /tmp/default_patch_fixed.txt > "$SETTINGS"
chmod 644 "$SETTINGS"
chown nginx:nginx "$SETTINGS" 2>/dev/null || true

echo "Restored settings.php successfully"
