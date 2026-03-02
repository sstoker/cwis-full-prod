<?php

namespace Drupal\islandora_iiif_hocr\Form;

use Drupal\Core\Form\ConfigFormBase;
use Drupal\Core\Form\FormStateInterface;
use Drupal\Core\Config\ConfigFactoryInterface;
use Drupal\search_api\IndexInterface;
use Drupal\views\Views;


/**
 * Configure Islandora iiif hocr settings for this site.
 */
class SettingsForm extends ConfigFormBase {

  /**
   * {@inheritdoc}
   */
  public function getFormId() {
    return 'islandora_iiif_hocr_settings';
  }

  /**
   * {@inheritdoc}
   */
  protected function getEditableConfigNames() {
    return ['islandora_iiif_hocr.settings'];
  }

  /**
   * {@inheritdoc}
   */
  public function buildForm(array $form, FormStateInterface $form_state) {
    $config = $this->config('islandora_iiif_hocr.settings');


    return parent::buildForm($form, $form_state);
  }

  /**
   * {@inheritdoc}
   */
  public function validateForm(array &$form, FormStateInterface $form_state) {
    parent::validateForm($form, $form_state);
  }

  /**
   * {@inheritdoc}
   */
  public function submitForm(array &$form, FormStateInterface $form_state) {
    $this->config('islandora_iiif_hocr.settings')
      ->set('solr_hocr_paged_content_display', $form_state->getValue('solr_hocr_paged_content_display'))
      ->set('solr_hocr_page_display', $form_state->getValue('solr_hocr_page_display'))
      ->set('solr_hocr_index', $form_state->getValue('solr_hocr_index'))
      ->set('solr_hocr_field', $form_state->getValue('solr_hocr_field'))
      ->save();
    parent::submitForm($form, $form_state);
  }

  public function solrHocrFieldListCallback(array &$form, FormStateInterface $form_state) {
    // Prepare our textfield. check if the example select field has a selected option.
    if ($index_id = $form_state->getValue('solr_hocr_index')) {
      $form['solr_hocr_fieldset']['solr_hocr_field']['#options'] = $this->hocrFieldOptionsFromIndexId($index_id);
      $form['solr_hocr_fieldset']['solr_hocr_field']['#default_value'] = $form_state->getValue('solr_hocr_field') ?? "";
    }
    else {
      $form['solr_hocr_fieldset']['solr_hocr_field']['#options'] = [];
    }
    // Return the updated select element.
    return $form['solr_hocr_fieldset']['solr_hocr_field'];
  }





  /**
   * @param $index_id
   *
   * Get a list of the media fields that use the ocr_highlight solr field type.
   *
   * @return array
   * @throws \Drupal\Component\Plugin\Exception\InvalidPluginDefinitionException
   * @throws \Drupal\Component\Plugin\Exception\PluginNotFoundException
   * @throws \Drupal\search_api\SearchApiException
   */
  private function hocrFieldOptionsFromIndexId($index_id) {
    $options = [];
    if(!empty($index_id)) {
      $search_api_index = $this->getIndexes($index_id)[$index_id] ?? NULL;
      if($search_api_index) {
        // Start by loading all the field type configs and getting a list of ocr_highlight field types.
        $configs = \Drupal::service('config.storage')->readMultiple(\Drupal::service('config.storage')->listAll('search_api_solr.solr_field_type'));
        foreach ($configs as $config) {
          if (!empty($config['custom_code']) && strpos($config['custom_code'], 'ocr_highlight') === 0) {
            // Here we end up with an array of search_api solr_text_custom fields and their corresponding language.
            $hocr_solr_field_languages['solr_text_custom:' . $config['custom_code']][] = $config['field_type_language_code'];
          }
        }
        $media_solr_fields = $search_api_index->getFieldsByDatasource('entity:media');
        foreach ($media_solr_fields as $field_id => $field_definition) {
          if (!empty($hocr_solr_field_languages[$field_definition->getType()])) {
            $options[$field_id] = $field_definition->getLabel();
          }
        }
      }
    }
    return $options;
  }

}
