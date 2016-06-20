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


sub message_creation : Tests {
  use Smart::Comments;

  ok my $priority =  model->schema->resultset('Priority')->create( {id => 'normal'} );

  my $priority_list = list_priority( model->schema );

  my $deref_priority_list = shift @{$priority_list};

  my $deref_priority_list_hash = $deref_priority_list->as_hash;
  my $test = $deref_priority_list_hash->{id};



  ### $test
  ## $deref_list_id

  is( $deref_priority_list_hash->{id}, 'normal', "list_priority works");

  my $announcement_params = {
    message         => 'This is a message',
    expiry_date     => '01/01/2099',
    created_date    => '01/01/2000',
    priority        => 'normal',
    wge             => '0',
    htgt            => '1',
    lims            => '0',
  };

  ok my $announcement = create_message( model->schema, $announcement_params );

  my $message_list = list_messages( model->schema );

  is( @{$message_list}, @{$announcement}, "list_messages works");

  my $deref_message_list = shift @{$message_list};
  my $deref_message_list_hash = $deref_message_list->as_hash;
  my $delete_message_id = $deref_message_list_hash->{id};

  delete_message( model->schema, { message_id => $delete_message_id } );

  $message_list = list_messages( model->schema );

  is( @{$message_list}, '0', "delete_message works");

}

## use critic

1;

__END__


