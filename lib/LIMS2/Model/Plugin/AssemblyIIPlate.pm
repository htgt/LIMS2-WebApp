package LIMS2::Model::Plugin::AssemblyIIPlate;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Hash::MoreUtils qw( slice slice_def );
use LIMS2::Model::Util qw( sanitize_like_expr random_string );
use LIMS2::Model::Util::CreateProcess qw( process_aux_data_field_list );
use LIMS2::Model::Util::DataUpload qw( upload_plate_dna_status upload_plate_dna_quality parse_csv_file upload_plate_pcr_status );
use LIMS2::Model::Util::CreatePlate qw( create_plate_well merge_plate_process_data );
use LIMS2::Model::Util::QCTemplates qw( create_qc_template_from_wells );
use LIMS2::Model::Constants
    qw( %PROCESS_PLATE_TYPES %PROCESS_SPECIFIC_FIELDS %PROCESS_TEMPLATE );
use LIMS2::Model::Util::BarcodeActions qw( checkout_well_barcode_list );
use Const::Fast;
use Try::Tiny;
use Log::Log4perl qw( :easy );
use namespace::autoclean;

requires qw( schema check_params throw retrieve log trace );

sub retrieve_experiments_assembly_ii {
    my ( $self, $params ) = @_;

    my @assembly_ii_experiments;
    if ($params->{crispr_id_assembly_ii}) {
        my @temp = $self->retrieve_experiments_by_field('crispr_id', $params->{crispr_id_assembly_ii});
        push @assembly_ii_experiments, @temp;
    }

    if ($params->{crispr_pair_assembly_ii}) {
        my @temp = $self->retrieve_experiments_by_field('crispr_pair_id', $params->{crispr_pair_assembly_ii});
        push @assembly_ii_experiments, @temp;
    }

    if ($params->{crispr_group_assembly_ii}) {
        my @temp = $self->retrieve_experiments_by_field('crispr_group_id', $params->{crispr_group_assembly_ii});
        push @assembly_ii_experiments, @temp;
    }

    if ($params->{gene_id_assembly_ii}) {
        my @temp = $self->retrieve_experiments_by_field('gene_id', $params->{gene_id_assembly_ii});
        push @assembly_ii_experiments, @temp;
    }

    if ($params->{design_id_assembly_ii}) {
        my @temp = $self->retrieve_experiments_by_field('design_id', $params->{design_id_assembly_ii});
        push @assembly_ii_experiments, @temp;
    }

    return @assembly_ii_experiments;
}

sub retrieve_experiments_by_field {
    my ( $self, $field_name, $field_value ) = @_;

    my @experiments;

    try {
        my @exp_records = $self->schema->resultset('Experiment')->search(
            { $field_name => $field_value },
            { distinct => 1 }
        )->all;

        for my $rec (@exp_records) {
            my %data = $rec->get_columns;
            push @experiments, \%data;
        }
    };

    return @experiments;

}

sub import_wge_crispr_assembly_ii {
    my ( $self, $params ) = @_;

    my $wge_id = $params->{wge_crispr_assembly_ii};

    my $species = $params->{species};
    my $assembly = $self->schema->resultset('SpeciesDefaultAssembly')->find( { species_id => $species } )->assembly_id;

    if ($wge_id) {
        my @crisprs = $self->import_wge_crisprs( [$wge_id], $species, $assembly );
        return @crisprs;
    }

    return;
}

sub find_projects_assembly_ii {
    my ( $self, $params ) = @_;

    my $search;
    if ($params->{gene_id_assembly_ii}) {

        if ($params->{cell_line_assembly_ii}) { $search->{cell_line_id} = $params->{cell_line_assembly_ii}; }
        $search->{gene_id} = $params->{gene_id_assembly_ii};

    } elsif ($params->{project_id}) {
        $search = {
            id => $params->{project_id}
        };
    }

    my @projects_rs = $self->schema->resultset('Project')->search( $search, { distinct => 1, order_by => 'id' })->all;

    my @projects;
    for my $rec (@projects_rs) {
        my %data = $rec->get_columns;
use Data::Dumper;
print Dumper %data;
        my @sponsors = $self->schema->resultset('ProjectSponsor')->search( { project_id => $data{id} } )->all;
        foreach my $sponsor (@sponsors) {
            if ($sponsor->get_column('sponsor_id') ne 'All') {
                $data{sponsor_id} = $sponsor->get_column('sponsor_id');
                last;
            }
            $data{sponsor_id} = $sponsor->get_column('sponsor_id');
        }
        push @projects, \%data;
    }

    return @projects;
}

sub create_project_assembly_ii {
    my ( $self, $params ) = @_;

    # Store params common to search and create
    my $search = { species_id => $params->{species} };
    if( $params->{gene_id_assembly_ii} ) {
        $search->{gene_id} = $params->{gene_id_assembly_ii};
    }
    if( $params->{targeting_type_assembly_ii} ) {
        $search->{targeting_type} = $params->{targeting_type_assembly_ii};
    }
    if( $params->{'cell_line_assembly_ii'} ) {
        $search->{cell_line_id} = $params->{'cell_line_assembly_ii'};
    }
    if( $params->{strategy_assembly_ii} ) {
        $search->{strategy_id} = $params->{strategy_assembly_ii};
    }

    my @project_results;
    my @projects_rs = $self->schema->resultset('Project')->search( $search, { order_by => 'id' })->all;

    if(scalar @projects_rs == 0){
        # Create a new project
        if(my $sponsor = $params->{sponsor_assembly_ii}){
            $search->{sponsors_priority} = { $sponsor => undef };
        }
        my $project;
        $self->txn_do(
            sub {
                try{
                    $project = $self->create_project($search);
                    print "New project created";
                }
                catch{
                    $self->txn_rollback;
                    print "Project creation failed with error:";
                };
            }
        );
    } else {
        print "Project already exists (see list below)";
    }

    return;

}

1;

__END__
