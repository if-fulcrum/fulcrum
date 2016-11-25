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
        "redis_client_host"          : "redis2-8",
        "redis_client_interface"     : "PhpRedis",
        "cache_default_class"        : "Redis_Cache",
        "cache_prefix"               : {"default" : "${FULCRUM_DBNAME}"},
        "cache_class_cache_form"     : "DrupalDatabaseCache",
        "lock_inc"                   : "sites/all/modules/contrib/redis/redis.lock.inc"
      }
    },
    "append" : {
      "conf" : {
        "cache_backends" : [
          "sites/all/modules/contrib/redis/redis.autoload.inc"
        ]
      }
    }
  }
}