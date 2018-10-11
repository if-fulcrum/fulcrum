if (function_exists('fulcrum_config')) {
  fulcrum_config('pre');
  require_once DRUPAL_ROOT . '/sites/all/modules/contrib/domain/settings.inc'; // Domain Access requires 2 phases
  fulcrum_config('post');
}