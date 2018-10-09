vcl 4.0;

import std;
import directors;

include "include/audience.vcl";
include "internal.vcl";
include "blacklist.vcl";
include "whitelist.vcl";
include "backends-webs.vcl";

# Respond to incoming requests.
sub vcl_recv {
  set req.backend_hint = web.backend();

  include "include/x-forward-for.vcl";

  # save the left most IP for whitelisting
  set req.http.X-Client-IP = regsub(req.http.X-Forwarded-For, "[, ].*$", "");

  # Only allow BAN requests from IP addresses in the 'purge' ACL.
  if (req.method == "BAN") {
      # Same ACL check as above:
      if (!client.ip ~ internal) {
          return (synth(403, "Not allowed."));
      }
      # We ban based on the url, not tags, as cloudflare business does not handle tags,
      # and drupal likes to do full tags or urls, not both.
      if (req.http.X-Url && req.http.X-Host) {
         # X-Url is not just the part after the domain name, but the whole thing, so we have to chop it up
         set req.http.X-Url = regsub(req.http.X-Url, "^https?://[^/]+/", "/");
         ban("req.http.host == " + req.http.X-Host + " && req.url == " + req.http.X-Url);
      }
      # Logic for the ban, using the Cache-Tags header. For more info
      # see https://github.com/geerlingguy/drupal-vm/issues/397.
      elseif (req.http.Cache-Tags && req.http.X-Host) {
        ban( "obj.http.X-Host == " + req.http.X-Host + " && obj.http.Cache-Tags ~ " + "#" + req.http.Cache-Tags + "#" );
      }
      # wildcard path bans, typically manually done
      # curl -X BAN -ksLI -H 'X-Url-Wildcard: /sites/default/files/css/*' -H 'host: example.com' -H 'X-Host: example.com' https://example.com
      elseif (req.http.X-Url-Wildcard && req.http.X-Host) {
        set req.http.X-Url-Wildcard = regsub(req.http.X-Url-Wildcard, "^https?://[^/]+/", "/");
        ban("req.http.host == " + req.http.X-Host + " && req.url ~ " + req.http.X-Url-Wildcard);
      }
      else {
        return (synth(403, "X-Url/X-Url-Wildcard/Cache-Tags header and/or X-Host header missing."));
      }
      # Throw a synthetic page so the request will not go to the backend.
      return (synth(200, "Ban added for " + req.http.X-Host));
  }

  # curl -X PURGE -ksLI -H 'host: example.com' -H 'X-Host: example.com' https://example.com/
  if (req.method == "PURGE") {
      # Same ACL check as above:
      if (!client.ip ~ internal) {
          return (synth(403, "Not allowed."));
      }
      return (purge);
  }

  # Use anonymous, cached pages if all backends are down.
  if (!std.healthy(req.backend_hint)) {
    unset req.http.Cookie;
  }

  # Allow the backend to serve up stale content if it is responding slowly.
  #
  # This is now handled in vcl_hit.
  #
  # set req.grace = 6h;

  # site wide ban, may need in future to do the right most, instead of left, most public ip
  if ( std.ip(req.http.X-Client-IP, client.ip) ~ blacklist ) {
    return (synth(403, "Access Denied."));
  }

  # after blacklist but before whitelist, for when you do not know the clients static IP
  # see later rules for rules after the whitelist IP check
  include "include/bypass-prewhitelist-rules.vcl";

  # Determines if the "public" part (not /user) can be hit.
  # audience.vcl should either be empty (dev/test) or 0.0.0.0/0 for a public (hinge/prd) setup
  # if IP in whitelist, you get access to both the frontend and /user
  # behind ELB -> HAproxy, it seems $_SERVER['HTTP_X_CLIENT_IP'];, not to be confused with HTTP_X_CLIENTIP
  if ( client.ip !~ audience && std.ip(req.http.X-Client-IP, client.ip) !~ whitelist ) {
    return (synth(403, "Access Denied."));
  }

  # Things with these in the url should just be blocked.
  # Check logs often for what the bad guys are after.
  # wp-admin
  # wp-content
  # wp-includes
  # wp-login
  # phpMyAdmin
  # /pma20 sniffers put in a random year at the end
  # /mysql
  # /cgi-bin
  # /autodiscover/autodiscover.xml
  if
  (
       req.url ~ "wp-(admin|content|includes|login)"
    || req.url ~ "(?i)phpmyadmin"
    || req.url ~ "/pma20"
    || req.url ~ "/mysql"
    || req.url ~ "cgi-bin"
    || req.url == "/autodiscover/autodiscover.xml"
  )
  { return (synth(404, "Not Found")); }

  # Do not allow outside access to certain php or txt files
  # Block user login and node add external
  # must be in whitelist.vcl to access /user
  # Also consider index.php?q=user as these can be POST at and make the redirect uncachable
  if ( !std.ip(req.http.X-Client-IP, client.ip) ~ whitelist &&
       (
            req.url ~ "^/((apc|authorize|cron|install|phptest|status|update)\.php|[A-Z]{6,11}[a-z\.]*\.txt)$"
         || req.url ~ "(?i)^/index.php\?q=?(admin.*|user.*|node/add|simplesaml*)"
         || req.url ~ "^/(admin|user|node/add|simplesaml)($|/.+)"
       )
  ) {
    return (synth(403, "Access Denied. " + std.ip(req.http.X-Client-IP, client.ip) ));
  }

  # Do not cache these paths.
  if (req.url ~ "^/(status|update)\.php$" ||
      req.url ~ "^/(admin/build/features|info/|flag/)" ||
      req.url ~ "^/system/files/.*$" ||
      req.url ~ "^.*/(ajax|ahah)/") {
       return (pass);
  }

  # Handle compression correctly. Different browsers send different
  # "Accept-Encoding" headers, even though they mostly all support the same
  # compression mechanisms. By consolidating these compression headers into
  # a consistent format, we can reduce the size of the cache and get more hits.=
  # @see: http:// varnish.projects.linpro.no/wiki/FAQ/Compression
  if (req.http.Accept-Encoding) {
    # https://www.getpagespeed.com/server-setup/varnish/varnish-brotli-done-right
    if (req.http.Accept-Encoding ~ "br" && req.url !~ "\.(jpg|png|gif|gz|mp3|mov|avi|mpg|mp4|swf|wmf)$") {
      set req.http.X-brotli = "true";
    } else if (req.http.Accept-Encoding ~ "gzip") {
      # If the browser supports it, we will use gzip.
      set req.http.Accept-Encoding = "gzip";
    } else if (req.http.Accept-Encoding ~ "deflate") {
      # Next, try deflate if it is supported.
      set req.http.Accept-Encoding = "deflate";
    } else {
      # Unknown algorithm. Remove it and send unencoded.
      unset req.http.Accept-Encoding;
    }
  }

  # Always cache the following file types for all users. This list of extensions
  # appears twice, once here and again in vcl_backend_response so make sure you edit both
  # and keep them equal.
  if (req.url ~ "(?i)\.(svg|woff|png|gif|jpe?g|ico|swf|css|js|html?|ttf)(\?[a-z0-9_=\?&\.-]+)?$") {
    unset req.http.Cookie;
  }

  # blackfire must bypass varnish for profiling - https://blackfire.io/login
  # allow header to bypass varnish
  if (req.http.X-Blackfire-Query || req.http.X-VARNISH-BYPASS) {
    return (pass);
  }

  # deal with Drupal cookie sessions, external file so it can be mounted over for exceptions
  include "include/vcl_recv_tail.vcl";
}

# Set a header to track a cache HIT/MISS.
sub vcl_deliver {

  # it seems varnish does not really run these durning the include for whatever reason
  # include "include/cache-tag-remove.vcl";

  # Remove ban-lurker friendly custom headers when delivering to client.
  unset resp.http.X-Url;
  unset resp.http.X-Host;

  # Comment these for easier Drupal cache tag debugging in development.
  unset resp.http.Cache-Tags;
  unset resp.http.X-Drupal-Cache-Contexts;

  # Just things to hide from the public
  unset resp.http.X-Generator;

  set resp.http.Via = "1.1 varnish";

  if (obj.hits > 0) {
    set resp.http.X-Varnish-Cache = "HIT";
  } else {
    set resp.http.X-Varnish-Cache = "MISS";
  }

  include "include/vcl_deliver_tail.vcl";
}

# Handle a cache hit.
sub vcl_hit {
  include "include/vcl_hit_tail.vcl";
}

# Routine used to determine the cache key if storing/retrieving a cached page.
sub vcl_hash {
  # hash data based on the domain (host) as to not have conflicts on foo.com/contact & bar.com/contact
  # also seperate based on http vs httpS else http will not redirect if its already in the cache
  # https://bensmann.no/seperate-varnish-caching-http-https/
  if (req.http.host && req.http.X-Forwarded-Proto ~ "https") {
      hash_data(req.http.X-Forwarded-Proto);
  }

  # https://www.getpagespeed.com/server-setup/varnish/varnish-brotli-done-right
  if(req.http.X-brotli == "true" && req.http.X-brotli-unhash != "true") {
    hash_data("brotli");
  }

  # now use the host (domain) part
  if (req.http.host) {
    hash_data(req.http.host);
  } else {
    hash_data(server.ip);
  }

  # strip off some of the timestamp used by javascript & Drupal itok that gets in the way of caching
  if (req.url ~ "(?i)^.*\.(?:png|gif|jpe?g)\?") {
    hash_data(regsub(req.url, "(?i)^(.*\.(?:png|gif|jpe?g))\?(?:itok=[^?&]+)?(?:[\?&](?:timestamp=)?1[4-6]\d{11})", "\1"));
  } else {
    hash_data(req.url);
  }

  include "include/vcl_hash_tail.vcl";

  return (lookup);
}

# Code determining what to do when serving items from the web servers.
# beresp == Back-end response from the web server.
sub vcl_backend_response {
  # Disable buffering only for BigPipe responses
  # comment out until ready to implement
  if (beresp.http.Surrogate-Control ~ "BigPipe/1.0") {
    set beresp.do_stream = true;
    set beresp.ttl = 0s;
  }

  # Set ban-lurker friendly custom headers.
  set beresp.http.X-Url = bereq.url;
  set beresp.http.X-Host = bereq.http.host;

  include "include/beresp-ttl.vcl";

  # large file kludge: dont cache files > 1mb
  # https://gist.github.com/mcphersoncreative/7469629
  if (beresp.http.Content-Length ~ "[0-9]{7,}" ) {
    set beresp.uncacheable = true;
    return (deliver);
  }

  # Do not allow static files to set cookies.
  # This list of extensions appears twice, once here and again in vcl_recv so
  # make sure you edit both and keep them equal.
  if (bereq.url ~ "(?i)\.(svg|woff|png|gif|jpe?g|ico|swf|css|js|html?|ttf)(\?[a-z0-9_=\?&\.-]+)?$") {
    # beresp == Back-end response from the web server.
    unset beresp.http.set-cookie;
  }

  # force cache for 5 minutes
  if (bereq.url ~ "^/(rss\.xml|robots\.txt|sites/all/themes/.*/twitterResults.php)$") {
    unset beresp.http.Cache-Control;
    set beresp.http.Cache-Control = "public, max-age=300";
  }

  # Allow items to be stale if needed.
  set beresp.grace = 6h;

  include "include/vcl_backend_response_tail.vcl";
}

# https://varnish-cache.org/docs/4.0/users-guide/vcl-built-in-subs.html#vcl-backend-error
# This subroutine is called if we fail the backend fetch or if max_retries has been exceeded.
# A synthetic object is generated in VCL, whose body may be contructed using the synthetic() function.
#
# Allows us to show friendlier messages.
sub vcl_backend_error {
  # HTML for all
  set beresp.http.Content-Type = "text/html; charset=utf-8";

  # more specific error for those who need to report it
  if (beresp.status == 403) {
    synthetic(std.fileread("/etc/varnish/error-denied.html"));
  } else if (beresp.status == 404) {
    synthetic(std.fileread("/etc/varnish/error-notfound.html"));
  } else if (beresp.status >= 500 && beresp.status <= 599) {
    synthetic(std.fileread("/etc/varnish/error-server.html"));
  } else {
    synthetic(std.fileread("/etc/varnish/error-default.html"));
  }

  return (deliver);
}

# https://varnish-cache.org/docs/4.0/users-guide/vcl-built-in-subs.html#vcl-synth
# Called to deliver a synthetic object. A synthetic object is generated in VCL, not fetched from the backend. Its body may be contructed using the synthetic() function.
# A vcl_synth defined object never enters the cache, contrary to a vcl_backend_error defined object, which may end up in cache.
sub vcl_synth {
  if (req.http.X-Fulcrum-Save-Content-Type == "application/javascript") {
    set resp.http.Content-Type = "application/javascript";
    set resp.http.Cache-Control = "must-revalidate, no-cache, private";
    set resp.status = 200;

    # kludge to save the content type since JSONP always needs a 200
    set req.http.X-Fulcrum-Status = resp.status;

    synthetic( {"fulcrumStatus("} + req.http.X-Fulcrum-Status + {", '"} + req.http.X-Client-IP + {"');"} );
  } else {
    # HTML for all
    set resp.http.Content-Type = "text/html; charset=utf-8";

    # more specific error for those who need to report it
    if (resp.status == 403) {
      # do not let cloudflare cache
      set resp.http.Cache-Control = "must-revalidate, no-cache, private";

      synthetic(std.fileread("/etc/varnish/error-denied.html"));
    } else if (resp.status == 404) {
      synthetic(std.fileread("/etc/varnish/error-notfound.html"));
    } else if (resp.status >= 500 && resp.status <= 599) {
      synthetic(std.fileread("/etc/varnish/error-server.html"));
    } else {
      synthetic(std.fileread("/etc/varnish/error-default.html"));
    }
  }

  return (deliver);
}


sub vcl_backend_fetch {
    # https://www.getpagespeed.com/server-setup/varnish/varnish-brotli-done-right
    if(bereq.http.X-brotli == "true") {
        set bereq.http.Accept-Encoding = "br";
        unset bereq.http.X-brotli;
    }
}
