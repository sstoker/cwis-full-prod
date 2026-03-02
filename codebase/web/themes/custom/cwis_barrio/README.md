# CWIS Barrio

Custom Barrio Bootstrap 5 subtheme for CWIS/Islandora.

## Structure

- **Base theme:** [Bootstrap Barrio](https://www.drupal.org/project/bootstrap_barrio) (5.5.x)
- **CSS:** `css/style.css` – add custom styles here.
- **JS:** `js/global.js` – add custom behaviors (Drupal.behaviors).
- **Templates:** Override base theme or Barrio templates in `templates/` as needed.
- **Logo:** `logo.svg` – replace with your site logo (SVG recommended).
- **Screenshot:** Add `screenshot.png` (588×438 px) for the Appearance page.

## Customization

1. **Styles:** Edit `css/style.css` or add new CSS files and declare them in `cwis_barrio.libraries.yml`.
2. **Theme settings:** Configure via Appearance → Settings → CWIS Barrio. Base Barrio options (container, navbars, etc.) are under the base theme.
3. **Bootstrap:** This subtheme loads Bootstrap from `web/libraries/bootstrap/dist/`. That copy is updated by the project’s `composer.json` `post-update-cmd` script.

## Dependencies

- Bootstrap Barrio (contrib)
- Bootstrap library in `web/libraries/bootstrap/` (provided by Composer post-update script)
