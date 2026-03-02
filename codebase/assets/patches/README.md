# Patches

Patches applied via `composer.json` under `extra.patches`.

## drupal/core – Views empty relationship base

**File:** `views-empty-relationship-base.patch`

**Purpose:** Prevents `InvalidArgumentException: A valid cache entry key is required` and "Undefined array key 'base'" when a view has a relationship with an empty `base` in its definition (e.g. some Search API or contrib view configurations).

**Action:** Skips relationships with empty `definition['base']` in `QueryPluginBase::getEntityTableInfo()` before calling `ViewsData::get()`.

**Remove when:** Drupal core includes an equivalent guard. Check core issue queue for Views + relationship + empty base.
