package LIMS2::Model::FormValidator::Constraint;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::FormValidator::Constraint::VERSION = '0.360';
}
## use critic


=head1 NAME

LIMS2::Model::FormValidator::Constraint

=head1 DESCRIPTION

Subclass of WebappCommon::FormValidator::Constraint, where the common constraints can be found.
Add LIMS2 specific constraints to this file.
Add constraints that may be used by both LIMS2 and WGE to WebappCommon::FormValidator::Constraint.

=cut

use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;

extends 'WebAppCommon::FormValidator::Constraint';

has '+model' => (
    isa => 'LIMS2::Model',
);

sub eng_seq_of_type {
    my ( $self, $type ) = @_;
    my $eng_seqs = $self->model->eng_seq_builder->list_seqs( type => $type );
    return $self->in_set( [ map { $_->{name} } @{$eng_seqs} ] );
}

sub passorfail {
    return shift->in_set( 'pass', 'passb', 'fail' );
}

sub validated_by_annotation {
    return shift->in_set( 'yes', 'no', 'maybe', 'not done' );
}

sub genotyping_result_text {
    return shift->in_set( 'potential', 'present', 'absent', 'pass', 'passb', 'fail', 'fa', 'na', 'nd', 'lrpcr_pass' );
}

sub chromosome_fail_text {
    return shift->in_set( '0', '1', '2', '3', '4', 'Y' );
}

sub oxygen_condition {
    return shift->in_set( 'normoxic', 'hypoxic' );
}

sub confidence_float {
    my $self = shift;
    return sub {
        my $val = shift;
        return $val =~ qr/^[<>]?\s*\d+(\.\d+)?$/ ;
    }
}

sub copy_float {
    my $self = shift;
    return sub {
        my $val = shift;
        return $val =~ qr/^\d+(\.\d+)?$/ ;
    }
}

sub signed_float {
    return shift->regexp_matches(qr/^[-]?\d+(\.\d+)?$/);
}

sub bac_library {
    return shift->regexp_matches(qr/^\w+$/);
}

sub bac_name {
    return shift->regexp_matches(qr/^[\w()-]+$/);
}

# More restrictive values  for Cre Bac recombineering
sub cre_bac_recom_bac_library {
    return shift->in_set('black6');
}

sub cre_bac_recom_bac_name {
    return shift->regexp_matches(qr/^RP2[34]/);
}

sub cre_bac_recom_cassette {
    return shift->in_set('pGTK_En2_eGFPo_T2A_CreERT_Kan');
}

sub cre_bac_recom_backbone {
    return shift->in_set( 'pBACe3.6 (RP23) with HPRT3-9 without PUC Linker',
        'pTARBAC1(RP24) with HPRT3-9 without PUC Linker' );
}

sub plate_name {
    return shift->regexp_matches(qr/^[A-Za-z0-9_\(\)]+$/);
}

sub well_name {
    return shift->regexp_matches(qr/^[A-O](0[1-9]|1[0-9]|2[0-4])$/);
}

sub plate_barcode {
    return shift->regexp_matches(qr/^[A-Za-z0-9]+$/);
}

sub well_barcode {
    return shift->regexp_matches(qr/^[A-Za-z0-9]+$/);
}

sub bac_plate {
    return shift->regexp_matches(qr/^[abcd]$/);
}

sub existing_well_barcode {
    return shift->in_resultset( 'WellBarcode', 'barcode' );
}
sub existing_bac_library {
    return shift->in_resultset( 'BacLibrary', 'id' );
}

sub existing_cell_line {
	return shift->in_resultset( 'CellLine', 'name' );
}

sub existing_plate_type {
    return shift->in_resultset( 'PlateType', 'id' );
}

sub existing_process_type {
    return shift->in_resultset( 'ProcessType', 'id' );
}

sub existing_recombinase {
    return shift->in_resultset( 'Recombinase', 'id');
}

sub existing_recombineering_result_type {
    return shift->in_resultset( 'RecombineeringResultType', 'id' );
}

sub existing_colony_type {
    return shift->in_resultset ( 'ColonyCountType', 'id')
}

sub existing_primer_band_type {
    return shift->in_resultset ( 'PrimerBandType', 'id')
}

sub recombineering_result {
    return shift->in_set( 'pass', 'fail', 'weak' );
}

sub dna_quality {
    return shift->in_set( qw( L M ML S U ) );
}

sub existing_genotyping_result_type {
    return shift->in_resultset( 'GenotypingResultType', 'id' );
}

sub existing_sponsor {
    return shift->in_resultset( 'Sponsor', 'id' );
}

sub existing_plate_name {
    return shift->existing_row( 'Plate', 'name' );
}

sub existing_qc_run_id {
    return shift->existing_row( 'QcRun', 'id' );
}

sub existing_qc_seq_project_id {
    return shift->existing_row( 'QcSeqProject', 'id' );
}

sub existing_qc_template_id {
    return shift->existing_row( 'QcTemplate', 'id' );
}

sub existing_qc_template_name {
    return shift->existing_row( 'QcTemplate', 'name' );
}

sub existing_qc_seq_read_id {
    return shift->existing_row( 'QcSeqRead', 'id' );
}

sub existing_qc_eng_seq_id {
    return shift->existing_row( 'QcEngSeq', 'id' );
}

sub existing_intermediate_cassette {
    return shift->eng_seq_of_type( 'intermediate-cassette' );
}

sub existing_intermediate_backbone {
    return shift->eng_seq_of_type( 'intermediate-backbone' );
}

sub existing_final_cassette {
    return shift->eng_seq_of_type( 'final-cassette' );
}

sub existing_final_backbone {
    return shift->eng_seq_of_type( 'final-backbone' );
}

sub existing_crispr_damage_type {
    return shift->existing_row( 'CrisprDamageType', 'id' );
}

sub existing_crispr_es_qc_run_id {
    return shift->existing_row( 'CrisprEsQcRuns', 'id' );
}

sub existing_crispr_es_qc_seq_project {
    return shift->existing_row( 'CrisprEsQcRuns', 'sequencing_project' );
}


# intermediate backbones can be in a final vector, so need a list of all backbone types
# which eng-seq-builder can not provide using the eng_seq_of_type method
sub existing_backbone {
    return shift->existing_row( 'Backbone', 'name' );
}

# all cassettes, regardless of type, for validated cassette names sent to generate_eng_seq_params
sub existing_cassette {
    return shift->existing_row( 'Cassette', 'name' );
}

sub existing_nuclease {
    return shift->existing_row( 'Nuclease', 'name');
}

sub existing_crispr_tracker_rna {
    return shift->existing_row( 'CrisprTrackerRna', 'name');
}

sub existing_crispr_primer_type {
	return shift->in_resultset( 'CrisprPrimerType', 'primer_name' );
}

sub qc_seq_read_id {
    return shift->regexp_matches(qr/^[A-Za-z0-9_]+\.[-A-Za-z0-9_]+$/);
}

sub cigar_string {
    return shift->regexp_matches(qr/^cigar: .+/);
}

sub op_str {
    return shift->regexp_matches(qr/^[MDI]\s*\d+(?:\s+[MDI]\s*\d+)*$/);
}

sub qc_match_str {
    return shift->regexp_matches(qr/^[|\s]*$/);
}

sub qc_alignment_seq {
    return shift->regexp_matches(qr/^[ATGCN-]*$/);
}

sub pass_or_fail {
    return shift->regexp_matches(qr/^(pass|fail)$/i);
}

sub existing_recovery_class {
    return shift->in_resultset( 'ProjectRecoveryClass', 'id' );
}

sub existing_design_id {
    return shift->in_resultset( 'Design', 'id' );
}

sub existing_crispr_pair_id {
    return shift->in_resultset( 'CrisprPair', 'id' );
}

sub existing_crispr_group_id {
    return shift->in_resultset( 'CrisprGroup', 'id' );
}

sub existing_crispr_plate_appends_type {
    return shift->in_resultset( 'CrisprPlateAppendsType', 'id' );
}

sub assembly_qc_type{
    return shift->in_enum_column('WellAssemblyQc','qc_type');
    #return shift->in_set('CRISPR_LEFT_QC','CRISPR_RIGHT_QC','VECTOR_QC');
}

sub assembly_qc_value{
    return shift->in_enum_column('WellAssemblyQc','value');
    #return shift->in_set('Good','Bad','Wrong');
}

sub existing_project_id {
    return shift->in_resultset( 'Project', 'id' );
}

sub existing_experiment_id {
    return shift->in_resultset( 'Experiment', 'id' );
}

sub primer_array {
    my $self = shift;
    return sub {
        ref $_[0] eq 'ARRAY';
    }
}

=head2 in_enum_column

  Use enum from database schema as set, e.g. value column from WellAssemblyQc

  data_type: 'enum'
  extra: {custom_type_name => "qc_element_type",list => ["Good","Bad","Wrong"]}
  is_nullable: 0

=cut

sub in_enum_column{
    my ($self,$resultset_name,$column_name) = @_;
    my $col_info = $self->model->schema->resultset($resultset_name)->result_source->column_info($column_name);
    my $list = $col_info->{extra}->{list};
    return $self->in_set(@{ $list });
}

__PACKAGE__->meta->make_immutable;

1;

__END__

