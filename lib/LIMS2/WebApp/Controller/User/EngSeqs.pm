package LIMS2::WebApp::Controller::User::EngSeqs;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::EngSeqs::VERSION = '0.248';
}
## use critic

use Moose;
use LIMS2::Model::Util::EngSeqParams qw( generate_well_eng_seq_params );
use Bio::SeqIO;
use IO::String;
use Try::Tiny;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::User::EngSeqs - Catalyst Controller

=head1 DESCRIPTION

Generate sequence files for wells

=head1 METHODS

=cut

=head2 well_eng_seq

Generate Genbank file for a well

=cut

sub well_eng_seq :Path( '/user/well_eng_seq' ) :Args(1) {
    my ( $self, $c, $well_id ) = @_;

    my $model = $c->model('Golgi');
    my $well =  $model->retrieve_well( { id => $well_id } );

    my $params = $c->request->params;
    my ( $method, undef , $eng_seq_params ) = generate_well_eng_seq_params( $model, $params, $well );

    my $eng_seq = $model->eng_seq_builder->$method( %{ $eng_seq_params } );

    my $formatted_seq;
    Bio::SeqIO->new(
        -fh     => IO::String->new($formatted_seq),
        -format => 'Genbank',
    )->write_seq($eng_seq);
    my $stage = $method =~ /vector/ ? 'vector' : 'allele';
    my $filename = $well->as_string . "_$stage" . '.gbk';

    $c->response->content_type( 'chemical/seq-na-genbank' );
    $c->response->header( 'Content-Disposition' => "attachment; filename=$filename" );
    $c->response->body( $formatted_seq );
    return;
}

=head1 AUTHOR

Team 87

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
