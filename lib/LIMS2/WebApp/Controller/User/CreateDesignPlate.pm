package LIMS2::WebApp::Controller::User::CreateDesignPlate;
use strict;
use warnings FATAL => 'all';

use Moose;
use Try::Tiny;
use Text::CSV;
use LIMS2::Model::Util::BacsForDesign qw( bacs_for_design );
use MooseX::Types::Path::Class;
use namespace::autoclean;
use Data::UUID;
use Path::Class;
use LIMS2::Util::QcPrimers;

BEGIN { extends 'Catalyst::Controller' };

with qw(
MooseX::Log::Log4perl
WebAppCommon::Crispr::SubmitInterface
);

has no_bacs => (
    is            => 'ro',
    isa           => 'Bool',
    traits        => ['Getopt'],
    documentation => 'No bacs for design',
    cmd_flag      => 'no-bacs',
    lazy_build    => 1,
);

has base_dir => (
    is     => 'ro',
    isa    => 'Str',
    lazy_build => 1,
    traits => [ 'NoGetopt' ],
);

has job_id => (
    is    => 'ro',
    isa   => 'Str',
    lazy_build => 1,
    traits => [ 'NoGetopt' ],
);

has internal_primers => (
    is            => 'ro',
    isa           => 'Bool',
    traits        => ['Getopt'],
    documentation => 'Generate internal primers for any crispr groups linked to the designs (use with generate-primers option)',
    cmd_flag      => 'internal-primers',
    default       => 0,
);

sub _build_job_id {
    return Data::UUID->new->create_str();
};

sub _build_base_dir {
    my $c = shift;
    $ENV{LIMS2_PRIMER_DIR} or die "LIMS2_PRIMER_DIR environment variable not set";
    my $primer_dir = dir( $ENV{LIMS2_PRIMER_DIR} );
    my $base_dir = $primer_dir->subdir( $c->{job_id} );
    $base_dir->mkpath;
    return "$base_dir";
}

sub create_design_plate :Path( '/user/create_design_plate' ) :Args(0){
    my ( $self, $c ) = @_;
    my $req_plate_name = $c->req->param('plate_name');
    my $req_primers = $c->req->param('primers');
    my $req_bacs = $c->req->param('bacs');


    my $plate_data = $c->request->upload('datafile');
    if ($plate_data){
        if ($req_plate_name){
            build_design_plate_data($c, $plate_data, $req_plate_name);
        }
        else{
             $c->stash->{error_msg} = "Please enter a plate name.";
        }
        if ($c->stash->{error_msg}){
            return;
        }
        try{
            $c->model('Golgi')->create_plate( $c->{design_plate_data} );

            if ( $req_primers ){
                $c->stash->{info_msg} = "Generating primers.";
                run_primer_generation($c);
                return;
            }
            else{
                if ($req_bacs){
                    $c->stash->{info_msg} = 'Successful design plate creation with bacs';
                }
                else {
                    $c->stash->{info_msg} = 'Successful design plate creation';
                }
            }
        } catch {
            $c->stash->{error_msg} = 'Error creating plate: ' . $_;
            return;
        };

    }
    if ($req_plate_name && !$plate_data) {
        $c->stash->{error_msg} = "No csv file containing design plate data uploaded."
    }
    return;
}

sub build_design_plate_data {
    my ($c, $plate, $plate_name) = @_;
    my @wells;

    my $csv = Text::CSV->new ( { binary => 1 } )
        or die "Cannot use CSV: ".Text::CSV->error_diag ();
    my $fh;
    open $fh, "<:encoding(utf8)", $plate->tempname or die;
    @wells = extract_data($c, $csv, $fh);
    close $fh;
    unless (@wells){
        return;
    }

    $c->{design_plate_data} = (
        {
            name       => $plate_name,
            species    => $c->session->{selected_species},
            type       => 'DESIGN',
            created_by => $c->user->{_user}->{_column_data}->{name},
            wells      => \@wells,
        }
    );

    return;
}

sub extract_data {
    my ($c, $csv, $fh) = @_;
    my @wells_arr;
    my $headers = $csv->getline( $fh );
    $csv->column_names( @{ $headers } );

    my @columns_array = $csv->column_names;
    my %columns = map { $_ => 1 } @columns_array;

    unless (exists($columns{'well_name'}) && exists($columns{'design_id'})){
        $c->stash->{error_msg} = 'Invalid file. The file must be a csv containing the headers "well_name" and "design_id"';
        return;
    }

    my $well_design_ids = {};

    while ( my $data = $csv->getline_hr( $fh ) ) {
        $c->log->debug( 'Process well data for: ' . $data->{well_name} );
        try{
            my $well_data = _build_well_data( $c, $data );
            $well_design_ids->{ $data->{well_name} } = $data->{design_id};
            push (@wells_arr, $well_data);
        }
        catch {
            $c->stash->{error_msg} = 'Error creating well data: ' . $_ ;
            return;
        };
    }

    $c->{well_design_ids} = $well_design_ids;

    return @wells_arr;
}

sub run_primer_generation {
    my ($c) = @_;
    $c->log->info("Generating primers for new plate");

    $c->{job_id} = _build_job_id;
    $c->{base_dir} = _build_base_dir($c);
    my %common_params = (
        model               => $c->model('Golgi'),
        base_dir            => $c->{base_dir},
        run_on_farm         => 0,
    );
    # persist_primers     => $c->commit,

    # Set up QcPrimers util for genotyping
    my $design_primer_util = LIMS2::Util::QcPrimers->new({
        primer_project_name => 'design_genotyping',
        overwrite           => 0,
        %common_params,
    });

    # Set up QcPrimers util for crisprs
    my $crispr_seq_primer_util = LIMS2::Util::QcPrimers->new({
        primer_project_name => 'crispr_sequencing',
        overwrite           => 0,
        %common_params,
    });
    my @seq_primer_names = $crispr_seq_primer_util->primer_name_list;

    my $crispr_internal_primer_util = LIMS2::Util::QcPrimers->new({
        primer_project_name => 'mgp_recovery',
        overrwite           => 0,
        %common_params,
    });
    my @internal_primer_names = $crispr_internal_primer_util->primer_name_list;

    # Always overwrite the PCR primers if we have generated new sequencing primers
    my $crispr_pcr_primer_util = LIMS2::Util::QcPrimers->new({
        primer_project_name => 'crispr_pcr',
        overwrite            => 1,
        %common_params,
    });

    my @design_primer_names = $design_primer_util->primer_name_list;

    while ( my ($well_name, $design_id) = each %{ $c->{well_design_ids} } ){
        $c->log->info("==== Generating primers for well $well_name, design $design_id ====");
        my $design = $c->model('Golgi')->c_retrieve_design( { id => $design_id } );

        # generate design primers unless already exist
        my @existing_primers = _existing_primers($design, \@design_primer_names);
        if(@existing_primers){
            $c->log->debug("Existing ".(join ", ", @existing_primers)." primers found for design: "
                             .$design->id.". Skipping primer generation");
        }
        else{
            $c->log->debug("Generating genotyping primers for design $design_id");
            $design_primer_util->design_genotyping_primers( $design );
        }

        my @crispr_collections;

        # All crisprs linked to design
        push @crispr_collections, grep { $_ } map { $_->crispr } $design->crispr_designs;
        # All crispr pairs linked to design
        push @crispr_collections, grep { $_ } map { $_->crispr_pair } $design->crispr_designs;

        # Decide how to handle crispr groups linked to design
        my @crispr_groups = grep { $_ } map { $_->crispr_group } $design->crispr_designs;
        unless( $c->{internal_primers} ){
            # No internal primers needed so treat crispr groups in the same way as crisprs and pairs
            push @crispr_collections, @crispr_groups;
            @crispr_groups = ();
        }

        foreach my $collection (@crispr_collections){
            # skip if already has primers
            my $collection_string = $collection->id_column_name.": ".$collection->id;

            my @existing_crispr_primers = _existing_primers($collection, \@seq_primer_names);
            if(@existing_crispr_primers){
                $c->log->debug("Existing ".(join ", ", @existing_crispr_primers)
                                 ." primers found for $collection_string. Skipping primer generation");
                next;
            }

            $c->log->debug("Generating crispr sequencing primers for $collection_string");
            my ($primer_data) = $crispr_seq_primer_util->crispr_sequencing_primers($collection);

            if($primer_data){
                $c->log->debug("Generating crispr PCR primers for $collection_string");
                $crispr_pcr_primer_util->crispr_PCR_primers($primer_data, $collection);
            }
        }

        foreach my $group (@crispr_groups){
            # skip if already has primers
            my $collection_string = "crispr_group_id: ".$group->id;
            my @existing_group_primers = _existing_primers($group, \@internal_primer_names);
            if(@existing_group_primers){
                $c->log->debug("Existing ".(join ", ", @existing_group_primers)
                    ." primers found for $collection_string. Skipping primer generation");
                next;
            }

            $c->log->debug("Generating crispr group sequencing primers with internal primer for $collection_string");
            my ($primer_data) = $crispr_internal_primer_util->crispr_group_genotyping_primers($group);

            if ($primer_data){
                $c->log->debug("Generating crispr PCR primers for $collection_string");
                $crispr_pcr_primer_util->crispr_PCR_primers($primer_data, $group);
            }
        }
    }
    if ($c->req->param('bacs')){
        $c->stash->{info_msg} = "Successful design plate creation with BACs. Primers Generated.";
    }
    else{
        $c->stash->{info_msg} = "Successful design plate creation. Primers Generated.";
    }
    return;
}

sub _existing_primers{
    my ($self, $object, $primer_name_list) = @_;

    my @existing_primers = grep { $_ } map { $object->current_primer($_) } @$primer_name_list;
    my @existing_names = map { $_->as_hash->{primer_name} }  @existing_primers;

    return @existing_names;
}

sub _build_well_data {
    my ( $c, $data ) = @_;
    my $design = $c->model('Golgi')->c_retrieve_design( { id => $data->{design_id} } );

    my %well_data;
    $well_data{well_name}    = $data->{well_name};
    $well_data{design_id}    = $data->{design_id};
    $well_data{process_type} = 'create_di';

    if ( $c->req->param('bacs') ) {
        my $bac_data = _build_bac_data( $c, $design );
        $well_data{bacs} = $bac_data if $bac_data;
    }

    return \%well_data;
}

sub _build_bac_data {
    my ( $c, $design ) = @_;
    my @bac_data;

    my $bacs = try{ bacs_for_design( $c->model('Golgi'), $design ) };

    unless( $bacs ) {
        $c->log->warn( 'Could not find bacs for design: ' . $design->id );
        return;
    }

    my $bac_plate = 'a';
    for my $bac ( @{ $bacs } ) {
        push @bac_data, {
            bac_plate   => $bac_plate++,
            bac_name    => $bac,
            bac_library => 'black6'
        };
    }

    return \@bac_data;
}

sub _build_no_bacs {
    my $self = shift;

    if ( $self->species eq 'Human' ) {
        return 1;
    }

    return 0;
}

__PACKAGE__->meta->make_immutable;

1;

