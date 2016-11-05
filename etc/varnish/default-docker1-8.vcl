vcl 4.0;

import std;
import directors;

include "internal.vcl";
include "whitelist.vcl";

include "backends-webs-docker1-8.vcl";

# Respond to incoming requests.
sub vcl_recv {
  set req.backend_hint = web.backend();

  # save the left most IP for whitelisting
  set req.http.X-Client-IP = regsub(req.http.X-Forwarded-For, "[, ].*$", "");

  # Use anonymous, cached pages if all backends are down.
  if (!std.healthy(req.backend_hint)) {
    unset req.http.Cookie;
  }

  # Allow the backend to serve up stale content if it is responding slowly.
  #
  # This is now handled in vcl_hit.
  #
  # set req.grace = 6h;

  # Do not cache these paths.
  if (req.url ~ "^/(status|update)\.php$" ||
      req.url ~ "^/(admin/build/features|info/|flag/)" ||
      req.url ~ "^.*/(ajax|ahah)/") {
       return (pass);
  }

# This is for the Varnish 3, not needed after Varnish 4 beresp.uncacheable
#  # large file kludge (see vcl_backend_response section)
#  if (req.http.x-pipe && req.restarts > 0) {
#    unset req.http.x-pipe;
#    return (pipe);
#  }

  # Pipe these paths directly to web server for streaming.
  if (req.url ~ "^/admin/content/backup_migrate/export") {
    return (pipe);
  }

  # for dev/test, only allow users in whitelist any kind of access
  # for dev/test behind cloudflare, the main acl should be at CF, as dev/test would be open to CF ips
  # for prod systems, port 80 should be open world, thus the internal ips from the elb should address this
  # TODO: what about haproxy terminiation and pass to varnish (443 -> 80 internal), should haproxy have its own acl?
  if ( client.ip !~ internal && client.ip !~ whitelist ) {
    return (synth(403, "Access Denied."));
  }

  # Squash malicious bot requests
  # Do not allow outside access to certain php or txt files
  # Block user login and node add external
  if (req.url ~ "^/((wordpress|wp|old)/wp-admin/?|wp-login.php)$" ||
      ( !std.ip(req.http.X-Client-IP, client.ip) ~ internal &&
        !std.ip(req.http.X-Client-IP, client.ip) ~ whitelist &&
        ( req.url ~ "^/((apc|authorize|cron|install|phptest|status|update)\.php|[A-Z]{6,11}[a-z\.]*\.txt)$" ||
          req.url ~ "(?i)^/((index.php)?\?q=)?(admin.*|user.*|node/add)")
  )) {
    return (synth(403, "Access Denied."));
  }

  # Handle compression correctly. Different browsers send different
  # "Accept-Encoding" headers, even though they mostly all support the same
  # compression mechanisms. By consolidating these compression headers into
  # a consistent format, we can reduce the size of the cache and get more hits.=
  # @see: http:// varnish.projects.linpro.no/wiki/FAQ/Compression
  if (req.http.Accept-Encoding) {
    if (req.http.Accept-Encoding ~ "gzip") {
      # If the browser supports it, we'll use gzip.
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
  if (req.url ~ "(?i)\.(png|gif|jpe?g|ico|swf|css|js|html?|ttf)(\?[a-z0-9_=\?&\.-]+)?$") {
    unset req.http.Cookie;
  }

  # Remove all cookies that Drupal doesn't need to know about. ANY remaining
  # cookie will cause the request to pass-through to web server. For the most part
  # we always set the NO_CACHE cookie after any POST request, disabling the
  # Varnish cache temporarily. The session cookie allows all authenticated users
  # to pass through as long as they're logged in.
  if (req.http.Cookie) {
    # 1. Append a semi-colon to the front of the cookie string.
    # 2. Remove all spaces that appear after semi-colons.
    # 3. Match the cookies we want to keep, adding the space we removed
    #    previously back. (\1) is first matching group in the regsuball.
    # 4. Remove all other cookies, identifying them by the fact that they have
    #    no space after the preceding semi-colon.
    # 5. Remove all spaces and semi-colons from the beginning and end of the
    #    cookie string.
    set req.http.Cookie = ";" + req.http.Cookie;
    set req.http.Cookie = regsuball(req.http.Cookie, "; +", ";");
    set req.http.Cookie = regsuball(req.http.Cookie, ";(SESS[a-z0-9]+|SSESS[a-z0-9]+|NO_CACHE)=", "; \1=");
    set req.http.Cookie = regsuball(req.http.Cookie, ";[^ ][^;]*", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "^[; ]+|[; ]+$", "");

    if (req.http.Cookie == "") {
      # If there are no remaining cookies, remove the cookie header. If there
      # aren't any cookie headers, Varnish's default behavior will be to cache
      # the page.
      unset req.http.Cookie;
    } else {
      # If there is any cookies left (a session or NO_CACHE cookie), do not
      # cache the page. Pass it on to web server directly.
      return (pass);
    }
  }
}

# Set a header to track a cache HIT/MISS.
sub vcl_deliver {
  set resp.http.Via = "1.1 varnish";

  if (obj.hits > 0) {
    set resp.http.X-Varnish-Cache = "HIT";
  } else {
    set resp.http.X-Varnish-Cache = "MISS";
  }
}

# Routine used to determine the cache key if storing/retrieving a cached page.
sub vcl_hash {

  # hash data based on the domain (host) as to not have conflicts on foo.com/contact & bar.com/contact
  # also seperate based on http vs httpS else http will not redirect if its already in the cache
  # https://bensmann.no/seperate-varnish-caching-http-https/
  if (req.http.host && req.http.X-Forwarded-Proto ~ "https") {
      hash_data(req.http.X-Forwarded-Proto);
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

  return (lookup);
}

# Code determining what to do when serving items from the web servers.
# beresp == Back-end response from the web server.
sub vcl_backend_response {
  # We need this to cache 404s, 301s, 500s. Otherwise, depending on backend but
  # definitely in Drupal's case these responses are not cacheable by default.
  if (beresp.status == 404 || beresp.status == 301 || beresp.status == 500) {
#    set beresp.ttl = 10m;
    set beresp.ttl = 1s;
  }

  # large file kludge: dont cache files > 1mb
  # https://gist.github.com/mcphersoncreative/7469629
  if (beresp.http.Content-Length ~ "[0-9]{7,}" ) {
    set beresp.uncacheable = true;
    return (deliver);
  }

  # Don't allow static files to set cookies.
  # This list of extensions appears twice, once here and again in vcl_recv so
  # make sure you edit both and keep them equal.
  if (bereq.url ~ "(?i)\.(png|gif|jpe?g|ico|swf|css|js|html?|ttf)(\?[a-z0-9_=\?&\.-]+)?$") {
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
}

# In the event of an error, show friendlier messages.
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
