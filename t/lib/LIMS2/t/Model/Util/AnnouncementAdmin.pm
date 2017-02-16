package LIMS2::t::Model::Util::AnnouncementAdmin;
use strict;
use warnings FATAL => 'all';

use base qw( Test::Class );
use Test::Most;
use LIMS2::Model::Util::AnnouncementAdmin qw( create_message list_messages delete_message list_priority );
use LIMS2::Test model => { classname => __PACKAGE__ };

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $DEBUG );
};

## no critic

=head1 NAME

LIMS2/t/Model/Util/AnnouncementAdmin.pm - test class for LIMS2::Model::Util::AnnouncementAdmin

=cut


sub message_creation_and_deletion : Test(9) {

  can_ok(__PACKAGE__, 'create_message');
  can_ok(__PACKAGE__, 'delete_message');
  can_ok(__PACKAGE__, 'list_priority');
  can_ok(__PACKAGE__, 'list_messages');

  my $priority_list = list_priority( model );
  my $priority_item = shift @{$priority_list};

  is( $priority_item->id, 'high', "list_priority works");

  my $announcement_params = {
    message         => 'This is a message',
    expiry_date     => '01-01-2099',
    created_date    => '01-01-2000',
    priority        => 'normal',
    wge             => '0',
    htgt            => '1',
    lims            => '0',
  };

  ok my $announcement = create_message( model, $announcement_params );

  my $message_list = list_messages( model );

  is( @{$message_list}, @{$announcement}, "list_messages works");

  my $message_item = shift @{$message_list};
  my $message_item_id = $message_item->id;

  delete_message( model, { message_id => $message_item_id } );

  $message_list = list_messages( model );

  is( @{$message_list}, '0', "delete_message works");

}

## use critic

1;

__END__


