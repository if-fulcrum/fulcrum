foreach (array('/fulcrum/fulcrum.php', "{$_SERVER['HOME']}/fulcrum/etc/fulcrum/php/fulcrum.php", "{$_SERVER['HOME']}/fulcrum/php/fulcrum.php") as $f) {
  if (is_file($f) && (include $f) && isset($_FULCRUM)) {
    fulcrum_cfg('pre', $_FULCRUM['conf']);
    break;
  }
}