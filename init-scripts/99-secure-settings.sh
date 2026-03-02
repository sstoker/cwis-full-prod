#!/usr/bin/with-contenv bash
# Best Practice: Secure settings.php after all initialization
# This runs last (99) to ensure settings.php is read-only and clean
# Mounted as a persistent volume to survive container recreation

if [ -f /var/www/drupal/web/sites/default/settings.php ]; then
    # Make file writable temporarily
    chmod 644 /var/www/drupal/web/sites/default/settings.php
    
    # Wait to ensure all other scripts have finished
    sleep 3
    
    # Remove ONLY hardcoded password lines (keep file_get_contents ones)
    # Remove lines with hardcoded 'password' value
    sed -i "/^\$databases\['default'\]\['default'\]\['password'\] = 'password';$/d" /var/www/drupal/web/sites/default/settings.php
    sed -i '/^\$databases\["default"\]\["default"\]\["password"\] = "password";$/d' /var/www/drupal/web/sites/default/settings.php
    # Note: Do NOT use awk to filter - it can corrupt array-format password lines
    # (e.g. 'password' => file_get_contents(...)) and empty the file
    
    # Ensure the secret-based password line exists (check for both quote styles)
    # Use /var/run/drupal_db_password which is readable by nginx (created by 07-fix-secret-permissions.sh)
    if ! grep -q 'file_get_contents.*drupal_db_password\|file_get_contents.*DRUPAL_DEFAULT_DB_PASSWORD' /var/www/drupal/web/sites/default/settings.php; then
        # Determine which password file to use
        PASSWORD_FILE="/var/run/drupal_db_password"
        if [ ! -f "$PASSWORD_FILE" ]; then
            PASSWORD_FILE="/run/secrets/DRUPAL_DEFAULT_DB_PASSWORD"
        fi
        
        # Try to add after username line (handle both quote styles)
        if grep -q "\$databases\['default'\]\['default'\]\['username'\]" /var/www/drupal/web/sites/default/settings.php; then
            sed -i "/\$databases\['default'\]\['default'\]\['username'\]/a\$databases['default']['default']['password'] = trim(file_get_contents(\"$PASSWORD_FILE\"));" /var/www/drupal/web/sites/default/settings.php
        elif grep -q '\$databases\["default"\]\["default"\]\["username"\]' /var/www/drupal/web/sites/default/settings.php; then
            sed -i "/\$databases\[\"default\"\]\[\"default\"\]\[\"username\"\]/a\$databases[\"default\"][\"default\"][\"password\"] = trim(file_get_contents(\"$PASSWORD_FILE\"));" /var/www/drupal/web/sites/default/settings.php
        fi
    fi
    
    # Update any existing password lines to use the readable copy if it exists
    if grep -q "file_get_contents.*DRUPAL_DEFAULT_DB_PASSWORD" /var/www/drupal/web/sites/default/settings.php && [ -f /var/run/drupal_db_password ]; then
        sed -i 's|/run/secrets/DRUPAL_DEFAULT_DB_PASSWORD|/var/run/drupal_db_password|g' /var/www/drupal/web/sites/default/settings.php
    fi
    
    # Make read-only but readable by web server (444 = read-only for all)
    chmod 444 /var/www/drupal/web/sites/default/settings.php
    chown root:root /var/www/drupal/web/sites/default/settings.php
    
    echo "[99-secure-settings.sh] Secured settings.php (read-only for all, secret-based password)"
fi
