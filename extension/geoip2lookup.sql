
-- types

CREATE TYPE city AS (
	ip_addr inet,
	city_name text,
	city_geo_id int,
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
);

CREATE TYPE isp AS (
	ip_addr inet,
	isp text,
	organization text,
	autononous_system_number text,
	autonomous_system_organization text
);

CREATE TYPE country AS (
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
);

CREATE TYPE anonymous_ip AS (
	ip_addr inet,
	is_anonymous bool,
	is_tor_exit_node bool,
	is_hosting_provider bool,
	is_anonymous_vpn bool,
	is_public_proxy bool
);

CREATE TYPE connection_type AS (
	ip_addr inet,
	connection_type text
);

-- raw function

CREATE FUNCTION raw_geoip2_json(in_ipaddr inet, in_db text, in_path text) returns jsonb
language plperlu as $_$
use JSON;
use MaxMind::DB::Reader;
use strict;
use warnings;

my ($ip, $dbname, $path) = @_;

my $db = MaxMind::DB::Reader->new( file => "${path}/GeoIP2-${dbname}.mmdb");
return JSON::to_json($db->record_for_address($ip) // {});
$_$;

CREATE FUNCTION raw_geoip2_json(in_ipaddr inet, in_db text) returns jsonb
language sql as
$$
select raw_geoip2_json($1, $2, pg_current_setting('geoip2lookup.path'));
$$ SET search_path FROM CURRENT;

-- tuple functions


CREATE FUNCTION isp(in_addr inet, in_path text)
RETURNS isp LANGUAGE PLPERLU
AS $_$
use MaxMind::DB::Reader;
use strict;
use warnings;

my ($ip, $path) = @_;

my $db = MaxMind::DB::Reader->new( file => "${path}/GeoIP2-ISP.mmdb");
my $record = $db->record_for_address($ip);
return {
    ip_addr => $ip,
    isp => $record->{isp},
    organization => $record->{organization},
    autononous_system_number => $record->{autonomous_system_number},
    autonomous_system_organization => $record->{autonomous_system_organization} };
$_$;

CREATE FUNCTION isp(in_addr inet) RETURNS isp LANGUAGE SQL AS
$$ SELECT isp($1, pg_current_setting('geoip2lookup.path')); $$ SET search_path FROM CURRENT;

CREATE FUNCTION connection_type(in_addr inet, in_path text) 
RETURNS connection_type
language plperlu as $_$
use MaxMind::DB::Reader;
use strict;
use warnings;

my ($ip, $path) = @_;

my $db = MaxMind::DB::Reader->new( file => "${path}/GeoIP2-Connection-Type.mmdb");
my $record = $db->record_for_address($ip);
return {
    ip_addr => $ip,
    connection_type => $record->{connection_type},
    };
$_$;

CREATE FUNCTION connection_type(in_addr inet) RETURNS connection_type 
LANGUAGE SQL AS
$$ SELECT connection_type($1, pg_current_setting('geoip2lookup.path')); $$ SET search_path FROM CURRENT;

CREATE FUNCTION anonymous_ip(in_addr inet in_path text) RETURNS anonymous_ip
    LANGUAGE plperlu
    AS $_$
use MaxMind::DB::Reader;
use strict;
use warnings;

my ($ip, $path) = @_;

my $db = MaxMind::DB::Reader->new( file => "${path}/GeoIP2-Anonymous-IP.mmdb");
my $record = $db->record_for_address($ip);
return {
    ip_addr => $ip,
    is_anonymous => ($record->{is_anonymous} // '0'),
    is_anonymous_vpn => ($record->{is_anonymous_vpn} // '0'),
    is_hosting_provider => ($record->{is_hosting_provider} // '0'),
    is_public_proxy => ($record->{is_public_proxy} // '0'),
    is_tor_exit_node => ($record->{is_tor_exit_node} // '0'), };
$_$;

CREATE FUNCTION anonymous_id(in_addr inet) RETURNS anonymous_ip 
LANGUAGE SQL AS
$$ SELECT anonymous_ip($1, pg_current_setting('geoip2lookup.path')); $$ SET search_path FROM CURRENT;


CREATE FUNCTION city(in_addr inet, in_path text, in_lang text) RETURNS city
    LANGUAGE plperlu
    AS $_$
use MaxMind::DB::Reader;
use strict;
use warnings;

my ($ip, $path, $lang) = @_;

my $db = MaxMind::DB::Reader->new( file => '${path}/GeoIP2-City.mmdb');
my $record = $db->record_for_address($ip);
return {
    ip_addr => $ip,
    city_name => $record->{city}->{names}->{$lang},
    city_geo_id => $record->{city}->{geoname_id},
    postal_code => $record->{postal}->{code},
    country_name => $record->{country}->{names}->{$lang}, 
    country_iso_code => $record->{country}->{iso_code},
    country_geo_id => $record->{country}->{geoname_id},
    subdivision_names => [map { $_->{names}->{$lang} }  @{$record->{subdivisions}}],
    subdivision_geo_ids => [map { $_->{geoname_id} }  @{$record->{subdivisions}}],
    continent_name => $record->{continent}->{names}->{$lang},
    continent_code => $record->{continent}->{code},
    continent_geo_id => $record->{continent}->{geoname_id},
    registered_country_name => $record->{registered_country}->{names}->{$lang}, 
    registered_country_iso_code => $record->{registered_country}->{iso_code}, 
    registered_country_geo_id => $record->{registered_country}->{geoname_id}, };
$_$;

CREATE FUNCTION city(in_addr inet) RETURNS city
LANGUAGE SQL AS
$$ SELECT city($1, pg_current_setting('geoip2lookup.path'), pg_current_setting('geoip2lookup.language')); $$ SET search_path FROM CURRENT;


CREATE FUNCTION country(in_addr inet, in_path text, in_lang text) 
RETURNS country
    LANGUAGE plperlu
    AS $_$
use MaxMind::DB::Reader;
use strict;
use warnings;

my ($ip, $path, $lang) = @_;

my $db = MaxMind::DB::Reader->new( file => "${path}/GeoIP2-Country.mmdb");
my $record = $db->record_for_address($ip);
return {
    ip_addr => $ip,
    name => $record->{country}->{names}->{$lang}, 
    iso_code => $record->{country}->{iso_code},
    geo_id => $record->{country}->{geoname_id},
    continent_name => $record->{continent}->{names}->{$lang},
    continent_code => $record->{continent}->{code},
    continent_geo_id => $record->{continent}->{geoname_id},
    registered_country_name => $record->{registered_country}->{names}->{$lang}, 
    registered_country_iso_code => $record->{registered_country}->{iso_code}, 
    registered_country_geo_id => $record->{registered_country}->{geoname_id}, };
$_$;

CREATE FUNCTION country(in_addr inet) RETURNS country
LANGUAGE SQL AS
$$ SELECT country($1, pg_current_setting('geoip2lookup.path'), pg_current_setting('geoip2lookup.language')); $$ SET search_path FROM CURRENT;



-- forthcoming, full scans
