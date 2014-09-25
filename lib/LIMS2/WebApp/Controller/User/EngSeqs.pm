package LIMS2::WebApp::Controller::User::EngSeqs;
use Moose;
use LIMS2::Model::Util::EngSeqParams
    qw( generate_well_eng_seq_params fetch_design_eng_seq_params fetch_eng_seq_params);
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

    my $design  = $well->design;
    my $gene_id = $design->genes->first->gene_id;
    my $gene_data = try { $model->retrieve_gene( { species => $design->species_id, search_term => $gene_id } ) };
    my $gene = $gene_data ? $gene_data->{gene_symbol} : $gene_id;

    my $filename = $well->as_string . "_$stage" . "_$gene" . '.gbk';

    $c->response->content_type( 'chemical/seq-na-genbank' );
    $c->response->header( 'Content-Disposition' => "attachment; filename=$filename" );
    $c->response->body( $formatted_seq );
    return;
}

sub generate_sequence_file :Path( '/user/generate_sequence_file' ) :Args(0) {
    my ( $self, $c ) = @_;

    my $model = $c->model('Golgi');
    my $input_params = $c->request->params;

    if ($c->request->params->{generate_sequence}){
        unless ( $input_params->{design_id} ) {
            # bad
        }
        my $design = $model->c_retrieve_design( { id => $input_params->{design_id} } );
        my $design_params = fetch_design_eng_seq_params( $design );

        my $params = {};
        $params->{cassette} = $input_params->{cassette};
        if ( $input_params->{backbone} ) {
            $params->{backbone} = $input_params->{backbone};
            $params->{stage} = 'vector';
        }
        else {
            $params->{stage} = 'allele';
        }
        $params->{recombinase} = $input_params->{recombinases} || []; # array ref

        $c->stash->{cassette} = $input_params->{cassette};
        $c->stash->{design_id} = $input_params->{design_id};
        $c->stash->{backbone} = $input_params->{backbone};
        $c->stash->{recombinase} = $input_params->{recombinases};

        my ( $method, $eng_seq_params ) = fetch_eng_seq_params( { %{ $params }, %{ $design_params } } );

        delete $design_params->{design_type};
        delete $design_params->{design_cassette_first};

        my $eng_seq = $model->eng_seq_builder->$method( %{ $eng_seq_params }, %{ $design_params } );
        my $formatted_seq;
        Bio::SeqIO->new(
            -fh     => IO::String->new($formatted_seq),
            -format => $input_params->{file_format},
        )->write_seq($eng_seq);
        my $stage = $method =~ /vector/ ? 'vector' : 'allele';
        my $filename = $eng_seq_params->{display_id} . '.gbk';

        $c->response->content_type( 'chemical/seq-na-genbank' );
        $c->response->header( 'Content-Disposition' => "attachment; filename=$filename" );
        $c->response->body( $formatted_seq );

    }

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
