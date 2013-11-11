package LIMS2::Model::Util::LegacyCreKnockInProjectReport;

use warnings FATAL => 'all';

=head1 NAME

LIMS2::Model::Util::LegacyCreKnockInProjectReport

=head1 DESCRIPTION

Generate the data for a report showing the current status of the
Cre KnockIn projects.

=cut

use Moose;
use Try::Tiny;
use LIMS2::Util::Tarmits;
use Lingua::EN::Inflect qw( PL );
use namespace::autoclean;

with qw( MooseX::Log::Log4perl );

use Smart::Comments;

has model => (
    is       => 'ro',
    isa      => 'LIMS2::Model',
    required => 1,
);

has tarmits_client => (
    is         => 'ro',
    isa        => 'LIMS2::Util::Tarmits',
    lazy_build => 1,
);

sub _build_tarmits_client {
    LIMS2::Util::Tarmits->new_with_config;
}

#TODO species? sp12 Fri 08 Nov 2013 08:47:35 GMT

has projects => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy_build => 1,
);

sub _build_projects {
    my $self = shift;

    my @projects
        = $self->model->schema->resultset('Project')->search( { sponsor_id => 'Cre Knockin' } );

    return \@projects;
}

has project_well_summary_data => (
    is => 'ro',
    isa => 'HashRef',
    lazy_build => 1,
)

sub _build_project_well_summary_data {
    my $self = shift;

    my $query_results = $self->project_well_summary_query;

    return $self->parse_project_well_summary_results( $query_results );
}

has report_data => (
    is  => 'rw',
    isa => 'ArrayRef',
);

=head2 generate_report_data

generate report data for report

=cut
sub generate_report_data {
    my ( $self ) = @_;
    my @report_data;

    for my $project( @{ $self->projects }  ) {

        my $gene = try {
            $self->model->retrieve_gene(
                { species => $project->species_id, search_term => $project->gene_id } );
        };
        my $marker_symbol = $gene ? $gene->{gene_symbol} : undef;

        my $project_status = $self->find_project_status( $project );

        push @report_data, [
             $project->htgt_project_id,
             $project->id,
             $marker_symbol,
             'foo',
        ]
    };

    $self->report_data( \@report_data );
}

=head2 find_project_status

work out status of project

=cut
sub find_project_status {
    my ( $self, $project ) = @_;

    #my @ws_rows
        #= $self->eucomm_vector_schema->resultset('NewWellSummary')->search( { project_id => $project->project_id } );
    my @ws_rows = ;

    $self->log->debug( 'Project has ' . @ws_rows . ' new_well_summary ' . PL( 'row', scalar @ws_rows ) );

    # No update needed if project has no new_well_summary rows
    # (but warn about orphaned projects in status TVIP or better)
    if ( @ws_rows == 0 ) {
        if ( $project->status->order_by >= $self->project_status_order_for('TVIP') ) {
            $self->log->warn('Project has no new_well_summary rows');
        }
        return;
    }

    my @dist_es_cells      = @{ $self->distributable_es_cells( \@ws_rows ) };
    my @targ_trap_es_cells = @{ $self->targ_trap_es_cells( \@ws_rows ) };

    #TODO do I use lims or htgt project id here? sp12 Fri 08 Nov 2013 08:44:46 GMT
    #my @emi_attempts       = @{ $self->emi_attempts( $project->project_id ) };

    #$self->log->debug('Considering status: Mice - genotype confirmed');

    ## Status is 'Mice - genotype confirmed' if there are any EMI attempts
    ## with status 'Genotype confirmed'
    #if ( any { $_->{status_name} eq 'Genotype confirmed' } @emi_attempts ) {
        #$self->set_status_mice_genotype_confirmed(
            #{   project      => $project,
                #ws_rows      => \@ws_rows,
                #emi_attempts => \@emi_attempts
            #}
        #);
        #return;
    #}

    #$self->log->debug('Considering status: Mice - Microinjection in progress');

    ## Status is 'Mice - Microinjection in progress' if there ane any
    ## EMI attempts
    #if (@emi_attempts) {
        #$self->set_status_mice_microinjection_in_progress(
            #{   project      => $project,
                #ws_rows      => \@ws_rows,
                #emi_attempts => \@emi_attempts
            #}
        #);
        #return;
    #}

    $self->log->debug('Considering status: ES Cells - Targeting Confirmed');

    # Status is 'ES Cells - Targeting Confirmed' if there are any EPD wells
    # flagged distribute or targeted_trap
    if ( @dist_es_cells or @targ_trap_es_cells ) {
        $self->set_status_es_cells_targeting_confirmed(
            {   project => $project,
                ws_rows => \@ws_rows
            }
        );
        return;
    }

    my @ep_plates  = @{ $self->sorted_plate_list( 'EP',  \@ws_rows ) };
    my @epd_plates = @{ $self->sorted_plate_list( 'EPD', \@ws_rows ) };

    my $latest_ep_plate = $ep_plates[-1];

    $self->log->debug('Considering status: ES Cells - Electroporation in Progress');

    # Status is 'ES Cells - Electroporation in Progress' if there is
    # at least 1 EP plate
    if (@ep_plates) {
        $self->set_status_es_cells_electroporation_in_progress(
            {   project   => $project,
                ws_rows   => \@ws_rows,
                ep_plates => \@ep_plates
            }
        );
        return;
    }

    my @dist_targ_vecs = grep { defined $_->pgdgr_distribute and $_->pgdgr_distribute eq 'yes' } @ws_rows;
    $self->log->debug('Considering status: Vector Complete');

    # Status is 'Vector Complete' if there is a distributable targeting vector
    if (@dist_targ_vecs) {
        $self->set_status_vector_complete(
            {   project        => $project,
                ws_rows        => \@ws_rows,
                dist_targ_vecs => \@dist_targ_vecs
            }
        );
        return;
    }
    
}

=head2 distributable_es_cells

Return a list of EPD well names for clones flagged I<epd_distribute>.

=cut
sub distributable_es_cells {
    my ( $self, $ws_rows ) = @_;

    my @dist_es_cells = map { $_->epd_well_name }
        grep { defined $_->epd_distribute and $_->epd_distribute eq 'yes' }
        @{ $self->uniq_ws_rows_by( 'epd_well_id', $ws_rows ) };

    $self->log->debug( 'Project has ' . @dist_es_cells . ' distributable ES ' . PL( 'cell', scalar @dist_es_cells ) );

    return \@dist_es_cells;
}

=head2 targ_trap_es_cells

Return a list of EPD well name for clones flagged I<targeted_trap>.

=cut
sub targ_trap_es_cells {
    my ( $self, $ws_rows ) = @_;

    my @targ_trap_es_cells = map { $_->epd_well_name }
        grep { defined $_->targeted_trap and $_->targeted_trap eq 'yes' }
        @{ $self->uniq_ws_rows_by( 'epd_well_id', $ws_rows ) };

    $self->log->debug(
        'Project has ' . @targ_trap_es_cells . ' targeted trap ES ' . PL( 'cell', scalar @targ_trap_es_cells ) );

    return \@targ_trap_es_cells;
}

=head2 emi_attempts

Retrieve any EMI attempts for the distributable and targeted trap ES
cells from Tarmits.

=cut
sub emi_attempts {
    my ( $self, $project_id ) = @_;

    return [] unless $project_id;

    my $emi_attempts = $self->tarmits_client->find_mi_attempt(
        {
            'es_cell_ikmc_project_id_eq' => $project_id,
            'is_active_eq'               => 'true',
            'report_to_public_eq'        => 'true',
        }
    );

    $self->log->debug( 'Project has ' . @{$emi_attempts} . ' emi ' . PL( 'attempt', scalar @{$emi_attempts} ) );

    return $emi_attempts;
}

sub uniq_ws_rows_by {
    my ( $self, $key_col, $ws_rows ) = @_;

    my ( %seen, @uniq );
    for my $row ( @{$ws_rows} ) {
        my $key_val = $row->$key_col;
        next unless defined $key_val and not $seen{$key_val}++;
        push @uniq, $row;
    }

    return \@uniq;
}

=head2 sorted_plate_list

Return a list of plates (C<HTGTDB::NewWellSummary> objects) of the requested
type sorted on created_date.

=cut
sub sorted_plate_list {
    my ( $self, $type, $ws_rows ) = @_;

    my $well_id_col = lc($type) . '_well_id';
    my $date_col    = lc($type) . '_plate_created_date';

    my @plates = sort { $a->$date_col <=> $b->$date_col }
        @{ $self->uniq_ws_rows_by( $well_id_col, $ws_rows ) };

    $self->log->debug( 'Found ' . @plates . " distinct $type " . PL( 'plate', scalar @plates ) );

    return \@plates;
}

=head2 project_well_summary_query

Large query to grab all of the well summary rows for the projects
we are interested in.

=cut
sub project_well_summary_query {
    my ( $self ) = @_;

my $sql_query =  <<"SQL";
WITH project_requests AS (
SELECT p.id AS project_id,
 p.htgt_project_id,
 p.sponsor_id,
 p.gene_id,
 p.targeting_type,
 pa.allele_type,
 pa.cassette_function,
 pa.mutation_type,
 cf.id AS cassette_function_id,
 cf.promoter,
 cf.conditional,
 cf.cre,
 cf.well_has_cre,
 cf.well_has_no_recombinase
FROM projects p
INNER JOIN project_alleles pa ON pa.project_id = p.id
INNER JOIN cassette_function cf ON cf.id = pa.cassette_function
WHERE p.sponsor_id   = 'Cre Knockin'
AND p.targeting_type = 'single_targeted'
AND p.species_id     = 'Mouse'
)
SELECT pr.project_id
, pr.htgt_project_id
, s.design_id
, s.design_name
, s.design_type
, s.design_phase
, s.design_plate_name
, s.design_plate_id
, s.design_well_name
, s.design_well_id
, s.design_gene_id
, s.design_gene_symbol
, s.int_plate_name
, s.int_plate_id
, s.int_well_name
, s.int_well_id
, s.final_pick_plate_name AS targeting_vector_plate_name
, s.final_pick_plate_id AS targeting_vector_plate_id
, s.final_pick_well_name AS targeting_vector_well_name
, s.final_pick_well_id AS targeting_vector_well_id
, s.final_pick_cassette_name AS vector_cassette_name
, s.final_pick_cassette_promoter AS vector_cassette_promotor
, s.final_pick_backbone_name AS vector_backbone_name
, s.ep_first_cell_line_name AS cell_line
, s.ep_well_recombinase_id AS ep_recombinase
, s.ep_pick_plate_name AS clone_plate_name
, s.ep_pick_plate_id AS clone_plate_id
, s.ep_pick_well_name AS clone_well_name
, s.ep_pick_well_id AS clone_well_id
, s.ep_pick_well_accepted AS clone_accepted
FROM summaries s
INNER JOIN project_requests pr ON s.design_gene_id = pr.gene_id
WHERE s.design_type IN (SELECT design_type FROM mutation_design_types WHERE mutation_id = pr.mutation_type)
AND (
    (pr.conditional IS NULL)
    OR
    (pr.conditional IS NOT NULL AND s.final_pick_cassette_conditional = pr.conditional)
)
AND (
    (pr.promoter IS NULL)
    OR
    (pr.promoter IS NOT NULL AND pr.promoter = s.final_pick_cassette_promoter)
)
AND (
    (pr.cre IS NULL)
    OR
    (pr.cre IS NOT NULL AND s.final_pick_cassette_cre = pr.cre)
)
AND (
    (pr.well_has_cre IS NULL)
    OR
    (
        (pr.well_has_cre = true AND s.final_pick_recombinase_id = 'Cre')
        OR
        (pr.well_has_cre = false AND (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL))
    )
)
AND (
    (pr.well_has_no_recombinase IS NULL)
    OR
    (
     pr.well_has_no_recombinase IS NOT NULL AND (
      (pr.well_has_no_recombinase = true AND (s.final_pick_recombinase_id = '' OR s.final_pick_recombinase_id IS NULL))
       OR
      (pr.well_has_no_recombinase = false AND s.final_pick_recombinase_id IS NOT NULL)
     )
    )
)
AND s.ep_pick_well_id > 0
GROUP by pr.project_id
, pr.htgt_project_id
, s.design_id
, s.design_name
, s.design_type
, s.design_phase
, s.design_plate_name
, s.design_plate_id
, s.design_well_name
, s.design_well_id
, s.design_gene_id
, s.design_gene_symbol
, s.int_plate_name
, s.int_plate_id
, s.int_well_name
, s.int_well_id
, s.final_pick_plate_name
, s.final_pick_plate_id
, s.final_pick_well_name
, s.final_pick_well_id
, s.final_pick_cassette_name
, s.final_pick_cassette_promoter
, s.final_pick_backbone_name
, s.ep_first_cell_line_name
, s.ep_well_recombinase_id
, s.ep_pick_plate_name
, s.ep_pick_plate_id 
, s.ep_pick_well_name
, s.ep_pick_well_id
, s.ep_pick_well_accepted
ORDER BY pr.project_id
, s.design_id
, s.design_gene_id
, s.final_pick_well_id
, s.ep_pick_well_id
SQL

    my $sql_result = $self->model->schema->storage->dbh_do(
        sub {
            my ( $storage, $dbh ) = @_;
            my $sth = $dbh->prepare( $sql_query );
            $sth->execute or die 'Unable to execute query: ' . $dbh->errstr;
            $sth->fetchall_arrayref({ });
        }
    );

    return $sql_result;
}

=head2 parse_project_well_summary_results

Parse the output of the sql command used to gather the well summary data
linked to each project.

=cut
sub parse_project_well_summary_results {
    my ( $self, $query_results  ) = @_;
    
}

__PACKAGE__->meta->make_immutable;

1;

__END__
