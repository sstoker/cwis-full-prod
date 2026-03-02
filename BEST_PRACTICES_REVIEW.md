# Isle DC Production – Best Practices Review

Assessment of the current setup at **library.cwis.org** (Islandora/Drupal in Docker).

---

## What’s Already in Good Shape

### Security

- **Secrets**
  - `USE_SECRETS=true`; DB and app passwords come from Docker secrets (files under `secrets/live/`), not env vars in compose.
  - `.gitignore` excludes `.env` and `secrets/live/*`, so secrets are not committed.
  - Init scripts (`05-fix-db-password.sh`, `07-fix-secret-permissions.sh`, `99-secure-settings.sh`) ensure:
    - DB password is read from secret (and a restricted copy for the web server).
    - `settings.php` is made read-only (444) after startup and has no hardcoded passwords.

- **Internal services not exposed**
  - `.env` has `EXPOSE_MYSQL=false`, `EXPOSE_POSTGRES=false`, `EXPOSE_TRAEFIK_DASHBOARD=false`, `EXPOSE_SOLR=false`, `EXPOSE_BLAZEGRAPH=false`, `EXPOSE_ACTIVEMQ=false` — good for production.

- **TLS**
  - Let’s Encrypt (ACME) with EC256, `USE_ACME=true`, HTTPS for the site.

- **Drupal**
  - Config sync directory set; hash salt from secret; reverse proxy and trusted host patterns in default settings; Twig compiled outside docroot; private files outside web root.

### Operations & Resilience

- **Resource limits**
  - Memory limits and reservations set per service (e.g. Drupal 5G, Solr 8G, MariaDB 1G).

- **Restart policy**
  - `restart: unless-stopped` on services.

- **Networks**
  - Separate default (internal) and gateway networks; only Traefik on gateway.

- **Backups**
  - Documented 3-2-1 approach: local + GitHub for codebase and docker-compose; cron for codebase and compose backups; verification and monitoring scripts.

### Codebase & Config

- **Drupal**
  - Config in `config/sync/` (hundreds of YAML files); Composer-managed dependencies; Drupal 10 with PHP 8.3.

- **Docker**
  - Custom Drupal image built from Islandora base; codebase copied in at build; no `settings.php` or files in image (handled at runtime).

- **Verification**
  - `scripts/verify-best-practices.sh` checks settings.php, DB, SSL, secrets, etc.

---

## Gaps and Recommendations

### 1. Traefik port bindings (production hardening)

**Current:** The main `docker-compose.yml` publishes many ports on the Traefik service (80, 443, 8081, 3306, 5432, 8080, 8082, 8161, 8983). Even with backend `traefik.enable=false`, those ports are still bound on the host.

**Recommendation:** If this file is generated from Isle build/templates, ensure the generator only publishes 80 and 443 (and 8081 only if Fedora must be reachable) in production. Avoid publishing 3306, 5432, 8080, 8082, 8161, 8983 unless you explicitly need them exposed. If you maintain the compose by hand, remove the unused port mappings.

### 2. Page cache (performance)

**Current:** `config/sync/system.performance.yml` has `cache.page.max_age: 0` (page cache disabled).

**Recommendation:** For a production site that isn’t changing on every request, enable page cache and set a positive `max_age` (e.g. 300 or 900) for anonymous users. Tune by content type if needed (e.g. longer for static pages, shorter for search).

### 3. Config vs database drift (post–Civic cleanup)

**Current:** After removing the Civic theme, the database still has modules and config that were removed from the codebase (e.g. references to `asset_injector`, `redirect`, `layout_builder_styles`). Some were cleaned from `core.extension` and config, but drift may remain (e.g. orphaned config, disabled blocks).

**Recommendation:**
- Avoid full `config:import` until you’ve resolved “content exists” / missing-extension errors.
- Re-export active config once the site is stable:  
  `drush config:export` (then commit and back up) so `config/sync` matches the intended production state.
- Document any config that must stay “DB-only” (e.g. block placement) if you don’t want it overwritten by import.

### 4. Front page and Solr search blocks (known workarounds)

**Current:** Front page was set to `/user/login` to avoid a 500; Solr search view blocks were disabled due to a Views relationship with an empty base table.

**Recommendation:**
- Fix the underlying view (remove or fix the relationship that references a missing table), then:
  - Set `system.site.page.front` back to the desired node (e.g. `/node/17`).
  - Re-enable the Solr search blocks.
- Until then, treat “front = login” and “Solr blocks off” as temporary workarounds, not long-term best practice.

### 5. Version control of deployment assets

**Current:** `.gitignore` excludes `docker-compose.yml` and `Dockerfile`. Backups push the compose (and codebase) to separate repos.

**Recommendation:**
- Prefer tracking the *source* of the running stack (e.g. env-specific overrides, or the generator inputs that produce `docker-compose.yml`) in a repo, so changes are auditable and recoverable.
- If the main `docker-compose.yml` is generated, document how to regenerate it and where the “source of truth” lives (e.g. which repo and path).

### 6. Drupal cron

**Current:** Not visible in the files reviewed.

**Recommendation:** Ensure Drupal cron runs on a schedule (e.g. system cron calling `drush cron` or a container cron). Required for search indexing, queues, and other periodic tasks.

### 7. Dependency and image freshness

**Current:** `composer.json` uses ranges (e.g. `^10.1`, `^2.12.3`); images use `islandora/*:main` and `traefik:v3.4.1@sha256:...`.

**Recommendation:**
- Periodically run `composer update` (or update key packages) in a branch, test, then deploy.
- Pin Traefik (and other critical images) by digest where possible; plan upgrades for Islandora images when the project releases versioned tags or security advisories.

### 8. Logging and monitoring

**Current:** Traefik log level INFO; backup monitoring script and logs (e.g. `/var/log/backup-monitor.log`) are in place.

**Recommendation:**
- Ensure Drupal logs (e.g. `watchdog` / dblog) are rotated or shipped to a central log store so you can investigate errors (e.g. the recent ViewsData issue) without losing history.
- Optionally send key metrics (e.g. HTTP errors, response time) to a monitoring system.

---

## Summary

| Area           | Status | Notes                                                                 |
|----------------|--------|-----------------------------------------------------------------------|
| Secrets        | Good   | Docker secrets, no secrets in repo, init scripts secure settings.php  |
| TLS            | Good   | Let’s Encrypt, HTTPS                                                 |
| Internal ports | Good   | DB, Solr, etc. not exposed in .env                                   |
| Backups        | Good   | 3-2-1, cron, verification, docs                                     |
| Drupal config  | Good   | Sync directory, trusted host, reverse proxy                         |
| Port bindings  | Review | Reduce Traefik-published ports to 80/443 (and 8081 if needed)       |
| Page cache     | Fix    | Enable and set max_age for production                               |
| Config drift   | Fix    | Export config when stable; document DB-only config                 |
| Front/Solr     | Fix    | Fix broken view, then restore front page and Solr blocks            |
| Cron           | Verify | Confirm Drupal cron is scheduled                                    |
| Logging        | Optional | Rotate/ship logs; consider monitoring                             |

Overall, the setup follows security and operational best practices well. The main improvements are: tighten Traefik port exposure, enable page cache, align config sync with the live site after the Civic cleanup, and resolve the Views/Solr issue so the front page and search blocks can be re-enabled properly.
