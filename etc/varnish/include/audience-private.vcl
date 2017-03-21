# This file controls who has access to the front end of the website.
# If empty, it will not answer to public calls, if 0.0.0.0/0 then it will be public.
# whitelist.vcl allows access to both the frontend and /user (admin) area.
# whitelist.vcl is currently managed by consul.
# This means dev/test should typically be empty and prd be 0.0.0.0/0

acl audience { }
