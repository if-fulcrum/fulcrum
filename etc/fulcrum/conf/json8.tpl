{
  "site" : "${FULCRUM_SITE}",
  "env" : "${FULCRUM_ENVIRONMENT}",
  "webroot" : "${FULCRUM_WEBROOT}",
  "pre" :  {
    "replace" : {
      "databases" : {
        "default" : {
          "default" : {
            "driver"   : "mysql",
            "namespace"   : "Drupal\\\\Core\\\\Database\\\\Driver\\\\mysql",
            "database" : "${FULCRUM_DBNAME}",
            "username" : "${FULCRUM_DBUSER}",
            "password" : "${FULCRUM_DBPASS}",
            "host"     : "mariadb",
            "prefix"   : ""
          }
        }
      }
    },
    "set" : {
      "settings" : {
        "hash_salt" : "${FULCRUM_SALT}",
        "install_profile" : "standard",
        "file_public_path" : "sites/default/files"
      },
      "config_directories" : {
        "sync" : "${FULCRUM_D8CONFIG}"
      }
    }
  }
}