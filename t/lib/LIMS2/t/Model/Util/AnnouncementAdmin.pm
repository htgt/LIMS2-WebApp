package LIMS2::t::Model::Util::AnnouncementAdmin;
use strict;
use warnings FATAL => 'all';

use base qw( Test::Class );
use Test::Most;
use LIMS2::Model::Util::AnnouncementAdmin;
use LIMS2::Test model => { classname => __PACKAGE__ };

## no critic

sub message_creation_and_deletion : Test {

	my $message = 'Testing message creation';
	my $created_date = '01/01/2015';
	my $expiry_date = '02/02/2016';
	my $priority = 'normal';
	my $wge = '0';
	my $htgt = '1';
	my $lims = '0';

  my $created_message = create_message( $c->model('Golgi')->schema, {
            message         => $message,
            expiry_date     => $expiry_date,
            created_date    => $created_date,
            priority        => $priority,
            wge             => $wge,
            htgt            => $htgt,
            lims            => $lims,
        }
    );

  is ( $created_message->message, 'Testing message creation', 'message' );
  is ( $created_message->expiry_date, '02/02/2016', 'expiry_date');
  is ( $created_message->created_date, '01/01/2015', 'created_date');
  is ( $created_message->priority, 'normal', 'priority');
  is ( $created_message->wge, '0', 'wge');
  is ( $created_message->htgt, '1', 'htgt');
  is ( $created_message->lims, '0', 'lims');

  my $listed_message = list_messages( $c->model('Golgi')->schema );

  is ( $listed_message->message, 'Testing message creation', 'message' );
  is ( $listed_message->expiry_date, '02/02/2016', 'expiry_date');
  is ( $listed_message->created_date, '01/01/2015', 'created_date');
  is ( $listed_message->priority, 'normal', 'priority');
  is ( $listed_message->wge, '0', 'wge');
  is ( $listed_message->htgt, '1', 'htgt');
  is ( $listed_message->lims, '0', 'lims');



}

sub list_priority : Test(3) {

  my $priorities = list_priority( $c->model('Golgi')->schema );

  is( $priorities[0], 'high', 'high' );
  is( $priorities[1], 'normal', 'normal' );
  is( $priorities[2], 'low', 'low' );

}