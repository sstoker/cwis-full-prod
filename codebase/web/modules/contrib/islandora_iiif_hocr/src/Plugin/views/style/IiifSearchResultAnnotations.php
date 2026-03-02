<?php

namespace Drupal\islandora_iiif_hocr\Plugin\views\style;

use Drupal\Core\Entity\Annotation\EntityType;
use Drupal\Core\Entity\EntityTypeManagerInterface;
use Drupal\Core\Form\FormStateInterface;
use Drupal\islandora\IslandoraUtils;
use Drupal\search_api\Item\Item;
use Drupal\search_api\Plugin\views\ResultRow;
use Drupal\views\Plugin\views\style\StylePluginBase;
use Drupal\views\ViewExecutable;
use Symfony\Component\DependencyInjection\ContainerInterface;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Serializer\SerializerInterface;

/**
 * IIIF Search Result Annotations style plugin.
 *
 * @ViewsStyle(
 *   id = "islandora_iiif_hocr_iiif_search_result_annotations",
 *   title = @Translation("IIIF Search Result Annotations"),
 *   help = @Translation("IIIF Annotation formatted search results for paged content."),
 *   display_types = {"data"}
 * )
 */
class IiifSearchResultAnnotations extends StylePluginBase {
/**
 * Undocumented variable
 *
 * @var [type]
 */
protected $canvasMediaUseTerm;

protected $usesOptions = TRUE;


  /**
   * {@inheritdoc}
   */
  protected $usesRowPlugin = TRUE;

  /**
   * {@inheritdoc}
   */
  protected $usesRowClass = TRUE;

  /**
   * The allowed formats for this serializer. Default to only JSON.
   *
   * @var array
   */
  protected $formats = ['json'];

  /**
   * The Drupal Entity Type Manager service.
   *
   * @var \Drupal\Core\Entity\EntityTypeManagerInterface
   */
  protected $entityTypeManager;

  /**
   * The request service.
   *
   * @var \Symfony\Component\HttpFoundation\Request
   */
  protected $request;

  /**
   * Islandora utility functions.
   *
   * @var \Drupal\islandora\IslandoraUtils
   */
  protected $utils;


  /**
   * Returns an array of format options.
   *
   * @return string[]
   *   An array of the allowed serializer formats. In this case just JSON.
   */
  public function getFormats() {
    return ['json' => 'json'];
  }
    /**
   * The serializer which serializes the views result.
   *
   * @var \Symfony\Component\Serializer\Serializer
   */
  protected $serializer;

  public function __construct(array $configuration, $plugin_id, $plugin_definition, SerializerInterface $serializer, IslandoraUtils $utils, EntityTypeManagerInterface $entity_type_manager, Request $request) {
    parent::__construct($configuration, $plugin_id, $plugin_definition);

    $this->serializer = $serializer;
    $this->utils = $utils;
    $this->entityTypeManager = $entity_type_manager;
    $this->request = $request;
  }

    /**
   * {@inheritdoc}
   */
  public static function create(ContainerInterface $container, array $configuration, $plugin_id, $plugin_definition) {
    return new static(
      $configuration,
      $plugin_id,
      $plugin_definition,
      $container->get('serializer'),
      $container->get('islandora.utils'),
      $container->get('entity_type.manager'),
      $container->get('request_stack')->getCurrentRequest(),
    );

  }

  /**
   * {@inheritdoc}
   */
  protected function defineOptions() {
    $options = parent::defineOptions();
    $options['canvas_media_term_uri'] = ['default' => 'string'];
    return $options;
  }

  /**
   * {@inheritdoc}
   */
  public function render() {


    $this->view->addCacheContext('url.query_args');
    $json = [];

    $json["@context"] = "http://iiif.io/api/presentation/2/context.json";
    $json["startIndex"] = $this->view->getOffset();

    if ($pager = $this->view->getPager()) {
      $total = $pager->getTotalItems();
    }
    else {

    }

    $json["within"]["total"] = $total;
    $json['within']['@type'] = "sc:Layer";

    $json['@type'] = "sc:AnnotationList";

    if (empty($this->canvasMediaUseTerm)) {
      $this->canvasMediaUseTerm = $this->utils->getTermForUri($this->options['canvas_media_term_uri']);
    }
    $json['resources'] = [];
    foreach ($this->view->result as $row) {
      $row_resources = $this->getAnnotationsForRow($row);
      if (!empty($row_resources)) {
        array_push($json['resources'],  ...$row_resources);
    }
    }
    return $this->serializer->serialize($json, 'json', ['views_style_plugin' => $this]);
  }

  /**
   * {@inheritdoc}
   */
  public function buildOptionsForm(&$form, FormStateInterface $form_state) {
    parent::buildOptionsForm($form, $form_state);

    $form['canvas_media_term'] = [
      '#type' => 'entity_autocomplete',
      '#target_type' => 'taxonomy_term',
      '#title' => $this->t('Canvas media use term'),
      '#default_value' => !empty($this->options['canvas_media_term_uri']) ? $this->utils->getTermForUri($this->options['canvas_media_term_uri']) : '',
      '#required' => TRUE,
      '#description' => $this->t('Media Use term used by the media that will contain the canvas that the result snippets come from.'),
    ];



  }

  /**
   * Submit handler for options form.
   *
   * Used to store the canvas media term by URL instead of Ttid.
   *
   * @param array $form
   *   The form.
   * @param \Drupal\Core\Form\FormStateInterface $form_state
   *   The form state object.
   */
  // @codingStandardsIgnoreStart
  public function submitOptionsForm(&$form, FormStateInterface $form_state) {
    // @codingStandardsIgnoreEnd
    $style_options = $form_state->getValue('style_options');
    $tid = $style_options['canvas_media_term'];
    $term = $this->entityTypeManager->getStorage('taxonomy_term')->load($tid);
    $style_options['canvas_media_term_uri'] = $this->utils->getUriForTerm($term);
    $form_state->setValue('style_options', $style_options);
    parent::submitOptionsForm($form, $form_state);
  }



  protected function getAnnotationsForRow(ResultRow $row): array {

    $row_resources = [];

    /**
     * @var Drupal\search_api\Item\Item
     */
    $item = $row->_item;
     if ($extra = $item->getExtraData('islandora_hocr_highlights')) {
      [$entity_placeholder, $entity_type, $entity_id, $language] = explode('/', str_replace(':', '/', $item->getId()));
      $mids = $this->utils->getMediaReferencingNodeAndTerm($item->getOriginalObject()->getEntity(), $this->canvasMediaUseTerm);
      $mid = reset($mids);
      $base_url = $this->request->getSchemeAndHttpHost();

      // Used for building the canvas ID, which uses the book ID not the page's.
      $parent_nid = $this->view->args[0];

      foreach ($extra as $snippet_field_name) {
        if (!empty($snippet_field_name['snippets'])) {
          foreach ($snippet_field_name['snippets'] as $snippet) {
            if (!empty($snippet['highlights'])) {
              foreach($snippet['highlights'] as $highlight_region => $highlight_wrapper) {
                if (!empty($highlight_wrapper) && is_array($highlight_wrapper)) {
                  foreach ($highlight_wrapper as $highlight) {
                    $ulx = $highlight['ulx'];
                     $uly = $highlight['uly'];
                     $lrx = $highlight['lrx'];
                     $lry = $highlight['lry'];

                     // The canvas's origin point is at the top-left.
                     $x = $ulx;
                     $y = $uly;
                     $w = abs($lrx - $ulx);
                     $h = abs($uly - $lry);

                     $resource = [];
                     $resource["@type"] = "Annotation";
                     $resource["motivation"] = "sc:painting";
                     $resource["resource"]["@type"] = "dctypes:Text";
                     $resource["resource"]["format"] = "text/html";
                     $resource["resource"]["chars"] = $snippet["text"];
                     $resource["resource"]["http://dev.llgc.org.uk/sas/full_text"] = $snippet['text'];

                     $search_annotation ='/node/' . $parent_nid . '/canvas/' . $mid . '#xywh=' . $x . ',' . $y . ',' . $w . ',' . $h;
                     $resource['on'] = $base_url . $search_annotation;

                     $resource['@id'] = $base_url. '/annotation/' . md5($search_annotation);
                     $resource["label"] = $highlight["text"];

                     $row_resources[] = $resource;

                  }
                }
              }
            }
          }
        }
      }
    }
return $row_resources;
  }

}
