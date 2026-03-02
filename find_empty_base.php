<?php
$config_names = [
  'views.view.frontpage', 'views.view.content', 'views.view.solr_search_content',
  'views.view.media', 'views.view.display_media', 'views.view.block_content',
  'views.view.comment', 'views.view.redirect', 'views.view.webform_submissions',
];
$db = \Drupal::database();
foreach ($config_names as $name) {
  $raw = $db->query("SELECT data FROM config WHERE name = :n", [':n' => $name])->fetchField();
  if ($raw) {
    $decoded = unserialize($raw);
    array_walk_recursive($decoded, function($v, $k) use ($name) {
      if ($k === 'base' && $v === '') {
        echo "Empty base in $name\n";
      }
    });
  }
}
echo "Done\n";
