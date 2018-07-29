{
  "site" : "${FULCRUM_SITE}",
  "env" : "${FULCRUM_ENVIRONMENT}",
  "webroot" : "${FULCRUM_WEBROOT}",
  ${FULCRUM_S3_JSON}
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
        "file_temporary_path"        : "/tmp"
      }
    }
  }
}