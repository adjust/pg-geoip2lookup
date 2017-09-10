Geoip2Lookup for PostgreSQL
Version 0.0.1

Geoip2Lookup is a PL/Perl-based extension for connecting to MaxMind's 
mmdb files and running queries for things like geolocation.  Current versions
allow you to look up data from any MMDB file and get a JSONB object back,
as well as to look up records from city, country, anonymous ip, ISP, and
connection-type databases and get rows back.

The extension configures itself in the geoip2lookup schema.  You can call the
base functions by providing a path (and for city and country functions a
language) or by using the wrappers and configuring the extension appropriately.

BUILDING AND INSTALLING THE EXTENSION

CONFIGURING

To configure use something like:

SET geoip2lookup.path = '/var/lib/GeoIP/' -- or wherever the mmdbs are
ALTER SYSTEM SET geoip2lookup.path TO CURRENT;

Then reload PostgreSQL.

Also you can set the language used for city/country lookups as:

SET geoip2lookup.language = 'en';
ALTER SYSTEM SET geoip2lookup.language to 'en';

Languages are case sensitive for performance reasons.  The extension sets
the default language to 'en' does not set a default path.

PERFORMANCE

On a gentoo vm on my macbook, I am able to query a million rows in about 3
minutes.  Performance on a server is expected to be a bit better.  This module
is not currently optimized for bulk lookups.  That may come later.

FUTURE WORK

In the future I expect to allow a full scan of an mmdb file by walking the
search tree.   This would also allow materialized views to be built against
binary mmdbs.
