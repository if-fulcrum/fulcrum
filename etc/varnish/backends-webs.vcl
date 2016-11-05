backend web01 {
  .host = "nginx";
}

# Define the director that determines how to distribute incoming requests.
sub vcl_init {
  new web = directors.round_robin();
  web.add_backend(web01);
}
