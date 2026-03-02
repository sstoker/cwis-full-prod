# Performance Optimization Changes

This document describes the performance optimizations applied to improve site loading speed.

## Changes Applied

### 1. Page cache enabled
- **File:** `codebase/config/sync/system.performance.yml`
- **Change:** `cache.page.max_age` set from `0` to `900` (15 minutes)
- **Effect:** Anonymous users receive cached HTML instead of dynamically generated pages.

### 2. Internal FCREPO URL
- **Files:** `build/docker-compose/docker-compose.drupal.yml`
- **Change:** `DRUPAL_DEFAULT_FCREPO_URL` changed to `http://fcrepo:8080/fcrepo/rest/`
- **Effect:** Drupal communicates with Fedora directly over the internal Docker network.

### 3. Traefik compression
- **Files:** `build/docker-compose/docker-compose.drupal.yml`, `build/docker-compose/docker-compose.cantaloupe.yml`
- **Change:** Added gzip compression middleware for Drupal and Cantaloupe responses
- **Effect:** HTML, CSS, JavaScript, and IIIF JSON responses are compressed.

## Deployment Steps

1. Rebuild the Drupal image: `make build`
2. Restart services: `docker compose up -d --force-recreate drupal cantaloupe traefik`
3. Import Drupal config: `docker compose exec drupal drush config:import -y`
4. Clear caches: `docker compose exec drupal drush cr`
