# this is to fix proxies that put private/non-routable ips in the header
# removes all non routable public ips
set req.http.X-Forwarded-For = regsuball(req.http.X-Forwarded-For, "(127\.0\.0\.1|10\.\d{1,3}\.\d{1,3}\.\d{1,3}|172\.1[6-9]\.\d{1,3}\.\d{1,3}|172\.2[0-9]\.\d{1,3}\.\d{1,3}|172\.3[0-1]\.\d{1,3}\.\d{1,3}|192\.168\.\d{1,3}\.\d{1,3})([, ]+)?", "");

# remove trailing commas/spaces
set req.http.X-Forwarded-For = regsub(req.http.X-Forwarded-For, "[, ]+$", "");
