package LIMS2::WebApp::Controller::API::AutoComplete;
use Moose;
use Try::Tiny;
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

sub qc_templates : Path( '/autocomplete/qc_templates' ) : Args(0) : ActionClass( 'REST' ) {
}

sub qc_templates_GET {
    my ( $self, $c ) = @_;
    my $template_names;

    try{
        $template_names = $c->model('Golgi')->autocomplete(
           'QcTemplate', 'name', $c->request->params->{term},
        );
    };

    return $self->status_ok( $c, entity => $template_names );
}

=head2 GET /api/sequencing_projects

Autocomplete for QC Sequencing Projects names

=cut

sub sequencing_projects : Path( '/autocomplete/sequencing_projects' ) : Args(0) : ActionClass( 'REST' ) {
}

sub sequencing_projects_GET {
    my ( $self, $c ) = @_;
    my $sequencing_project_names;

    try{
        $sequencing_project_names = $c->model('Golgi')->autocomplete(
           'QcSeqProject', 'id', $c->request->params->{term},
        );
    };

    return $self->status_ok( $c, entity => $sequencing_project_names );
}

=head1 AUTHOR

Sajith Perera

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
