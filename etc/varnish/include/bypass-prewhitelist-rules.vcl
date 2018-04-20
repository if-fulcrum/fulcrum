# This file is run BEFORE determining if the client is whitelisted or the server is public
# See bypass-rules.vcl for rules after whitelisted IP check

# Pipe these paths directly to web server for streaming.
if (req.url ~ "^/admin/content/backup_migrate/export") {
  return (pipe);
}

# these should get to the webserver and not block by guru
if (req.url ~ "^/fulcrum/whitelist/") {
  return (pass);
}

# allow to check access via a ajax request
if (req.url == "/fulcrumwhitelistcheck") {
  set req.http.X-Fulcrum-Save-Content-Type = "application/javascript";

  if ( !std.ip(req.http.X-Client-IP, client.ip) ~ whitelist) {
    return (synth(403, "denied"));
  }

  return (synth(200, "ok"));
}
