<?php

namespace Drupal\flysystem\Plugin;

use Drupal\Component\Utility\Crypt;
use Drupal\Core\Entity\EntityTypeManagerInterface;
use Drupal\image\Entity\ImageStyle;

/**
 * Helper trait for generating URLs from adapter plugins.
 */
trait ImageStyleGenerationTrait {

  /**
   * Generates an image style for a file target.
   *
   * @param string $target
   *   The file target.
   *
   * @return bool
   *   True on success, false on failure.
   *
   * @deprecated in flysystem:2.2.0 and is removed from flysystem:3.0.0.
   *   Adapters should use generateImageUrl() to enable non-blocking image
   *   uploads.
   *
   * @see https://www.drupal.org/project/flysystem/issues/2661588
   *
   * @todo Revise per https://www.drupal.org/project/flysystem/issues/2661588#comment-10972463
   */
  protected function generateImageStyle($target) {
    if (strpos($target, 'styles/') !== 0 || substr_count($target, '/') < 3) {
      return FALSE;
    }

    [, $style, $scheme, $file] = explode('/', $target, 4);

    if (!$image_style = ImageStyle::load($style)) {
      return FALSE;
    }

    $image_uri = $scheme . '://' . $file;

    $derivative_uri = $image_style->buildUri($image_uri);

    if (!file_exists($image_uri)) {
      $path_info = pathinfo($image_uri);
      $converted_image_uri = $path_info['dirname'] . '/' . $path_info['filename'];

      if (!file_exists($converted_image_uri)) {
        return FALSE;
      }
      else {
        // The converted file does exist, use it as the source.
        $image_uri = $converted_image_uri;
      }
    }

    $lock_name = 'image_style_deliver:' . $image_style->id() . ':' . Crypt::hashBase64($image_uri);

    if (!file_exists($derivative_uri)) {
      $lock_acquired = \Drupal::lock()->acquire($lock_name);
      if (!$lock_acquired) {
        return FALSE;
      }
    }

    $success = file_exists($derivative_uri) || $image_style->createDerivative($image_uri, $derivative_uri);

    if (!empty($lock_acquired)) {
      \Drupal::lock()->release($lock_name);
    }

    return $success;
  }

  /**
   * Return the external URL for a generated image.
   *
   * @param string $target
   *   The target URI.
   *
   * @return string
   *   The generated URL.
   */
  protected function generateImageUrl($target) {
    [, $style, $scheme, $file] = explode('/', $target, 4);
    $args = [
      'image_style' => $style,
      'scheme' => $scheme,
      'filepath' => $file,
    ];

    if (empty($this->entityTypeManager)) {
      @trigger_error('Calling ' . __METHOD__ . '() in a class without the $entityTypeManager property set is deprecated in flysystem:2.3.0 and it will be required in flysystem:3.0.0. See https://www.drupal.org/project/flysystem/issues/3513799', E_USER_DEPRECATED);
      $entityTypeManager = \Drupal::entityTypeManager();
    }
    else {
      $entityTypeManager = $this->entityTypeManager;
    }
    assert($entityTypeManager instanceof EntityTypeManagerInterface);

    $imageStyle = $entityTypeManager
      ->getStorage('image_style')
      ->load($style);
    assert($imageStyle instanceof ImageStyle);

    return \Drupal::urlGenerator()->generateFromRoute(
      'flysystem.image_style_redirect.serve',
      $args,
      [
        'absolute' => TRUE,
        'query' => [IMAGE_DERIVATIVE_TOKEN => $imageStyle->getPathToken("$scheme://$file")],
      ]
    );
  }

}
