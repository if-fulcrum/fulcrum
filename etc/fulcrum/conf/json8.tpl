{
  "site" : "${FULCRUM_SITE}",
  "env" : "${FULCRUM_ENVIRONMENT}",
  "webroot" : "${FULCRUM_WEBROOT}",
  "timezone" : "UTC",
  ${FULCRUM_S3_JSON}
  ${FULCRUM_CONF_EXTRA}
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
      "config" : {
        "system.file" : {
          "path" : {
            "temporary" : "/tmp"
          }
        },
        "search_api.server.solr1" : {
          "backend_config" : {
            "connector_config" : {
              "host" : "solr"
            }
          }
        },
        "s3fs.settings" : {
          "root_folder" : "${FULCRUM_S3_ROOT}",
          "bucket" : "${FULCRUM_S3_BUCKET}",
          "region" : "${FULCRUM_S3_REGION}",
          "use_https" : true
        },
        "elasticsearch_connector.cluster.elasticsearch1" : {
          "url" : "http://elasticsearch:9200"
        }
      },
      "settings" : {
        "container_yamls" : [
          "sites/default/services.yml",
          "modules/redis/example.services.yml"
        ],
        "redis.connection" : {
          "interface" : "PhpRedis",
          "host" : "redis",
          "port" : "6379"
        },
        "cache_prefix" : {
          "default" : "${FULCRUM_DBNAME}"
        },
        "cache" : {
          "bins" : {
            "bootstrap" : "cache.backend.chainedfast",
            "discovery" : "cache.backend.chainedfast",
            "config" : "cache.backend.chainedfast"
          }
        },
        "hash_salt" : "${FULCRUM_SALT}",
        "install_profile" : "standard",
        "file_public_path" : "sites/default/files",
        "file_private_path" : "${FULCRUM_PRIV_DIR}",
        "s3fs.access_key" : "${FULCRUM_S3_ACCESS_KEY}",
        "s3fs.secret_key" : "${FULCRUM_S3_SECRET_KEY}",
        "s3fs.use_s3_for_public" : true,
        "php_storage" : {
          "twig" : {
            "directory" : "${FULCRUM_TWIG_DIR}"
          }
        }
      },
      "config_directories" : {
        "sync" : "${FULCRUM_D8CONFIG}"
      }
    }
  }
}
