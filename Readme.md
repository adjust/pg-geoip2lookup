Geoip2Lookup for PostgreSQL
===========================
Version 0.0.1

Geoip2Lookup is a PL/Perl-based extension for connecting to MaxMind's 
mmdb files and running queries for things like geolocation.  Current versions
allow you to look up data from any MMDB file and get a JSONB object back,
as well as to look up records from city, country, anonymous ip, ISP, and
connection-type databases and get rows back.

The extension configures itself in the geoip2lookup schema.  You can call the
base functions by providing a path (and for city and country functions a
language) or by using the wrappers and configuring the extension appropriately.

0.0.x versions of this extension are considered usable (and manually tested) but
yet subject to automated regression testing, as this requires creating our own
mmdbs with the same format as MaxMind's.

BUILDING AND INSTALLING THE EXTENSION
=====================================
    make install

Then in any database you want to use it in:

    create extesnion geoip2lookup;

Set your path to the mmdb files as below.  Away you go.

CONFIGURING
============

To configure use something like:

    SET geoip2lookup.path = '/var/lib/GeoIP/' -- or wherever the mmdbs are
    ALTER SYSTEM SET geoip2lookup.path TO CURRENT;

Then reload PostgreSQL.

Also you can set the language used for city/country lookups as:

    SET geoip2lookup.language = 'en';
    ALTER SYSTEM SET geoip2lookup.language to 'en';

Languages are case sensitive for performance reasons.  The extension sets
the default language to 'en' does not set a default path.

API REFERENCE
==============

ALL APIS come with multiple, overloaded forms.  There is a convenience form that
just takes an IP address as input and uses configured directories, etc. and there
is a low-level 203 argument form. In the long argument form the second argument
is always the path to the MMDB and the third, if it exists, is always the language
for localization of names.  An exception is made for raw json lookups because there
we have to specify the database as well.

All functions and types are found in the geoip2lookup schema.

    raw_geoip2_json($ip, $db),
    raw_geoip2_json($ip, $db, $path);

returns a json dump of the record found.

Tuple-returning functions always include an ip_addr function which echoes back in
the first argument passed.  This is in order to simplify storage and joins.

The return types are the same as the IP addresses.   Also names are localized by
requested language and geoname_ids are represented geo_id

Anonymous IP
-------------

    anonymous_ip(inet)
    anonymous_ip(inet, path)

Fields returned:

    ip_addr inet,
    is_anonymous bool,
    is_tor_exit_node bool,
    is_hosting_provider bool,
    is_anonymous_vpn bool,
    is_public_proxy bool

Balues are all returned as true or false.

City
-----

    city(inet)
    city(inet, path, language)

Fields Returned:

    ip_addr inet,
    city_name text,
    city_geo_id int.
    postal_code text,
    country_name text,
    country_iso_code text,
    country_geo_id int,
    subdivision_names text[],
    subdivision_geo_ids int[],
    continent_name text,
    continent_code text,
    continent_geo_id int,
    registered_country_name text,
    registered_country_iso_code text,
    registered_country_geo_id int 

Connection Type
---------------

    connection_type(inet)
    connection_type(inet, path)

Fields Returned

   ip_addr inet,
   connection_type text

Country
-------

    country(inet)
    country(inet, path, language)

Fields returned

    ip_addr inet,
    name text,
    iso_code text,
    geo_id int,
    continent_name text,
    continent_code text,
    continent_geo_id int,
    registered_country_name text,
    registered_country_iso_code text,
    registered_country_geo_id int 


ISP
----

    isp(inet)
    isp(inet, path)

fields returned"

    ip_addr inet.
    isp text,
    autonomous_system_number text,
    autonomous_system_organization text

PERFORMANCE
============

On a gentoo vm on my macbook, I am able to query a million rows in about 3
minutes.  Performance on a server is expected to be a bit better.  This module
is not currently optimized for bulk lookups.  That may come later.

Also we expect to get test scripts and better documentation. 

FUTURE WORK
============

In the future I expect to allow a full scan of an mmdb file by walking the
search tree.   This would also allow materialized views to be built against
binary mmdbs. ASN databases will be supported at some point (patches welcome).
