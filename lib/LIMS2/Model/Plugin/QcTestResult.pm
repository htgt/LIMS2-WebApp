package LIMS2::Model::Plugin::QcTestResult;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use namespace::autoclean;
use Hash::MoreUtils qw( slice slice_def );

requires qw( schema check_params throw );

# TODO: possibly move this code into QcRuns plugin

sub pspec_create_qc_test_result {
    return {
        qc_run_id                 => { validate => 'uuid' },
        qc_eng_seq_id             => { validate => 'integer' },
        well_name                 => { validate => 'well_name' },          #lower case, how to fix this?
        plate_name                => { validate => 'plate_name' },
        score                     => { validate => 'integer' },
        pass                      => { validate => 'boolean' },
        qc_test_result_alignments => { validate => 'non_empty_string' },
    };
}

sub create_qc_test_result {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_qc_test_result );

    my $qc_test_result = $self->schema->resultset('QcTestResult')->create(
        { slice_def( $validated_params, qw( well_name plate_name score pass qc_eng_seq_id qc_run_id ) ) }
    );

    for my $test_result_alignment_params ( @{ $validated_params->{qc_test_result_alignments} } ) {
        $self->create_qc_test_result_alignment( $test_result_alignment_params, $qc_test_result );
    }

    $self->log->debug( 'created qc test result: ' . $qc_test_result->id );

    return $qc_test_result;
}

sub pspec_create_qc_test_result_alignment {
    return {
        qc_seq_read_id    => { validate => 'qc_seq_read_id' },
        primer_name       => { validate => 'non_empty_string' },
        query_start       => { validate => 'integer' },
        query_end         => { validate => 'integer' },
        query_strand      => { validate => 'strand' },
        target_start      => { validate => 'integer' },
        target_end        => { validate => 'integer' },
        target_strand     => { validate => 'strand' },
        score             => { validate => 'integer' },
        pass              => { validate => 'boolean' },
        features          => { validate => 'non_empty_string' },
        cigar             => { validate => 'cigar_string' },
        op_str            => { validate => 'op_str' },
        alignment_regions => { validate => 'non_empty_string' },
    };
}

sub create_qc_test_result_alignment {
    my ( $self, $params, $qc_test_result ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_qc_test_result_alignment );

    my $qc_test_result_alignment = $self->schema->resultset('QcTestResultAlignment')->create(
        {   slice_def(
                $validated_params, qw(
                    qc_seq_read_id primer_name
                    query_start    query_end   query_strand
                    target_start   target_end  target_strand
                    score          pass        features      cigar op_str )
            )
        }
    );

    $qc_test_result_alignment->create_related(
        qc_test_result_alignment_maps => { qc_test_result_id => $qc_test_result->id } );

    for my $alignment_region_params ( @{ $validated_params->{alignment_regions} } ) {
        $self->create_qc_test_result_alignment_region( $alignment_region_params, $qc_test_result_alignment );
    }

    return $qc_test_result_alignment;
}

sub pspec_create_qc_test_result_align_region {
    return {
        name        => { validate => 'non_empty_string' },
        length      => { validate => 'integer' },
        match_count => { validate => 'integer' },
        query_str   => { validate => 'qc_alignment_seq' },
        target_str  => { validate => 'qc_alignment_seq' },
        match_str   => { validate => 'qc_match_str' },
        pass        => { validate => 'boolean' },
    };
}

sub create_qc_test_result_alignment_region {
    my ( $self, $params, $qc_test_result_alignment ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_create_qc_test_result_align_region );

    my $qc_test_result_align_region = $qc_test_result_alignment->create_related( qc_test_result_align_regions =>
            { slice_def( $validated_params, qw( name length match_count query_str target_str match_str pass ) ) } );

    return $qc_test_result_align_region;
}

1;

__END__
