# Note this is in an external include file in case we want need to debug

# Remove ban-lurker friendly custom headers when delivering to client.
unset resp.http.X-Url;
unset resp.http.X-Host;

# Comment these for easier Drupal cache tag debugging in development.
unset resp.http.Cache-Tags;
unset resp.http.X-Drupal-Cache-Contexts;
