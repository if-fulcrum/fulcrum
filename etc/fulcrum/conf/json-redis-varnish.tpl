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
        "file_temporary_path"        : "/tmp",
        "redis_client_host"          : "redis",
        "redis_client_interface"     : "PhpRedis",
        "cache_default_class"        : "Redis_Cache",
        "cache_prefix"               : {"default" : "${FULCRUM_DBNAME}"},
        "cache_class_cache_form"     : "DrupalDatabaseCache",
        "lock_inc"                   : "sites/all/modules/contrib/redis/redis.lock.inc",
        "varnish_control_terminal"   : "varnish:6082",
        "varnish_version"            : "4",
        "varnish_control_key"        : "${FULCRUM_VARN_SECRET}"
      }
    },
    "append" : {
      "conf" : {
        "cache_backends" : [
          "sites/all/modules/contrib/redis/redis.autoload.inc",
          "sites/all/modules/contrib/varnish/varnish.cache.inc"
        ]
      }
    }
  }
}