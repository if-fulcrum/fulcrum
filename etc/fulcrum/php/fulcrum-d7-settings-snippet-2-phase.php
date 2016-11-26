// Domain Access requires 2 phases
foreach (array('/fulcrum/fulcrum.php', "{$_SERVER['HOME']}/fulcrum/etc/fulcrum/php/fulcrum.php", "{$_SERVER['HOME']}/fulcrum/php/fulcrum.php") as $f) {
  if (is_file($f) && (include $f) && isset($_FULCRUM)) {
    fulcrum_cfg('pre', $_FULCRUM['conf']);
    require_once DRUPAL_ROOT . '/sites/all/modules/contrib/domain/settings.inc';
    fulcrum_cfg('post', $_FULCRUM['conf']);
    break;
  }
}