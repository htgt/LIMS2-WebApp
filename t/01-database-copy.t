#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

BEGIN { 
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
}   


use strict;
use warnings FATAL => 'all';

use Test::Most;
use Data::Dumper;

use LIMS2::DBUtils::Databases;

use_ok 'LIMS2::Model::DBConnect';

ok my $config = LIMS2::Model::DBConnect->read_config, 'parse config file';
#print STDERR Data::Dumper->Dump([\$config], [qw(config)]);

# Compiles
use_ok 'LIMS2::DBUtils::Databases';

# Dies under the right circumstances
#dies_ok { LIMS2::DBUtils::Databases->new(source_db => '', destination_db => 'yes', source_role => 'yes', destination_role => 'yes') } 'no source db';
#dies_ok { LIMS2::DBUtils::Databases->new(source_db => 'yes', destination_db => '', source_role => 'yes', destination_role => 'yes') } 'no destination db';
#dies_ok { LIMS2::DBUtils::Databases->new(source_db => 'yes', destination_db => 'yes', source_role => '', destination_role => 'yes') } 'no source roleb';
#dies_ok { LIMS2::DBUtils::Databases->new(source_db => 'yes', destination_db => 'yes', source_role => 'yes', destination_role => '') } 'no destination role';
#lives_ok { LIMS2::DBUtils::Databases->new(source_db => 'yes', destination_db => 'yes', source_role => 'yes', destination_role => 'yes') } 'expecting to live';

my $obj = LIMS2::DBUtils::Databases->new(source_db => 'LIMS2_LIVE', destination_db => 'LIMS2_DEVEL_UNITTEST', source_role => 'lims2_live_admin', destination_role => 'lims2');
is($obj->clone_database(overwrite => 1, with_data => 1, no_source_role => 0), 1, 'cloning database');

done_testing;

