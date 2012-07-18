package LIMS2::WebApp::Controller::API::AutoComplete;
use Moose;
use Try::Tiny;
use LIMS2::Model::Util qw( sanitize_like_expr );
use namespace::autoclean;

BEGIN { extends 'LIMS2::Catalyst::Controller::REST'; }

=head1 NAME

LIMS2::WebApp::Controller::API::AutoComplete - Catalyst Controller

=head1 DESCRIPTION

Autocomplete for LIMS2.
jQuery UI autocomplete plugin used to call the sources defined below.

=head1 METHODS

=cut

=head2 GET /api/qc_templates

Autocomplete for QC Template Plate names

=cut

sub qc_templates :Path( '/api/autocomplete/qc_templates' ) :Args(0) :ActionClass( 'REST' ) {
}

sub qc_templates_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'read' );

    my $template_names;

    try {
        $template_names = $self->_entity_column_search(
           $c, 'QcTemplate', 'name', $c->request->params->{term},
        );
    }
    catch {
        $c->log->error($_);
    };

    return $self->status_ok( $c, entity => $template_names );
}

=head2 GET /api/sequencing_projects

Autocomplete for QC Sequencing Projects names

=cut

sub sequencing_projects :Path( '/api/autocomplete/sequencing_projects' ) :Args(0) :ActionClass( 'REST' ) {
}

sub sequencing_projects_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'read' );

    my $sequencing_project_names;

    try {
        $sequencing_project_names = $self->_entity_column_search(
           $c, 'QcSeqProject', 'id', $c->request->params->{term},
        );
    }
    catch {
        $c->log->error( $_ );
    };

    return $self->status_ok( $c, entity => $sequencing_project_names );
}

=head1 GET /api/autocomplete/marker_symbols

Autocomplete for marker symbols

=cut

sub marker_symbols :Path( '/api/autocomplete/marker_symbols' ) :Args(0) :ActionClass('REST') {
}

sub marker_symbols_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'read' );

    my $search_term = $c->request->param( 'term' )
        or return [];

    my @results;

    try {
        my $solr = $c->model('Golgi')->solr_util( solr_rows => 25 );
        @results = map { $_->{marker_symbol} } @{ $solr->query( $search_term, undef, 1 ) };
    }
    catch {
        $c->log->error($_);
    };

    return $self->status_ok( $c, entity => \@results );
}

=head1 GET /api/autocomplete/plate_names

Autocomplete for plate names

=cut

sub plate_names :Path( '/api/autocomplete/plate_names' ) :Args(0) :ActionClass('REST') {
}

sub plate_names_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'read' );

    my $plate_names;

    try {
        $plate_names = $self->_entity_column_search( $c, 'Plate', 'name', $c->req->param('term') );
    }
    catch {
        $c->log->error( $_ );
    };

    return $self->status_ok( $c, entity => $plate_names );
}

sub _entity_column_search {
    my ( $self, $c, $entity_class, $search_column, $search_term ) = @_;

    $search_term = sanitize_like_expr( $search_term );

    my @objects = $c->model('Golgi')->schema->resultset($entity_class)->search(
        {
            $search_column => { ILIKE => '%' . $search_term . '%' },
        },
        {
            rows     => 25,
            order_by => { -asc => $search_column  } ,
            columns  => [ ( $search_column ) ],
        }
    );

    return [ map { $_->$search_column } @objects ];
}

=head1 AUTHOR

Sajith Perera

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
