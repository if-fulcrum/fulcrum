<?php

// correct client IP, since we cannot provide CIDR to reverse_proxy_addresses we set REMOTE_ADDR
if (isset($_SERVER['HTTP_CF_CONNECTING_IP'])) {
  $_SERVER['REMOTE_ADDR'] = $_SERVER['HTTP_CF_CONNECTING_IP'];
} else if (isset($_SERVER['HTTP_X_FORWARDED_FOR'])) {
  $ips = explode(',', $_SERVER['HTTP_X_FORWARDED_FOR']);
  $_SERVER['REMOTE_ADDR'] = trim(current($ips));
}

// see if we are run from the server or command line
if (isset($_SERVER['FULCRUM_CONF'])) {
  $_FULCRUM['conf'] = json_decode($_SERVER['FULCRUM_CONF'], 1);

  // extend execution time for long tasks
  if (
    isset($_SERVER['REQUEST_URI']) &&
    in_array($_SERVER['REQUEST_URI'], array(
      '/admin/config/development/configuration/full/export-download',
    ))
  ) {
    set_time_limit(300);
  }
} else if (PHP_SAPI === 'cli') {
  if (file_exists('/config.json')) {
    $_FULCRUM['conf'] = json_decode(preg_replace('/\\\\\\\\/', '\\', file_get_contents('/config.json')), 1);
  } else if (isset($_SERVER['FCONF'])) {
    $_FULCRUM['conf'] = json_decode(preg_replace('/\\\\\\\\/', '\\', $_SERVER['FCONF']), 1);
  } else if (
    preg_match(          "#(.*)/(?:fulcrum/sites(?:/docroot)?)/([^/]+).*#", getcwd(), $matches) AND
    $json = preg_replace("#(.*)/(?:fulcrum/sites(?:/docroot)?)/([^/]+).*#", "$1/fulcrum/etc/fulcrum/conf/$2.json", getcwd()) AND
    file_exists($json)
  ) {
    global $base_url;
    $base_url = "http://{$matches[2]}";
    ini_set('memory_limit','512M');
    $_FULCRUM['conf'] = json_decode(preg_replace('/\\\\\\\\/', '\\', file_get_contents($json)), 1);
  }
}

if (!function_exists('fulcrum_force_https')) {
  function fulcrum_force_https() {
    if (PHP_SAPI !== 'cli' && (!isset($_SERVER['HTTP_X_FORWARDED_PROTO']) || $_SERVER['HTTP_X_FORWARDED_PROTO'] == 'http')) {
      header('HTTP/1.0 301 Moved Permanently');
      header('Location: https://' . $_SERVER['SERVER_NAME'] . $_SERVER['REQUEST_URI']);
      exit();
    }
  }
}

if (!function_exists('fulcrum_cfg')) {
  function fulcrum_cfg($phase, $fcfg, &$settings = NULL, &$databases = NULL) {
    if (isset($fcfg[$phase])) {
      $special = array('settings', 'databases');
      foreach ($fcfg[$phase] as $action => $vars) {
        foreach ($vars as $var_name => $var_val) {
          if ($action == 'replace') {
            if (in_array($var_name, $special) && is_array(${$var_name})) {
              ${$var_name} = $var_val;
            } else {
              $GLOBALS[$var_name] = $var_val;
            }
          } else {
            foreach ($var_val as $key => $val) {
              if ($action == 'set') {
                if (in_array($var_name, $special) && is_array(${$var_name})) {
                  ${$var_name}[$key] = $val;
                } else {
                  $GLOBALS[$var_name][$key] = $val;
                }
              } else if ($action == 'append') {
                foreach ($var_val[$key] as $i => $item) {
                  if (in_array($var_name, $special) && is_array(${$var_name})) {
                    ${$var_name}[$key][] = $item;
                  } else {
                    $GLOBALS[$var_name][$key][] = $item;
                  }
                }
              }
            }
          }
        }
      }

      if (isset($fcfg['force_https']) && $fcfg['force_https'] == 'true') {
        fulcrum_force_https();
      }
      if (isset($fcfg['timezone'])) {
        date_default_timezone_set($fcfg['timezone']);
      }
    }
  }
}
