#!/usr/bin/with-contenv bash
# Best Practice: Fix settings.php content issues while maintaining security
# This script runs after 05a-fix-secret-permissions.sh (so /var/run/drupal_db_password exists)
# It fixes the content_directories issue and restores corrupted settings

SITE_DIR="/var/www/drupal/web/sites/default"
SETTINGS="${SITE_DIR}/settings.php"
DEFAULT_SETTINGS="/var/www/drupal/web/core/assets/scaffold/files/default.settings.php"
DEFAULT_PATCH="/var/www/drupal/assets/patches/default_settings.txt"
PATH_PREFIX="/var/run/s6/container_environment"

# Ensure 05a created the readable password file (runs before us)
PASSWORD_FILE="/var/run/drupal_db_password"
[ ! -f "$PASSWORD_FILE" ] && PASSWORD_FILE="/run/secrets/DRUPAL_DEFAULT_DB_PASSWORD"

need_restore=0
if [ ! -f "$SETTINGS" ]; then
    need_restore=1
    echo "[06-fix-settings-content.sh] settings.php does not exist, restoring from scaffold"
elif [ -f "$SETTINGS" ]; then
    line_count=$(wc -l < "$SETTINGS" 2>/dev/null || echo 0)
    has_db_config=$(grep -q "databases\[" "$SETTINGS" 2>/dev/null && echo "yes" || echo "no")
    has_php_open=$(head -c 5 "$SETTINGS" 2>/dev/null | grep -q "<?php" && echo "yes" || echo "no")
    if [ "$line_count" -lt 10 ] && [ "$has_db_config" = "no" ]; then
        need_restore=1
        echo "[06-fix-settings-content.sh] settings.php appears corrupted (only $line_count lines, no database config), restoring"
    elif [ "$has_php_open" = "no" ]; then
        need_restore=1
        echo "[06-fix-settings-content.sh] settings.php missing PHP open tag, restoring from scaffold"
    fi
fi

if [ "$need_restore" = "1" ] && [ -f "$DEFAULT_SETTINGS" ] && [ -f "$DEFAULT_PATCH" ]; then
    # Restore: default.settings.php + default_settings.txt (without content_directories, with correct password path)
    # Remove content_directories from patch and fix password to use readable secret file
    grep -v "content_directories" "$DEFAULT_PATCH" > /tmp/default_patch_fixed.txt
    # Replace password to use readable secret file (container_environment may not have it)
    sed -i "s|file_get_contents(\$path \. 'DRUPAL_DEFAULT_DB_PASSWORD')|trim(file_get_contents('$PASSWORD_FILE'))|g" /tmp/default_patch_fixed.txt
    cat "$DEFAULT_SETTINGS" /tmp/default_patch_fixed.txt > "$SETTINGS"
    chmod 644 "$SETTINGS"
    echo "[06-fix-settings-content.sh] Restored settings.php from scaffold"
fi

if [ -f "$SETTINGS" ]; then
    # Make file writable temporarily to fix it
    chmod 644 "$SETTINGS"
    
    line_count=$(wc -l < "$SETTINGS" 2>/dev/null || echo 0)
    has_db_config=$(grep -q "databases\[" "$SETTINGS" 2>/dev/null && echo "yes" || echo "no")
    
    # Remove the incorrect content_directories lines (Drupal 7 concept, not needed in Drupal 10)
    if grep -q "content_directories" "$SETTINGS"; then
        sed -i '/^global \$content_directories;$/d' "$SETTINGS"
        sed -i '/^\$content_directories\["sync"\].*$/d' "$SETTINGS"
        sed -i "/^\$content_directories\['sync'\].*$/d" "$SETTINGS"
        echo "[06-fix-settings-content.sh] Removed incorrect content_directories lines"
    fi
    
    # Ensure config_sync_directory is set correctly
    sed -i '/^\['\''config_sync_directory'\''\]/d' "$SETTINGS"
    sed -i '/\$settings\[.config_sync_directory.\]/d' "$SETTINGS"
    if ! grep -q "config_sync_directory" "$SETTINGS"; then
        if [ "$has_db_config" = "yes" ]; then
            echo "\$settings['config_sync_directory'] = '/var/www/drupal/config/sync';" >> "$SETTINGS"
            echo "[06-fix-settings-content.sh] Added config_sync_directory setting"
        fi
    fi
    
    # Ensure database password uses readable secret file
    if ! grep -q "file_get_contents.*drupal_db_password\|file_get_contents.*DRUPAL_DEFAULT_DB_PASSWORD" "$SETTINGS"; then
        if grep -q "username.*drupal_default" "$SETTINGS"; then
            if [ -f /var/run/drupal_db_password ]; then
                sed -i '/\$databases\[.default.\]\[.default.\]\[.username.\]/a\$databases["default"]["default"]["password"] = trim(file_get_contents("/var/run/drupal_db_password"));' "$SETTINGS"
            else
                sed -i '/\$databases\[.default.\]\[.default.\]\[.username.\]/a\$databases["default"]["default"]["password"] = trim(file_get_contents("/run/secrets/DRUPAL_DEFAULT_DB_PASSWORD"));' "$SETTINGS"
            fi
            echo "[06-fix-settings-content.sh] Added database password from secret file"
        fi
    fi
    
    # Update existing password lines to use the readable copy
    if grep -q "file_get_contents.*DRUPAL_DEFAULT_DB_PASSWORD" "$SETTINGS" 2>/dev/null && [ -f /var/run/drupal_db_password ]; then
        sed -i 's|/run/secrets/DRUPAL_DEFAULT_DB_PASSWORD|/var/run/drupal_db_password|g' "$SETTINGS"
        sed -i "s|\$path \. 'DRUPAL_DEFAULT_DB_PASSWORD'|'/var/run/drupal_db_password'|g" "$SETTINGS"
        echo "[06-fix-settings-content.sh] Updated password path to use readable copy"
    fi
    
    echo "[06-fix-settings-content.sh] Completed settings.php content fix"
fi
