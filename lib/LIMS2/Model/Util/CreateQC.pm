package LIMS2::Model::Util::CreateQC;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::CreateQC::VERSION = '0.071';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [
        qw(
            create_or_retrieve_eng_seq
            find_qc_template_with_layout
            build_qc_template_search_params
            create_qc_run_seq_proj
            create_qc_test_result_alignment
            get_qc_run_seq_well_from_alignments
            )
    ]
};

use Log::Log4perl qw( :easy );
use JSON ();
use Data::Compare qw( Compare );
use List::MoreUtils qw( uniq );
use Hash::MoreUtils qw( slice );
use LIMS2::Exception::Validation;
use LIMS2::Exception::System;

sub create_or_retrieve_eng_seq {
    my ( $model, $params ) = @_;

    return $model->schema->resultset('QcEngSeq')->find_or_create(
        {   method => $params->{eng_seq_method},
            params => _encode_eng_seq_params( $params->{eng_seq_params} )
        },
        { key => 'qc_eng_seqs_method_params_key' }
    );
}

sub build_qc_template_search_params {
    my ( $params ) = @_;

    if ( defined $params->{id} ) {
        return { 'me.id' => $params->{id} };
    }

    my %search;

    if ( $params->{species} ) {
        $search{'me.species_id'} = $params->{species};
    }

    if ( $params->{name} ) {
        $search{'me.name'} = $params->{name};
    }
    else {
        LIMS2::Exception::System->throw(
            'Can not build qc template search params without a template name' );
    }

    if ( $params->{created_before} ) {
        $search{'me.created_at'} = { '<=', $params->{created_before} };
    }

    if ( $params->{latest} ) {
        if ( $params->{created_before} ) {
            $search{'me.created_at'} = {
                '=' => \[
                    '( select max(created_at) from qc_templates where name = me.name and created_at <= ? )',
                    [ created_at => $params->{created_before} ]
                ]
            };
        }
        else {
            $search{'me.created_at'}
                = { '=' => \['( select max(created_at) from qc_templates where name = me.name )'] };
        }
    }

    return \%search;
}

sub find_qc_template_with_layout {
    my ( $model, $species, $template_name, $template_layout ) = @_;

    my $template_rs = $model->schema->resultset('QcTemplate')->search(
        {
            'me.name'       => $template_name,
            'me.species_id' => $species
        },
        { prefetch => { qc_template_wells => 'qc_eng_seq' } }
    );

    while ( my $template = $template_rs->next ) {
        if ( _qc_template_has_identical_layout( $template, $template_layout ) ) {
            DEBUG("Found existing template with identical layout");
            return $template;
        }
    }

    return;
}

sub pspec__create_qc_run_seq_proj {
    return {
        qc_seq_project_id => { validate => 'non_empty_string' },
        species_id        => { validate => 'existing_species' }
    };
}

sub create_qc_run_seq_proj {
    my ( $model, $qc_run, $params ) = @_;

    my $validated_params = $model->check_params( $params, pspec__create_qc_run_seq_proj );

    my $qc_seq_project = $model->schema->resultset( 'QcSeqProject' )->find_or_create(
        {
            id         => $validated_params->{qc_seq_project_id},
            species_id => $validated_params->{species_id}
        }
    );

    return $qc_run->create_related( qc_run_seq_projects => { qc_seq_project_id => $qc_seq_project->id } );
}

sub pspec__create_qc_test_result_alignment {
    return {
        qc_seq_read_id    => { validate => 'existing_qc_seq_read_id' },
        qc_eng_seq_id     => { validate => 'existing_qc_eng_seq_id' },
        primer_name       => { validate => 'non_empty_string' },
        query_start       => { validate => 'integer' },
        query_end         => { validate => 'integer' },
        query_strand      => { validate => 'strand' },
        target_start      => { validate => 'integer' },
        target_end        => { validate => 'integer' },
        target_strand     => { validate => 'strand' },
        score             => { validate => 'integer' },
        pass              => { validate => 'boolean' },
        features          => { optional => 1 },
        cigar             => { validate => 'cigar_string' },
        op_str            => { validate => 'op_str' },
        alignment_regions => { optional => 1 }
    };
}

sub create_qc_test_result_alignment {
    my ( $model, $params, $qc_test_result ) = @_;

    my $validated_params
        = $model->check_params( $params, pspec__create_qc_test_result_alignment );

    $validated_params->{features} ||= '';

    my $alignment = $model->schema->resultset('QcAlignment')->create(
        {   slice(
                $validated_params, qw( qc_seq_read_id qc_eng_seq_id primer_name
                    query_start query_end query_strand
                    target_start target_end target_strand
                    score pass features cigar op_str )
            )
        }
    );

    for my $region ( @{ $validated_params->{alignment_regions} || [] } ) {
        _create_qc_test_result_alignment_region( $model, $region, $alignment );
    }

    return $alignment;
}

sub pspec__create_qc_test_result_alignment_region {
    return {
        name        => { validate => 'non_empty_string' },
        length      => { validate => 'integer' },
        match_count => { validate => 'integer' },
        query_str   => { validate => 'qc_alignment_seq' },
        target_str  => { validate => 'qc_alignment_seq' },
        match_str   => { validate => 'qc_match_str', trim => 0 },
        pass        => { validate => 'boolean' }
    };
}

sub _create_qc_test_result_alignment_region {
    my ( $model, $params, $alignment ) = @_;

    my $validated_params
        = $model->check_params( $params, pspec__create_qc_test_result_alignment_region );

    return $alignment->create_related( qc_alignment_regions => $validated_params );
}

sub get_qc_run_seq_well_from_alignments {
    my ( $model, $qc_run_id, $alignments ) = @_;

    my @qc_seq_read_ids = uniq map { $_->{qc_seq_read_id} } @{$alignments};

    my @wells = $model->schema->resultset('QcRunSeqWell')->search(
        {   'me.qc_run_id'                                => $qc_run_id,
            'qc_run_seq_well_qc_seq_reads.qc_seq_read_id' => { -in => \@qc_seq_read_ids }
        },
        {   join     => 'qc_run_seq_well_qc_seq_reads',
            columns  => ['me.id'],
            distinct => 1
        }
    );

    LIMS2::Exception::Validation->throw(
        {
            message => 'Alignments must belong to exactly one well',
            params  => { alignments => $alignments }
        }
    ) unless @wells == 1;

    return shift @wells;
}

sub _encode_eng_seq_params {
    my ( $eng_seq_params ) = @_;
    return JSON->new->utf8->canonical->encode($eng_seq_params);
}

sub _qc_template_has_identical_layout {
    my ( $template, $wanted_layout ) = @_;

    my %template_layout = map { $_->name => $_->qc_eng_seq_id } $template->qc_template_wells;

    return Compare( \%template_layout, $wanted_layout );
}

1;

__END__
