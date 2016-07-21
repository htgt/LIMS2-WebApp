package LIMS2::Model::Util::AnnouncementAdmin;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::AnnouncementAdmin::VERSION = '0.412';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [
        qw(
            delete_message
            create_message
            list_messages
            list_priority
          )
    ]
};

=head2 delete_message

Deletes announcement messages from the messages table by message id.

=cut
sub delete_message {
    my ( $schema, $params ) = @_;
    my $message_id = $params->{message_id}
      or die "No message_id provided to delete_message";

    #create result variable and then use delete method to delete row

    my $priority = $schema->resultset('Message')->search({
        'me.id'  => [ $message_id ],
      },
      {
        order_by    => { -desc => 'me.expiry_date'},
      }
    );

    $priority->delete;

  return;
}

=head2 create_message

Creates announcement messages in the messages table.

=cut
sub create_message {
    my ( $schema, $params ) = @_;

    my @message = $schema->resultset('Message')->create(
        {
            message         => $params->{message},
            expiry_date     => $params->{expiry_date},
            created_date    => $params->{created_date},
            priority        => $params->{priority},
            wge             => $params->{wge},
            htgt            => $params->{htgt},
            lims            => $params->{lims},
        }
    );

    return \@message;

}

=head2 list_messages

Retrieves announcement messages from the messages table, longest expiry date top.

=cut
sub list_messages {
    my ($schema) = @_;

    my @messages = $schema->resultset('Message')->search(
        {},
        {
            order_by    => { -desc => 'me.expiry_date'},
        }
    );

    return \@messages;
}

=head2 list_priority

Priority options.

=cut
sub list_priority {
    my ($schema) = @_;

    my @priority = $schema->resultset('Priority')->search({},
    {
        order_by    => { -asc => 'me.id'},
    });

    return \@priority;
}


1;