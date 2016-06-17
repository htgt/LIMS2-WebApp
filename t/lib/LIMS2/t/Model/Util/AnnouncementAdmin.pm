package LIMS2::t::Model::Util::AnnouncementAdmin;
use strict;
use warnings FATAL => 'all';

use base qw( Test::Class );
use Test::Most;
use LIMS2::Model::Util::AnnouncementAdmin;
use LIMS2::Test model => { classname => __PACKAGE__ };

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $DEBUG );
};

## no critic

=head1 NAME

LIMS2/t/Model/Util/AnnouncementAdmin.pm - test class for LIMS2::Model::Util::AnnouncementAdmin

=cut


sub message_creation : Test {

  my $priority = model->schema->resultset('Priority')->create( id => 'normal' );

  my $announcement_params = {
    message         => 'This is a message',
    expiry_date     => '01/01/2099',
    created_date    => DateTime->now(time_zone=>'local'),
    priority        => 'normal',
    wge             => '0',
    htgt            => '1',
    lims            => '0',
  };

  ok my $announcement = create_message( model->schema, $announcement_params );




}

## use critic

1;

__END__


