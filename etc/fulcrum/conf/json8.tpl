{
  "site" : "${FULCRUM_SITE}",
  "env" : "${FULCRUM_ENVIRONMENT}",
  "webroot" : "${FULCRUM_WEBROOT}",
  "timezone" : "UTC",
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
	"search_api.server.solr1" : {
	  "backend_config" : {
	    "connector_config" : {
	      "host" : "solr"
	    }
	  }
	},
        "elasticsearch_connector.cluster.elasticsearch1" : {
	  "url" : "http://elastcisearch:9200"
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
        "file_public_path" : "sites/default/files"
      },
      "config_directories" : {
        "sync" : "${FULCRUM_D8CONFIG}"
      }
    }
  }
}