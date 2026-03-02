#!/usr/bin/with-contenv bash
# Don't exit on error - we want to continue even if some commands fail
set +e

source /etc/islandora/utilities.sh

function main {
    local site="default"
    # Creates database if does not already exist.
    # Skipping database creation as it already exists with imported data
    # create_database "${site}"
    
    # Update settings.php FIRST to ensure database connection is configured
    # This is critical when using an existing database with imported data
    update_settings_php "${site}"
    
    # Fedora URL: Use DRUPAL_DEFAULT_FCREPO_URL from env (external URL for working user links).
    # Do NOT replace with internal fcrepo:8080 - that breaks Fedora links for users.
    
    # Fix missing content_translation columns in node_field_revision (Drupal 10.5+
    # content translation schema; prevents "Column not found" when saving nodes).
    drush sqlq "SELECT content_translation_uid FROM node_field_revision LIMIT 1" 2>/dev/null || {
        drush sqlq "ALTER TABLE node_field_revision ADD COLUMN content_translation_uid int(10) unsigned DEFAULT NULL" 2>/dev/null
        drush sqlq "ALTER TABLE node_field_revision ADD COLUMN content_translation_status tinyint(4) DEFAULT NULL" 2>/dev/null
        drush sqlq "ALTER TABLE node_field_revision ADD COLUMN content_translation_created int(11) DEFAULT NULL" 2>/dev/null
        drush sqlq "ALTER TABLE node_field_revision ADD COLUMN content_translation_changed int(11) DEFAULT NULL" 2>/dev/null
    } || true

    # Fix missing content_translation columns in media_field_data (Drupal 10.5+
    # content translation schema; prevents "Column not found" when saving media).
    drush sqlq "SELECT content_translation_uid FROM media_field_data LIMIT 1" 2>/dev/null || {
        drush sqlq "ALTER TABLE media_field_data ADD COLUMN content_translation_uid int(10) unsigned DEFAULT NULL" 2>/dev/null
        drush sqlq "ALTER TABLE media_field_data ADD COLUMN content_translation_status tinyint(4) DEFAULT NULL" 2>/dev/null
        drush sqlq "ALTER TABLE media_field_data ADD COLUMN content_translation_created int(11) DEFAULT NULL" 2>/dev/null
        drush sqlq "ALTER TABLE media_field_data ADD COLUMN content_translation_changed int(11) DEFAULT NULL" 2>/dev/null
    } || true

    # Fix missing content_translation columns in media_field_revision (Drupal 10.5+
    # content translation schema; prevents "Column not found" when saving media).
    drush sqlq "SELECT content_translation_uid FROM media_field_revision LIMIT 1" 2>/dev/null || {
        drush sqlq "ALTER TABLE media_field_revision ADD COLUMN content_translation_uid int(10) unsigned DEFAULT NULL" 2>/dev/null
        drush sqlq "ALTER TABLE media_field_revision ADD COLUMN content_translation_status tinyint(4) DEFAULT NULL" 2>/dev/null
        drush sqlq "ALTER TABLE media_field_revision ADD COLUMN content_translation_created int(11) DEFAULT NULL" 2>/dev/null
        drush sqlq "ALTER TABLE media_field_revision ADD COLUMN content_translation_changed int(11) DEFAULT NULL" 2>/dev/null
    } || true

    # Fix missing content_translation columns in taxonomy_term_field_data (Drupal 10.5+
    # content translation schema; prevents "Column not found" when saving taxonomy terms).
    drush sqlq "SELECT content_translation_uid FROM taxonomy_term_field_data LIMIT 1" 2>/dev/null || {
        drush sqlq "ALTER TABLE taxonomy_term_field_data ADD COLUMN content_translation_uid int(10) unsigned DEFAULT NULL" 2>/dev/null
        drush sqlq "ALTER TABLE taxonomy_term_field_data ADD COLUMN content_translation_status tinyint(4) DEFAULT NULL" 2>/dev/null
        drush sqlq "ALTER TABLE taxonomy_term_field_data ADD COLUMN content_translation_created int(11) DEFAULT NULL" 2>/dev/null
        drush sqlq "ALTER TABLE taxonomy_term_field_data ADD COLUMN content_translation_changed int(11) DEFAULT NULL" 2>/dev/null
    } || true

    # Fix missing content_translation columns in taxonomy_term_field_revision (Drupal 10.5+
    # content translation schema; prevents "Column not found" when saving taxonomy terms).
    drush sqlq "SELECT content_translation_uid FROM taxonomy_term_field_revision LIMIT 1" 2>/dev/null || {
        drush sqlq "ALTER TABLE taxonomy_term_field_revision ADD COLUMN content_translation_uid int(10) unsigned DEFAULT NULL" 2>/dev/null
        drush sqlq "ALTER TABLE taxonomy_term_field_revision ADD COLUMN content_translation_status tinyint(4) DEFAULT NULL" 2>/dev/null
        drush sqlq "ALTER TABLE taxonomy_term_field_revision ADD COLUMN content_translation_created int(11) DEFAULT NULL" 2>/dev/null
        drush sqlq "ALTER TABLE taxonomy_term_field_revision ADD COLUMN content_translation_changed int(11) DEFAULT NULL" 2>/dev/null
    } || true

    # Needs to be set to do an install from existing configuration.
    drush islandora:settings:create-settings-if-missing || echo "Warning: create-settings-if-missing failed, continuing..."
    local previous_owner_group=$(allow_settings_modifications ${site})
    drush islandora:settings:set-config-sync-directory "${DRUPAL_DEFAULT_CONFIGDIR}" || echo "Warning: set-config-sync-directory failed, continuing..."
    restore_settings_ownership ${site} ${previous_owner_group}
    
    # Skip installation since database already has imported data
    # install_site "${site}"
    echo "Skipping installation - database already contains imported data"

    # Ensure that settings which depend on environment variables like service urls are set dynamically on startup.
    # These may fail if database isn't ready, so make them non-fatal
    configure_islandora_module "${site}" || echo "Warning: configure_islandora_module failed, continuing..."
    configure_openseadragon "${site}" || echo "Warning: configure_openseadragon failed, continuing..."
    configure_islandora_default_module "${site}" || echo "Warning: configure_islandora_default_module failed, continuing..."
    # The following commands require several services
    # to be up and running before they can complete.
    # Use timeout to prevent blocking forever on unreachable host (islandora.traefik.me)
    timeout 60 bash -c 'while ! curl -s -o /dev/null -w "%{http_code}" http://fcrepo:8080/fcrepo/rest/ 2>/dev/null | grep -q 200; do sleep 2; done' || echo "Warning: Fedora wait timeout, continuing..."
    # Create missing solr cores.
    create_solr_core_with_default_config "${site}" || echo -e "\n\nERROR: SOLR was not initialized. Check the logs above for more details.\n\n"

    # Create namespace assumed one per site.
    create_blazegraph_namespace_with_default_properties "${site}" || echo "Warning: create_blazegraph_namespace failed, continuing..."
    # Need to run migration to get expected default content, now that our required services are running.
    import_islandora_migrations "${site}" || echo "Warning: import_islandora_migrations failed, continuing..."
    # Workaround for this issue (only seems to apply to islandora_fits):
    # https://www.drupal.org/project/drupal/issues/2914213
    # Uses Drupal 10 Entity API (taxonomy_term_load_multiple_by_name was removed in Drupal 8+)
    cat << 'FIXEOF' > /tmp/fix.php
<?php
$terms = \Drupal::entityTypeManager()->getStorage('taxonomy_term')->loadByProperties([
  'vid' => 'islandora_media_use',
  'name' => 'FITS File',
]);
if ($term = reset($terms)) {
  $term->set('field_external_uri', [['uri' => 'https://projects.iq.harvard.edu/fits']]);
  $term->save();
}
FIXEOF
    drush php:script /tmp/fix.php || echo "Warning: FITS fix script failed, continuing..."
    # Rebuild the cache.
    drush cr || echo "Warning: cache rebuild failed, continuing..."
    
    # Exit with success even if some commands failed
    exit 0
}
main
