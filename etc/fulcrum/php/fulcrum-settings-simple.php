
if ($ff = '/fulcrum/fulcrum.php' AND file_exists($ff) AND (include $ff) AND isset($_FULCRUM)) {
  fulcrum_cfg('pre', $_FULCRUM['conf']);
}
