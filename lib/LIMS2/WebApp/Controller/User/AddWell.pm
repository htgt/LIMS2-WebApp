package LIMS2::WebApp::Controller::User::AddWell;

use Moose;
use TryCatch;
use Data::Dump 'pp';
use Const::Fast;
use Smart::Comments;
use LIMS2::Model::Constants qw( %PROCESS_PLATE_TYPES %PROCESS_SPECIFIC_FIELDS );
use namespace::autoclean;
use LIMS2::Model::Util::AddWellToPlate qw( get_relationship_data );

BEGIN { extends 'Catalyst::Controller'; }

sub begin :Private {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'edit' );
    return;
}

sub add_well : Path( '/user/add_well' ) : Args(0) {
    my ( $self, $c ) = @_;

    return unless $c->request->method eq 'POST';

    my $params = {
        parent_plate    => $c->request->param('parent_plate'),
        parent_well     => $c->request->param('parent_well'),
        target_plate    => $c->request->param('target_plate'),
        target_well     => $c->request->param('target_well'),
        template_well   => $c->request->param('template_well'),
        user            => $c->user->name,
    };


    my $well = $c->model('Golgi')->retrieve_well({
        plate_name  => $params->{target_plate},
        well_name   => $params->{template_well},
    });

    $params->{process} = ($well->parent_processes)[0];

    my $process_data_ref = {
        type            => $params->{process}->type_id,
        input_wells     => [ { plate_name => $params->{parent_plate}, well_name => $params->{parent_well} } ],
        output_wells    => [ { plate_name => $params->{target_plate}, well_name => $params->{target_well} } ],
    };

    my $created_well = get_relationship_data( $c->model('Golgi'), {
        process_data => $process_data_ref,
        process => $params->{process},
        params => $params,
    });

    # foreach my $field ( @{$PROCESS_TYPE_DATA{$process_data_ref->{type}}}) {


    # }

    $c->flash( success_msg => "ID: " . $created_well->id . " - Well successfully added" );

    return $c->response->redirect( $c->uri_for('/user/add_well') );

}


=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
