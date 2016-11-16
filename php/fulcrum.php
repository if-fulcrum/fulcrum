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
} else if (PHP_SAPI === 'cli') {
  if (file_exists('/config.json')) {
    $_FULCRUM['conf'] = json_decode(preg_replace('/\\\\\\\\/', '\\', file_get_contents('/config.json')), 1);
  } else if (
    preg_match(          "#(.*)/(?:repos(?:/docroot)?|fulcrum/webroots)/([^/]+).*#", getcwd(), $matches) AND
    $json = preg_replace("#(.*)/(?:repos(?:/docroot)?|fulcrum/webroots)/([^/]+).*#", "$1/fulcrum/conf/$2.json", getcwd()) AND
    file_exists($json)
  ) {
    global $base_url;
    $base_url = "http://{$matches[3]}";
    ini_set('memory_limit','512M');
    $_FULCRUM['conf'] = json_decode(preg_replace('/\\\\\\\\/', '\\', file_get_contents($json)), 1);
  }
}

if (!function_exists('fulcrum_cfg')) {
  function fulcrum_cfg($phase, $fcfg, &$settings = NULL, &$databases = NULL) {
    if (isset($fcfg[$phase])) {
      $special = array('settings', 'databases');
      foreach ($fcfg[$phase] as $action => $vars) {
        foreach ($vars as $var_name => $var_val) {
          if ($action == 'replace') {
            if (in_array($var_name, $special) && !is_null($$var_name)) {
              ${$var_name} = $var_val;
            } else {
              $GLOBALS[$var_name] = $var_val;
            }
          } else {
            foreach ($var_val as $key => $val) {
              if ($action == 'set') {
                if (in_array($var_name, $special) && !is_null($$var_name)) {
                  ${$var_name}[$key] = $val;
                } else {
                  $GLOBALS[$var_name][$key] = $val;
                }
              } else if ($action == 'append') {
                foreach ($var_val[$key] as $i => $item) {
                  if (in_array($var_name, $special) && !is_null($$var_name)) {
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
    }
  }
}