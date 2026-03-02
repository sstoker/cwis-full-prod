#!/usr/bin/with-contenv bash
# Remove deprecated content_directories from settings.php (Drupal 7 concept, causes warnings in Drupal 10)
# Runs late (99) to fix any settings corrupted by earlier init scripts

SETTINGS="/var/www/drupal/web/sites/default/settings.php"
DEFAULT_SETTINGS="/var/www/drupal/web/core/assets/scaffold/files/default.settings.php"
DEFAULT_PATCH="/var/www/drupal/assets/patches/default_settings.txt"
PASSWORD_FILE="/var/run/drupal_db_password"
[ ! -f "$PASSWORD_FILE" ] && PASSWORD_FILE="/run/secrets/DRUPAL_DEFAULT_DB_PASSWORD"

# If settings are severely corrupted (missing PHP tag or < 100 lines), restore from scaffold
need_restore=0
if [ ! -f "$SETTINGS" ]; then
    need_restore=1
elif ! head -c 5 "$SETTINGS" 2>/dev/null | grep -q "<?php"; then
    need_restore=1
elif [ "$(wc -l < "$SETTINGS" 2>/dev/null || echo 0)" -lt 100 ]; then
    grep -q "databases\[" "$SETTINGS" 2>/dev/null || need_restore=1
fi

if [ "$need_restore" = "1" ] && [ -f "$DEFAULT_SETTINGS" ] && [ -f "$DEFAULT_PATCH" ]; then
    grep -v "content_directories" "$DEFAULT_PATCH" > /tmp/default_patch_fixed.txt
    sed -i "s|file_get_contents(\$path \. 'DRUPAL_DEFAULT_DB_PASSWORD')|trim(file_get_contents(\"$PASSWORD_FILE\"))|g" /tmp/default_patch_fixed.txt 2>/dev/null || true
    sed -i "s|trim(file_get_contents(\"/run/secrets/DRUPAL_DEFAULT_DB_PASSWORD\"))|trim(file_get_contents(\"/var/run/drupal_db_password\"))|g" /tmp/default_patch_fixed.txt 2>/dev/null || true
    cat "$DEFAULT_SETTINGS" /tmp/default_patch_fixed.txt > "$SETTINGS"
    chmod 644 "$SETTINGS"
    echo "[99-remove-content-directories.sh] Restored settings.php from scaffold"
fi

# Always remove content_directories if present
if [ -f "$SETTINGS" ] && grep -q "content_directories" "$SETTINGS" 2>/dev/null; then
    sed -i '/^global \$content_directories;$/d' "$SETTINGS"
    sed -i '/\$content_directories\["sync"\].*$/d' "$SETTINGS"
    sed -i "/\$content_directories\['sync'\].*$/d" "$SETTINGS"
    sed -i '/\$content_directories.*sync/d' "$SETTINGS"
    echo "[99-remove-content-directories.sh] Removed content_directories from settings.php"
fi

# Ensure password uses readable file
if [ -f "$SETTINGS" ] && grep -q "DRUPAL_DEFAULT_DB_PASSWORD" "$SETTINGS" 2>/dev/null && [ -f /var/run/drupal_db_password ]; then
    sed -i 's|/run/secrets/DRUPAL_DEFAULT_DB_PASSWORD|/var/run/drupal_db_password|g' "$SETTINGS" 2>/dev/null
    sed -i "s|trim(file_get_contents(\"/run/secrets/DRUPAL_DEFAULT_DB_PASSWORD\"))|trim(file_get_contents(\"/var/run/drupal_db_password\"))|g" "$SETTINGS" 2>/dev/null
fi

# Fix Fedora URL: configure_islandora_module may inject islandora.traefik.me - replace with env value
if [ -f "$SETTINGS" ] && grep -q "islandora.traefik.me" "$SETTINGS" 2>/dev/null; then
    sed -i "s|\$settings\['flysystem'\]\['fedora'\]\['config'\]\['root'\] = 'http://islandora.traefik.me:8081/fcrepo/rest/'|\$settings['flysystem']['fedora']['config']['root'] = trim(file_get_contents(\$path . 'DRUPAL_DEFAULT_FCREPO_URL'));|g" "$SETTINGS" 2>/dev/null || true
    echo "[99-remove-content-directories.sh] Fixed Fedora URL in settings.php"
fi
