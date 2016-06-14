package LIMS2::WebApp::Controller::User::EngSeqs;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::EngSeqs::VERSION = '0.405';
}
## use critic

use Moose;
use LIMS2::Model::Util::EngSeqParams qw( generate_custom_eng_seq_params );
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

=head2 pick_gene_generate_sequence_file

Generate a sequence file from a user specified design, cassette and backbone combination.
If a backbone is specified vector sequence is produced, if not then allele sequence is
returned. In addition one or more recombinases can be specified.

=cut

sub pick_gene_generate_sequence_file :Path( '/user/pick_gene_generate_sequence_file' ) :Args(0) {
    my ( $self, $c ) = @_;

    my $gene = $c->request->param( 'search_gene' )
        or return;

    $c->go('generate_sequence_file', [ $gene ] );

    return;
}

=head2 generate_sequence_file

Generate a sequence file from a user specified design, cassette and backbone combination.
If a backbone is specified vector sequence is produced, if not then allele sequence is
returned. In addition one or more recombinases can be specified.

=cut

sub generate_sequence_file :Path( '/user/generate_sequence_file' ) :Args(0) {
    my ( $self, $c, $gene ) = @_;
    my $model = $c->model('Golgi');
    my $input_params = $c->request->params;
    $gene ||= $input_params->{gene};

    if ( $gene ) {
        $c->stash->{design_id_list} = $self->_designs_for_gene( $c, $model, $gene );
        $c->stash->{gene} = $gene;
    }

    if ($c->request->params->{generate_sequence}) {
        $self->_generate_sequence( $c, $model, $input_params );
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

sub _designs_for_gene {
    my ( $self, $c, $model, $gene ) = @_;

    my $species_id = $c->session->{selected_species};
    my $gene_info = try{ $model->find_gene( { search_term => $gene, species => $species_id } ) };
    my $gene_id = $gene_info ? $gene_info->{gene_id} : $gene;
    my $designs = $model->c_list_assigned_designs_for_gene( { gene_id => $gene_id, species => $species_id } );
    my $design_data = [ map { $_->as_hash(1) } @{ $designs } ];

    return $design_data;
}

=head2 _generate_sequence

Generate the custom sequence file, validate input first.

=cut

sub _generate_sequence {
    my ( $self, $c, $model, $input_params ) = @_;

    $c->stash->{cassette}    = $input_params->{cassette};
    $c->stash->{design_id}   = $input_params->{design_id};
    $c->stash->{backbone}    = $input_params->{backbone};
    $c->stash->{picked_recombinase} = $input_params->{recombinases};

    unless ( $input_params->{design_id} ) {
        $c->stash( error_msg => 'You must specify a design id' );
        return;
    }

    unless ( $input_params->{cassette} ) {
        $c->stash( error_msg => 'You must specify a cassette' );
        return;
    }

    my $design = try {
        $model->c_retrieve_design(
            { id => $input_params->{design_id}, species => $c->session->{selected_species} } );
    };
    unless ( $design ) {
        $c->stash(error_msg => 'Can not find design '
                . $input_params->{design_id}
                . ' for species '
                . $c->session->{selected_species} );
        return;
    }

    try {
        my ( $method, $eng_seq_params )
            = generate_custom_eng_seq_params( $model, $input_params, $design );
        my $eng_seq = $model->eng_seq_builder->$method( %{$eng_seq_params} );
        $self->download_genbank_file( $c, $eng_seq, $eng_seq_params->{display_id}, $input_params->{file_format} );
    }
    catch {
        $c->stash( error_msg => 'Error encountered generating sequence: ' . $_ );
    };

    return;
}

sub download_genbank_file {
    my ( $self, $c, $eng_seq, $file_name, $file_format ) = @_;

    $file_format ||= 'Genbank';
    my $suffix = $file_format eq 'Genbank' ? 'gbk' : 'fa';
    my $formatted_seq;
    Bio::SeqIO->new(
        -fh     => IO::String->new($formatted_seq),
        -format => $file_format,
    )->write_seq($eng_seq);
    $file_name = $file_name . ".$suffix";

    $c->response->content_type( 'chemical/seq-na-genbank' );
    $c->response->header( 'Content-Disposition' => "attachment; filename=$file_name" );
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
