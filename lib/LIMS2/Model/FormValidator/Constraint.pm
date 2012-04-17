package LIMS2::Model::FormValidator::Constraint;

use strict;
use warnings FATAL => 'all';

use DateTime::Format::ISO8601;
use Regexp::Common;
use Try::Tiny;
use JSON qw( decode_json );

sub in_set {

    my $values;

    if ( @_ == 1 and ref $_[0] eq 'ARRAY' ) {
        $values = $_[0];
    }
    else {
        $values = \@_;
    }    
    
    my %is_in_set = map { $_ => 1 } @{$values};

    return sub {
        $is_in_set{ shift() }
    };
}

sub in_resultset {
    my ( $model, $resultset_name, $column_name ) = @_;
    in_set( [ map { $_->$column_name } $model->schema->resultset( $resultset_name )->all ] );
}

sub eng_seq_of_type {
    my ( $model, $type ) = @_;
    my $eng_seqs = $model->eng_seq_builder->list_seqs( type => $type );
    in_set( [ map { $_->{name} } @{ $eng_seqs } ] );
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
            DateTime::Format::ISO8601->parse_datetime( $str );
        };
    };    
}

sub strand {
    in_set( 1, -1 );
}

sub phase {
    in_set( 0, 1, 2, -1 );
}

sub boolean {
    in_set( 0, 1 );
}

sub validated_by_annotation {
    in_set( 'yes', 'no', 'maybe', 'not done' );
}

sub assay_result {
    in_set( 'pass', 'fail', 'maybe' );
}

sub dna_seq {
    regexp_matches( qr/^[ATGC]+$/ );
}

sub user_name {
    regexp_matches( qr/^\w+[\w\@\.\-\:]+$/ );
}

sub integer {
    regexp_matches( $RE{num}{int} );
}

sub alphanumeric_string {
    regexp_matches( qr/^\w+$/ );
}

sub non_empty_string {
    regexp_matches( qr/\S+/ );
}

sub bac_library {
    regexp_matches( qr/^\w+$/ );
}

sub bac_name {
    regexp_matches( qr/^[\w()-]+$/ );
}

# More restrictive values  for Cre Bac recombineering
sub cre_bac_recom_bac_library {
    in_set( 'black6' );
}

sub cre_bac_recom_bac_name {
    regexp_matches( qr/^RP2[34]/ );
}

sub cre_bac_recom_cassette {
    in_set( 'pGTK_En2_eGFPo_T2A_CreERT_Kan' );
}

sub cre_bac_recom_backbone {
    in_set( 'pBACe3.6 (RP23) with HPRT3-9 without PUC Linker',
            'pTARBAC1(RP24) with HPRT3-9 without PUC Linker' );
}

sub plate_name {
    regexp_matches( qr/^[A-Z0-9_]+$/ );
}

sub well_name {
    regexp_matches( qr/^[A-O](0[1-9]|1[0-9]|2[0-4])$/ );
}

sub bac_plate {
    regexp_matches( qr/^[abcd]$/ );
}

sub existing_assembly {
    my ( $class, $model ) = @_;    
    in_resultset( $model, 'Assembly', 'assembly' );
}

sub existing_bac_library {
    my ( $class, $model ) = @_;    
    in_resultset( $model, 'BacLibrary', 'library' );
}

sub existing_chromosome {
    my ( $class, $model ) = @_;    
    in_resultset( $model, 'Chromosome', 'chromosome' );
}

sub existing_design_type {
    my ( $class, $model ) = @_;    
    in_resultset( $model, 'DesignType', 'type' );
}

sub existing_design_comment_category {
    my ( $class, $model ) = @_;    
    in_resultset( $model, 'DesignCommentCategory', 'category' );
}

sub existing_design_oligo_type {
    my ( $class, $model ) = @_;    
    in_resultset( $model, 'DesignOligoType', 'type' );
}

sub existing_pipeline {
    my ( $class, $model ) = @_;
    in_resultset( $model, 'Pipeline', 'name' );
}

sub existing_plate_type {
    my ( $class, $model ) = @_;
    in_resultset( $model, 'PlateType', 'type' );
}

sub existing_design_well_recombineering_assay {
    my ( $class, $model ) = @_;
    in_resultset( $model, 'DesignWellRecombineeringAssay', 'assay' );
}

sub existing_genotyping_primer_type {
    my ( $class, $model ) = @_;    
    in_resultset( $model, 'GenotypingPrimerType', 'type' );
}

sub existing_user {
    my ( $class, $model ) = @_;    
    in_resultset( $model, 'User', 'name' );
}

sub existing_role {
    my ( $class, $model ) = @_;    
    in_resultset( $model, 'Role', 'name' );
}

sub existing_plate_name {
    my ( $class, $model ) = @_;
    
    return sub {
        my $plate_name = shift;
        $model->schema->resultset( 'Plate' )->search_rs( { name => $plate_name } )->count;
    }
}

sub existing_qc_template_name {
    my ( $class, $model ) = @_;

    return sub {
        my $qc_template_name = shift;
        $model->schema->resultset( 'QcTemplate' )->search_rs(
            { name => $qc_template_name } )->count;
    }
}

sub existing_assay {
    my ( $class, $model ) = @_;
    in_resultset( $model, 'AssayResult', 'assay' );
}

sub existing_assay_result {
    my ( $class, $model ) = @_;
    in_resultset( $model, 'AssayResult', 'result' );
}

sub existing_intermediate_cassette {
    my ( $class, $model ) = @_;
    eng_seq_of_type( $model, 'intermediate-cassette' );
}

sub existing_intermediate_backbone {
    my ( $class, $model ) = @_;
    eng_seq_of_type( $model, 'intermediate-backbone' );
}

sub existing_final_cassette {
    my ( $class, $model ) = @_;
    eng_seq_of_type( $model, 'final-cassette' ); 
}

sub existing_final_backbone {
    my ( $class, $model ) = @_;
    eng_seq_of_type( $model, 'final-backbone' );
}

sub design_parent_plate_type {
    in_set();
}

sub pcs_parent_plate_type {
    in_set( qw( design pcs ) );
}

sub pgs_parent_plate_type {
    in_set( qw( design pcs pgs ) );
}

sub vtp_parent_plate_type {
    # probably more plates types to add here
    in_set( qw( design pcs pgs ) )
}

sub dna_parent_plate_type {
    in_set( qw( design pcs pgs dna ) );
}

sub ep_parent_plate_type {
    in_set( qw( design pcs pgs dna ep ) );
}

sub epd_parent_plate_type {
    in_set( qw( design pcs pgs ep epd ) );
}

sub fp_parent_plate_type {
    in_set( qw( design pcs pgs ep epd fp ) );
}

sub comma_separated_list {
    regexp_matches( qr/^[^,]+(?:,[^,+])*$/ );
}

sub ensembl_transcript_id {
    regexp_matches( qr/^ENSMUST\d+$/ );
}

sub uuid {
    regexp_matches( qr/^[A-F0-9]{8}(-[A-F0-9]{4}){3}-[A-F0-9]{12}$/ );
}

sub software_version {
    regexp_matches( qr/^\d+\.\d+\.\d+(?:_\d+)?$/ );
}

sub qc_seq_read_id {
    regexp_matches( qr/^[A-Za-o0-9_]+\.[A-Za-z0-9]+$/ );
}

sub cigar_string {
    regexp_matches( qr/^cigar: .+/ );
}

sub op_str {
    regexp_matches( qr/[MD0-9\s|]/ );
}

sub qc_match_str {
    regexp_matches( qr/[|\s]*/ );
}

sub qc_alignment_seq {
    regexp_matches( qr/^[ATGC-]*$/ );
}

sub json {
    return sub {
        my $str = shift;
        try {
            decode_json( $str );
            return 1;
        };
    };
}

1;

__END__
