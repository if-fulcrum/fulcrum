
if ($ff = '/fulcrum/fulcrum.php' AND file_exists($ff) AND (include $ff) AND isset($_FULCRUM)) {
  fulcrum_cfg('pre', $_FULCRUM['conf']);

  // Domain Access
  require_once DRUPAL_ROOT . '/sites/all/modules/contrib/domain/settings.inc';

  fulcrum_cfg('post', $_FULCRUM['conf']);
}
