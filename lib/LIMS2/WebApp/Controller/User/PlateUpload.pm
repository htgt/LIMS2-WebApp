package LIMS2::WebApp::Controller::User::PlateUpload;
use Moose;
use namespace::autoclean;
use Try::Tiny;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::UI::PlateUpload - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

use Smart::Comments;

sub begin :Private {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'edit' );
}

sub plate_upload_step1 :Path( '/user/plate_upload_step1' ) :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        process_types => $c->model('Golgi')->list_process_types,
    );
}

sub plate_upload_step2 :Path( '/user/plate_upload_step2' ) :Args(0) {
    my ( $self, $c ) = @_;

    my $process_type = $c->request->params->{process_type};
    unless ( $process_type ) {
        $c->flash->{error_msg} = 'You must specify a process type';
        return $c->res->redirect('/user/plate_upload_step1');
    }
    #check process type here
    $c->stash( process_type => $process_type );
    my $process_fields = $c->model('Golgi')->get_process_fields( $process_type );

    #my $process_fields = $c->model('Golgi')->get_process_fields( $process_type );
    my $plate_types    = get_process_plate_types( $process_type );
    ### $process_fields
    $c->stash( process_fields => $process_fields );
    $c->stash( plate_types => $plate_types );

    #stash cassettes, backbones, recombinases
    #$c->stash( 'final-cassettes' => $c->model('Golgi')->eng_seq_builder->list_seqs( type => 'final-cassettes' ) );

}

sub plate_upload_complete :Path( '/user/plate_upload_complete' ) :Args(0) {
    my ( $self, $c ) = @_;

    unless ( $c->req->param('create_plate') ) {
        return $c->res->redirect('/user/plate_upload_step1');
    }

    my $well_data = $c->req->upload('well_data');
    my $params = $c->request->params;
    $params->{species} ||= $c->session->{selected_species};
    $params->{created_by} = $c->user->id;
    ### $params

    $c->model('Golgi')->process_plate_data( $params, $well_data->fh );
}

my %PROCESS_FIELDS = (
    #create_id             => [ qw( design_id bacs ) ],
    int_recom             => [ qw( cassette backbone ) ],
    cre_bac_recom         => [ qw( cassette backbone ) ],
    '2w_gateway'          => [ qw( cassette backbone recombinase ) ],
    '3w_gateway'          => [ qw( cassette backbone recombinase ) ],
    recombinase           => [ qw( recombinase ) ],
    first_electroporation => [ qw( cell_line ) ],
);

sub get_process_fields {
    my ( $process_type ) = @_;

    my %process_fields;
    my $fields =  exists $PROCESS_FIELDS{$process_type} ? $PROCESS_FIELDS{$process_type} : [];

    # must get this to report hash, keys and fields, values as list of allowed values
}

my %PROCESS_PLATE_TYPES = (
    create_id              => [ qw( DESIGN ) ],
    int_recom              => [ qw( INT ) ],
    cre_bac_recom          => [ qw( INT ) ],
    '2w_gateway'           => [ qw( POSTINT FINAL ) ],
    '3w_gateway'           => [ qw( POSTINT FINAL ) ],
    dna_prep               => [ qw( DNA ) ],
    recombinase            => [ qw( FINAL XEP POSTINT ) ],
    first_electroporation  => [ qw( EP ) ],
    second_electroporation => [ qw( SEP ) ],
    clone_pick             => [ qw( EP_PICK SEP_PICK XEP_PICK ) ],
    clone_pool             => [ qw( SEP_POOL XEP_POOL ) ],
    freeze                 => [ qw( FP SFP ) ],
);

sub get_process_plate_types {
    my $process_type = shift;

    return $PROCESS_PLATE_TYPES{$process_type};
}

=head1 AUTHOR

Sajith Perera

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
