package LIMS2::t::Model::Util::ImportSequencing;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::Util::ImportSequencing qw( backup_data );
use Path::Class;
use LIMS2::Test model => { classname => __PACKAGE__ };
use File::Temp ':seekable';

use strict;
## no critic

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
};

all_tests  : Test(3)
{
    note( "Plate Create - merge plate process data" );
    my $project_name =  "test_seq";
    my $test_dir = dir($ENV{LIMS2_TEMP},$project_name);
    use_ok('LIMS2::Model::Util::ImportSequencing', qw( backup_data ) );

    ok backup_data( $test_dir, $project_name );

}


1;

__END__

