
CREATE or replace FUNCTION city(in_addr inet, in_path text, in_lang text) RETURNS city
    LANGUAGE plperlu
    AS $_$
use MaxMind::DB::Reader;
use strict;
use warnings;

my ($ip, $path, $lang) = @_;

my $db = MaxMind::DB::Reader->new( file => "${path}/GeoIP2-City.mmdb");
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

