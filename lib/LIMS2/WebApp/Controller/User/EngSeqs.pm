package LIMS2::WebApp::Controller::User::EngSeqs;
use Moose;
use LIMS2::Model::Util::EngSeqParams qw( generate_well_eng_seq_params fetch_design_eng_seq_params );
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

sub generate_sequence_file :Path( '/user/generate_sequence_file' ) :Args(0) {
    my ( $self, $c ) = @_;

    my $model = $c->model('Golgi');
    my $params = $c->request->params;

	if ( $c->req->param('generate_sequence') ) {
        unless ( $params->{design_id} ) {
            # bad
        }
        my $design = $model->retrieve_design( { id => $params->{design_id} } );
        my $design_params = fetch_design_eng_seq_params( $design->as_hash );


    }
    #my ( $method, undef , $eng_seq_params ) = generate_well_eng_seq_params( $model, $params, $well );

    #my $eng_seq = $model->eng_seq_builder->$method( %{ $eng_seq_params } );
    #my $formatted_seq;
    #Bio::SeqIO->new(
        #-fh     => IO::String->new($formatted_seq),
        #-format => 'Genbank',
    #)->write_seq($eng_seq);
    #my $stage = $method =~ /vector/ ? 'vector' : 'allele';
    #my $filename = $well->as_string . "_$stage" . '.gbk';

    #$c->response->content_type( 'chemical/seq-na-genbank' );
    #$c->response->header( 'Content-Disposition' => "attachment; filename=$filename" );
    #$c->response->body( $formatted_seq );
    my @backbones = $model->schema->resultset('Backbone')->all;
    $c->stash->{backbones} = [ sort { lc($a) cmp lc($b) } map { $_->name } @backbones ];
    unshift @{ $c->stash->{backbones} }, "";

    my @cassettes = $model->schema->resultset('Cassette')->all;
    $c->stash->{cassettes} = [ sort { lc($a) cmp lc($b) } map { $_->name } @cassettes ];
    unshift @{ $c->stash->{cassettes} }, "";

    $c->stash->{recombinases} = [ sort map { $_->id } $c->model('Golgi')->schema->resultset('Recombinase')->all ];

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
