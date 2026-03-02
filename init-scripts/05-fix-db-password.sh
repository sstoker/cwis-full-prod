#!/usr/bin/with-contenv bash
# Best Practice: Fix DRUPAL_DEFAULT_DB_PASSWORD to read from secret file
# This script runs before 04-custom-setup.sh to ensure the environment variable
# is set correctly from the secret file before update_settings_php is called.
#
# This is a persistent fix that will survive container recreation when mounted as a volume.
# The environment variable is exported so it's available to all child processes.

if [ -f /run/secrets/DRUPAL_DEFAULT_DB_PASSWORD ]; then
    export DRUPAL_DEFAULT_DB_PASSWORD=$(cat /run/secrets/DRUPAL_DEFAULT_DB_PASSWORD)
    # Also set it in the environment for all child processes
    echo "export DRUPAL_DEFAULT_DB_PASSWORD=\"${DRUPAL_DEFAULT_DB_PASSWORD}\"" >> /etc/environment
    echo "[05-fix-db-password.sh] Set DRUPAL_DEFAULT_DB_PASSWORD from secret file (length: ${#DRUPAL_DEFAULT_DB_PASSWORD})"
else
    echo "[05-fix-db-password.sh] Warning: /run/secrets/DRUPAL_DEFAULT_DB_PASSWORD not found"
fi

# Best Practice: Ensure settings.php is read-only after initialization
# This will be set after 04-custom-setup.sh completes, but we prepare the function here
ensure_settings_readonly() {
    if [ -f /var/www/drupal/web/sites/default/settings.php ]; then
        chmod 400 /var/www/drupal/web/sites/default/settings.php
        # Remove any duplicate password lines that might have been added
        sed -i '/^\$databases\['\''default'\''\]\['\''default'\''\]\['\''password'\''\] = '\''[^'\'']*'\'';$/d' /var/www/drupal/web/sites/default/settings.php
        # Ensure only the secret-based password line exists
        if ! grep -q "file_get_contents.*DRUPAL_DEFAULT_DB_PASSWORD" /var/www/drupal/web/sites/default/settings.php; then
            # Add the correct password line if missing
            sed -i '/\$databases\["default"\]\["default"\]\["username"\]/a\$databases["default"]["default"]["password"] = trim(file_get_contents("/run/secrets/DRUPAL_DEFAULT_DB_PASSWORD"));' /var/www/drupal/web/sites/default/settings.php
        fi
        chmod 400 /var/www/drupal/web/sites/default/settings.php
    fi
}

# Export the function so it can be called from other scripts
export -f ensure_settings_readonly
