package LIMS2::Model::Util::AnnouncementAdmin;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::AnnouncementAdmin::VERSION = '0.491';
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

sub pspec_delete_message {
    return {
        message_id    => { validate => 'existing_message_id' },
    };
}

=head2 delete_message

Deletes announcement messages from the messages table by message id.

=cut
sub delete_message {
    my ( $model, $params ) = @_;

    my $validated_params = $model->check_params($params, pspec_delete_message);

    my $message_id = $validated_params->{message_id}
      or die "No message_id provided to delete_message";

    #create result variable and then use delete method to delete row

    my $priority = $model->schema->resultset('Message')->search({
        'me.id'  => [ $message_id ],
      },
      {
        order_by    => { -desc => 'me.expiry_date'},
      }
    );

    $priority->delete;

  return;
}

sub pspec_create_message {
    return {
        message         => { validate => 'non_empty_string' },
        expiry_date     => { validate => 'date_time' },
        created_date    => { validate => 'date_time' },
        priority        => { validate => 'existing_priority' },
        wge             => { validate => 'boolean' },
        htgt            => { validate => 'boolean' },
        lims            => { validate => 'boolean' },
    };
}

=head2 create_message

Creates announcement messages in the messages table.

=cut
sub create_message {
    my ( $model, $params ) = @_;

    my $validated_params = $model->check_params($params, pspec_create_message);

    my @message = $model->schema->resultset('Message')->create(
        {
            message         => $validated_params->{message},
            expiry_date     => $validated_params->{expiry_date},
            created_date    => $validated_params->{created_date},
            priority        => $validated_params->{priority},
            wge             => $validated_params->{wge},
            htgt            => $validated_params->{htgt},
            lims            => $validated_params->{lims},
        }
    );

    return \@message;

}

=head2 list_messages

Retrieves announcement messages from the messages table, longest expiry date top.

=cut
sub list_messages {
    my ($model) = @_;

    my @messages = $model->schema->resultset('Message')->search(
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
    my ($model) = @_;

    my @priority = $model->schema->resultset('Priority')->search({},
    {
        order_by    => { -asc => 'me.id'},
    });

    return \@priority;
}


1;