# put in logic to have conditions that will bypass varnish
# if cookie found starting with examplecookie_a and domain name is example.com, bypass varnish
if (req.http.Cookie ~ "examplecookie_[a-z]+") {
  if ( req.http.host ~ "example.com" ) {
    return (pass);
  }
}
