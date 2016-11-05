{
  "env" : "${FULCRUM_ENVIRONMENT}",
  "webroot" : "${FULCRUM_WEBROOT}",
  "pre" :  {
    "replace" : {
      "databases" : {
        "default" : {
          "default" : {
            "driver"   : "mysql",
            "database" : "${FULCRUM_DBNAME}",
            "username" : "${FULCRUM_DBUSER}",
            "password" : "${FULCRUM_DBPASS}",
            "host"     : "mariadb",
            "prefix"   : ""
          }
        }
      },
      "cookie_domain" : "${FULCRUM_COOKIE}",
      "drupal_hash_salt" : "${FULCRUM_SALT}"
    },
    "set" : {
      "conf" : {
        "file_public_path"           : "sites/default/files",
        "file_temporary_path"        : "/tmp",
        "varnish_control_terminal"   : "varnish:6082",
        "varnish_version"            : "4",
        "varnish_control_key"        : "05f41c5c8787aa214e1966c155990488"
      }
    },
    "append" : {
      "conf" : {
        "cache_backends" : [
          "sites/all/modules/contrib/varnish/varnish.cache.inc"
        ]
      }
    }
  }
}