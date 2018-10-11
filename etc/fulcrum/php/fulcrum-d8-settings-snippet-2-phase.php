if (function_exists('fulcrum_config')) {
  fulcrum_config('pre',  $settings, $databases);
  require_once DRUPAL_ROOT . '/modules/contrib/domain/settings.inc'; // Domain Access requires 2 phases
  fulcrum_config('post', $settings, $databases);
}