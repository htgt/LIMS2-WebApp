package LIMS2::t::Model::Util::AnnouncementAdmin;
use strict;
use warnings FATAL => 'all';

use base qw( Test::Class );
use Test::Most;
use LIMS2::Model::Util::AnnouncementAdmin;
use LIMS2::Test model => { classname => __PACKAGE__ };

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
};

## no critic

=head1 NAME

LIMS2/t/Model/Util/AnnouncementAdmin.pm - test class for LIMS2::Model::Util::AnnouncementAdmin

=cut


sub message_creation : Test {


  my $mech = LIMS2::Test::mech();

  {
  note( "No message set" );
  $mech->get_ok( '/admin/announcements/create_announcement' );
  $mech->title_is('LIMS2 - Create Announcement');
  ok my $res = $mech->submit_form(
      form_id => 'create_announcement_form',
      fields  => {
            expiry_date   => '01/01/2099',
            priority      => 'normal',
            wge           => '0',
            htgt          => '1',
            lims          => '0',
      },
      button  => 'create_announcement_button'
  ), 'submit form without message';

  ok $res->is_success, '...response is_success';
  is $res->base->path, '/admin/announcements/create_announcement', '... stays on same page';
  like $res->content, qr/Please fill in this field/, '...throws error saying no message specified';
  }

  {
  note( "No expiry_date set" );
  $mech->get_ok( '/admin/announcements/create_announcement' );
  $mech->title_is('LIMS2 - Create Announcement');
  ok my $res = $mech->submit_form(
      form_id => 'create_announcement_form',
      fields  => {
            message       => 'This is a message',
            priority      => 'normal',
            wge           => '0',
            htgt          => '1',
            lims          => '0',
      },
      button  => 'create_announcement_button'
  ), 'submit form without message';

  ok $res->is_success, '...response is_success';
  is $res->base->path, '/admin/announcements/create_announcement', '... stays on same page';
  like $res->content, qr/Please fill in this field/, '...throws error saying no expiry_date specified';
  }

  {
  note( "incorrect expiry_date set - year" );
  $mech->get_ok( '/admin/announcements/create_announcement' );
  $mech->title_is('LIMS2 - Create Announcement');
  ok my $res = $mech->submit_form(
      form_id => 'create_announcement_form',
      fields  => {
            message       => 'This is a message'
            expiry_date   => '01/01/1099',
            priority      => 'normal',
            wge           => '0',
            htgt          => '1',
            lims          => '0',
      },
      button  => 'create_announcement_button'
  ), 'submit form without message';

  ok $res->is_success, '...response is_success';
  is $res->base->path, '/admin/announcements/create_announcement', '... stays on same page';
  like $res->content, qr/Please enter a valid 4 digit year between  and 2100/, '...throws error saying wrong expiry_date specified';
  }

  {
  note( "incorrect expiry_date set - month" );
  $mech->get_ok( '/admin/announcements/create_announcement' );
  $mech->title_is('LIMS2 - Create Announcement');
  ok my $res = $mech->submit_form(
      form_id => 'create_announcement_form',
      fields  => {
            message       => 'This is a message'
            expiry_date   => '01/13/2099',
            priority      => 'normal',
            wge           => '0',
            htgt          => '1',
            lims          => '0',
      },
      button  => 'create_announcement_button'
  ), 'submit form without message';

  ok $res->is_success, '...response is_success';
  is $res->base->path, '/admin/announcements/create_announcement', '... stays on same page';
  like $res->content, qr/Please enter a valid month/, '...throws error saying wrong expiry_date specified';
  }

  {
  note( "incorrect expiry_date set - day" );
  $mech->get_ok( '/admin/announcements/create_announcement' );
  $mech->title_is('LIMS2 - Create Announcement');
  ok my $res = $mech->submit_form(
      form_id => 'create_announcement_form',
      fields  => {
            message       => 'This is a message'
            expiry_date   => '35/01/2099',
            priority      => 'normal',
            wge           => '0',
            htgt          => '1',
            lims          => '0',
      },
      button  => 'create_announcement_button'
  ), 'submit form without message';

  ok $res->is_success, '...response is_success';
  is $res->base->path, '/admin/announcements/create_announcement', '... stays on same page';
  like $res->content, qr/Please enter a valid day/, '...throws error saying wrong expiry_date specified';
  }

  {
  note( "incorrect expiry_date set - text" );
  $mech->get_ok( '/admin/announcements/create_announcement' );
  $mech->title_is('LIMS2 - Create Announcement');
  ok my $res = $mech->submit_form(
      form_id => 'create_announcement_form',
      fields  => {
            message       => 'This is a message'
            expiry_date   => 'tomorrow',
            priority      => 'normal',
            wge           => '0',
            htgt          => '1',
            lims          => '0',
      },
      button  => 'create_announcement_button'
  ), 'submit form without message';

  ok $res->is_success, '...response is_success';
  is $res->base->path, '/admin/announcements/create_announcement', '... stays on same page';
  like $res->content, qr(The date format should be : dd/mm/yyyy), '...throws error saying wrong expiry_date specified';
  }

  {
  note( "no priority set" );
  $mech->get_ok( '/admin/announcements/create_announcement' );
  $mech->title_is('LIMS2 - Create Announcement');
  ok my $res = $mech->submit_form(
      form_id => 'create_announcement_form',
      fields  => {
            message       => 'This is a message'
            expiry_date   => '01/01/2099',
            wge           => '0',
            htgt          => '1',
            lims          => '0',
      },
      button  => 'create_announcement_button'
  ), 'submit form without message';

  ok $res->is_success, '...response is_success';
  is $res->base->path, '/admin/announcements/create_announcement', '... stays on same page';
  like $res->content, qr(Please fill in this field), '...throws error asking user to specify priority';
  }

  {
  note( "no webapp specified" );
  $mech->get_ok( '/admin/announcements/create_announcement' );
  $mech->title_is('LIMS2 - Create Announcement');
  ok my $res = $mech->submit_form(
      form_id => 'create_announcement_form',
      fields  => {
            message       => 'This is a message'
            expiry_date   => '01/01/2099',
            priority      => 'normal',
            wge           => '0',
            htgt          => '0',
            lims          => '0',
      },
      button  => 'create_announcement_button'
  ), 'submit form without message';

  ok $res->is_success, '...response is_success';
  is $res->base->path, '/admin/announcements/create_announcement', '... stays on same page';
  like $res->content, qr(Please specify a system for the announcement), '...throws error saying wrong expiry_date specified';
  }

  {
  note( "no webapp specified" );
  $mech->get_ok( '/admin/announcements/create_announcement' );
  $mech->title_is('LIMS2 - Create Announcement');
  ok my $res = $mech->submit_form(
      form_id => 'create_announcement_form',
      fields  => {
            message       => 'This is a message'
            expiry_date   => '01/01/2099',
            priority      => 'normal',
            wge           => '0',
            htgt          => '1',
            lims          => '0',
      },
      button  => 'create_announcement_button'
  ), 'submit form without message';

  ok $res->is_success, '...response is_success';
  is $res->base->path, '/admin/announcements', '... redirects to announcements page';
  like $res->content, qr(Message sucessfully created), '... message creation was sucessful';
  }

}

#todo, list priority, list messages and delete messages

# sub list_priority : Test(3) {

#   my @priorities = list_priority( model->schema );

#   is( $priorities[0], 'high', 'high' );
#   is( $priorities[1], 'normal', 'normal' );
#   is( $priorities[2], 'low', 'low' );

#}

## use critic

1;

__END__


