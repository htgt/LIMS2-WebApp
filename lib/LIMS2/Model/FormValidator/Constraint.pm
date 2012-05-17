package LIMS2::Model::FormValidator::Constraint;

use strict;
use warnings FATAL => 'all';

use DateTime::Format::ISO8601;
use Regexp::Common;
use Try::Tiny;
use JSON qw( decode_json );

sub in_set {
    my @args = @_;

    my $values;

    if ( @args == 1 and ref $args[0] eq 'ARRAY' ) {
        $values = $args[0];
    }
    else {
        $values = \@args;
    }

    my %is_in_set = map { $_ => 1 } @{$values};

    return sub {
        $is_in_set{ shift() };
    };
}

sub in_resultset {
    my ( $model, $resultset_name, $column_name ) = @_;
    return in_set( [ map { $_->$column_name } $model->schema->resultset($resultset_name)->all ] );
}

sub existing_row {
    my ( $model, $resultset_name, $column_name ) = @_;

    return sub {
        my $value = shift;
        $model->schema->resultset($resultset_name)->search_rs( { $column_name => $value } )->count > 0;
    };
}

sub eng_seq_of_type {
    my ( $model, $type ) = @_;
    my $eng_seqs = $model->eng_seq_builder->list_seqs( type => $type );
    return in_set( [ map { $_->{name} } @{$eng_seqs} ] );
}

sub regexp_matches {
    my $match = shift;
    return sub {
        shift =~ m/$match/;
    };
}

sub date_time {
    return sub {
        my $str = shift;
        try {
            DateTime::Format::ISO8601->parse_datetime($str);
        };
    };
}

sub strand {
    return in_set( 1, -1 );
}

sub phase {
    return in_set( 0, 1, 2, -1 );
}

sub boolean {
    return in_set( 0, 1 );
}

sub validated_by_annotation {
    return in_set( 'yes', 'no', 'maybe', 'not done' );
}

sub assay_result {
    return in_set( 'pass', 'fail', 'maybe' );
}

sub dna_seq {
    return regexp_matches(qr/^[ATGCN]+$/);
}

sub user_name {
    return regexp_matches(qr/^\w+[\w\@\.\-\:]+$/);
}

sub integer {
    return regexp_matches( $RE{num}{int} );
}

sub alphanumeric_string {
    return regexp_matches(qr/^\w+$/);
}

sub non_empty_string {
    return regexp_matches(qr/\S+/);
}

sub bac_library {
    return regexp_matches(qr/^\w+$/);
}

sub bac_name {
    return regexp_matches(qr/^[\w()-]+$/);
}

# More restrictive values  for Cre Bac recombineering
sub cre_bac_recom_bac_library {
    return in_set('black6');
}

sub cre_bac_recom_bac_name {
    return regexp_matches(qr/^RP2[34]/);
}

sub cre_bac_recom_cassette {
    return in_set('pGTK_En2_eGFPo_T2A_CreERT_Kan');
}

sub cre_bac_recom_backbone {
    return in_set( 'pBACe3.6 (RP23) with HPRT3-9 without PUC Linker', 'pTARBAC1(RP24) with HPRT3-9 without PUC Linker' );
}

sub plate_name {
    return regexp_matches(qr/^[A-Z0-9_]+$/);
}

sub well_name {
    return regexp_matches(qr/^[A-O](0[1-9]|1[0-9]|2[0-4])$/);
}

sub bac_plate {
    return regexp_matches(qr/^[abcd]$/);
}

sub existing_assembly {
    my ( $class, $model ) = @_;
    return in_resultset( $model, 'Assembly', 'assembly' );
}

sub existing_bac_library {
    my ( $class, $model ) = @_;
    return in_resultset( $model, 'BacLibrary', 'library' );
}

sub existing_chromosome {
    my ( $class, $model ) = @_;
    return in_resultset( $model, 'Chromosome', 'chromosome' );
}

sub existing_design_type {
    my ( $class, $model ) = @_;
    return in_resultset( $model, 'DesignType', 'type' );
}

sub existing_design_comment_category {
    my ( $class, $model ) = @_;
    return in_resultset( $model, 'DesignCommentCategory', 'category' );
}

sub existing_design_oligo_type {
    my ( $class, $model ) = @_;
    return in_resultset( $model, 'DesignOligoType', 'type' );
}

sub existing_pipeline {
    my ( $class, $model ) = @_;
    return in_resultset( $model, 'Pipeline', 'name' );
}

sub existing_plate_type {
    my ( $class, $model ) = @_;
    return in_resultset( $model, 'PlateType', 'type' );
}

sub existing_design_well_recombineering_assay {
    my ( $class, $model ) = @_;
    return in_resultset( $model, 'DesignWellRecombineeringAssay', 'assay' );
}

sub existing_genotyping_primer_type {
    my ( $class, $model ) = @_;
    return in_resultset( $model, 'GenotypingPrimerType', 'type' );
}

sub existing_user {
    my ( $class, $model ) = @_;
    return in_resultset( $model, 'User', 'name' );
}

sub existing_role {
    my ( $class, $model ) = @_;
    return in_resultset( $model, 'Role', 'name' );
}

sub existing_plate_name {
    my ( $class, $model ) = @_;

    return existing_row( $model, 'Plate', 'name' );
}

sub existing_qc_run_id {
    my ( $class, $model ) = @_;

    return existing_row( $model, 'QcRun', 'id' );
}

sub existing_qc_seq_project_id {    
    my ( $class, $model ) = @_;

    return existing_row( $model, 'QcSeqProject' , 'id' );
}

sub existing_qc_template_id {
    my ( $class, $model ) = @_;

    return existing_row( $model, 'QcTemplate', 'id' );
}

sub existing_qc_template_name {
    my ( $class, $model ) = @_;

    return existing_row( $model, 'QcTemplate', 'name' );
}

sub existing_qc_seq_read_id {
    my ( $class, $model ) = @_;

    return existing_row( $model, 'QcSeqRead', 'id' );
}

sub existing_qc_eng_seq_id {
    my ( $class, $model ) = @_;

    return existing_row( $model, 'QcEngSeq', 'id' );
}

sub existing_assay {
    my ( $class, $model ) = @_;
    return in_resultset( $model, 'AssayResult', 'assay' );
}

sub existing_assay_result {
    my ( $class, $model ) = @_;
    return in_resultset( $model, 'AssayResult', 'result' );
}

sub existing_intermediate_cassette {
    my ( $class, $model ) = @_;
    return eng_seq_of_type( $model, 'intermediate-cassette' );
}

sub existing_intermediate_backbone {
    my ( $class, $model ) = @_;
    return eng_seq_of_type( $model, 'intermediate-backbone' );
}

sub existing_final_cassette {
    my ( $class, $model ) = @_;
    return eng_seq_of_type( $model, 'final-cassette' );
}

sub existing_final_backbone {
    my ( $class, $model ) = @_;
    return eng_seq_of_type( $model, 'final-backbone' );
}

sub design_parent_plate_type {
    return in_set();
}

sub pcs_parent_plate_type {
    return in_set(qw( design pcs ));
}

sub pgs_parent_plate_type {
    return in_set(qw( design pcs pgs ));
}

sub vtp_parent_plate_type {

    # probably more plates types to add here
    return in_set(qw( design pcs pgs ));
}

sub dna_parent_plate_type {
    return in_set(qw( design pcs pgs dna ));
}

sub ep_parent_plate_type {
    return in_set(qw( design pcs pgs dna ep ));
}

sub epd_parent_plate_type {
    return in_set(qw( design pcs pgs ep epd ));
}

sub fp_parent_plate_type {
    return in_set(qw( design pcs pgs ep epd fp ));
}

sub comma_separated_list {
    return regexp_matches(qr/^[^,]+(?:,[^,+])*$/);
}

sub ensembl_transcript_id {
    return regexp_matches(qr/^ENSMUST\d+$/);
}

sub uuid {
    return regexp_matches(qr/^[A-F0-9]{8}(-[A-F0-9]{4}){3}-[A-F0-9]{12}$/);
}

sub software_version {
    return regexp_matches(qr/^\d+(\.\d+)*(?:_\d+)?$/);
}

sub qc_seq_read_id {
    return regexp_matches(qr/^[A-Za-o0-9_]+\.[A-Za-z0-9]+$/);
}

sub cigar_string {
    return regexp_matches(qr/^cigar: .+/);
}

sub op_str {
    return regexp_matches(qr/^[MDI]\s*\d+(?:\s+[MDI]\s*\d+)*$/);
}

sub qc_match_str {
    return regexp_matches(qr/^[|\s]*$/);
}

sub qc_alignment_seq {
    return regexp_matches(qr/^[ATGC-]*$/);
}

sub json {
    return sub {
        my $str = shift;
        try {
            decode_json($str);
            return 1;
        };
    };
}

sub hashref {
    return sub {
        ref $_[0] eq ref {};
    }
}

1;

__END__
