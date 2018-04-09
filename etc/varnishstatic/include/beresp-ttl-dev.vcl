# We need this to cache 404s, 301s, 500s. Otherwise, depending on backend but
# definitely in Drupal's case these responses are not cacheable by default.
if (beresp.status == 404 || beresp.status == 301 || beresp.status == 302 || beresp.status == 500) {
    set beresp.ttl = 1s;
    set beresp.http.X-ISDEV = true;
}
