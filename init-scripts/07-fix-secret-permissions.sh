#!/usr/bin/with-contenv bash
# Best Practice: Make secret files readable by web server while maintaining security
# Docker secrets are read-only, so we create a readable copy for the web server
# This script runs after password fix but before settings are secured

if [ -f /run/secrets/DRUPAL_DEFAULT_DB_PASSWORD ]; then
    # Read the secret as root and create a readable copy for nginx user
    # Store in /tmp which is typically readable, or use a more secure location
    DB_PASSWORD=$(cat /run/secrets/DRUPAL_DEFAULT_DB_PASSWORD)
    
    # Create a readable copy in /var/run (tmpfs, more secure than /tmp)
    # Make it readable by nginx user and group
    echo "$DB_PASSWORD" > /var/run/drupal_db_password
    chmod 640 /var/run/drupal_db_password
    chown root:101 /var/run/drupal_db_password 2>/dev/null || chown root:nginx /var/run/drupal_db_password
    
    echo "[07-fix-secret-permissions.sh] Created readable copy of DRUPAL_DEFAULT_DB_PASSWORD for nginx user"
else
    echo "[07-fix-secret-permissions.sh] Warning: /run/secrets/DRUPAL_DEFAULT_DB_PASSWORD not found"
fi
