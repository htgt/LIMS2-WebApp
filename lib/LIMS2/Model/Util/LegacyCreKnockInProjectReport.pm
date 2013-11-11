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
    is         => 'ro',
    isa        => 'HashRef',
    traits     => [ 'Hash' ],
    lazy_build => 1,
    handles    => {
        have_project_data => 'exists',
        get_project_data => 'get',
    }
);

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

    for my $project ( @{ $self->projects }  ) {
        Log::Log4perl::NDC->remove;
        Log::Log4perl::NDC->push( $project->id );
        $self->log->debug('Working on project');
        my ( $project_data, $marker_symbol );
        if ( $self->have_project_data( $project->id ) ) {
            $project_data = $self->get_project_data( $project->id );
            $marker_symbol = $project_data->{gene};
        }
        else {
            #TODO what to do here? sp12 Mon 11 Nov 2013 08:17:27 GMT
            $self->log->warn('Project has no summary rows' );
            my $gene = try {
                $self->model->retrieve_gene(
                    { species => $project->species_id, search_term => $project->gene_id } );
            };
            $marker_symbol = $gene ? $gene->{gene_symbol} : undef;
        }

        my $project_status = $project_data ? $self->find_project_status( $project, $project_data ) : 'unknown';
        $self->log->warn( "Status: $project_status" );

        push @report_data, [
             $project->htgt_project_id,
             $project->id,
             $marker_symbol,
             $project_status,
        ]
    };
    Log::Log4perl::NDC->remove;

    $self->report_data( \@report_data );
}

=head2 find_project_status

work out status of project

=cut
sub find_project_status {
    my ( $self, $project, $project_data ) = @_;

    my $ws_rows = $project_data->{ws};

    $self->log->debug( 'Project has ' . scalar(@{ $ws_rows }) . ' summary row(s)' );

    my @dist_es_cells      = @{ $self->distributable_es_cells( $ws_rows ) };
    #TODO targeted trap ?? sp12 Mon 11 Nov 2013 08:59:37 GMT
    #my @targ_trap_es_cells = @{ $self->targ_trap_es_cells( $ws_rows ) };

    $self->log->debug('Considering status: Mice - genotype confirmed');
    $self->log->debug('Considering status: Mice - Microinjection in progress');

    my $tarmits_status = $self->tarmits_status( $ws_rows );
    if ( $tarmits_status ) {
        return $tarmits_status;
    }

    $self->log->debug('Considering status: ES Cells - Targeting Confirmed');

    # Status is 'ES Cells - Targeting Confirmed' if there are any EPD wells
    # flagged distribute or targeted_trap
    if ( @dist_es_cells ) {
        return 'ES Cells - Targeting Confirmed';
    }

    my @ep_plates = @{ $self->sorted_plate_list( 'EP',  $ws_rows ) };

    $self->log->debug('Considering status: ES Cells - Electroporation in Progress');

    # Status is 'ES Cells - Electroporation in Progress' if there is at least 1 EP plate
    if (@ep_plates) {
        return 'ES Cells - Electroporation in Progress';
    }

    my @dist_targ_vecs = @{ $self->distributable_targeting_vectors( $ws_rows ) };
    $self->log->debug('Considering status: Vector Complete');

    # Status is 'Vector Complete' if there is a distributable targeting vector
    if (@dist_targ_vecs) {
        return 'Vector Complete';
    }

    #TODO what status to be fall back to sp12 Mon 11 Nov 2013 09:15:19 GMT
    return 'Unknown';
}

=head2 distributable_es_cells

Return a list of ep_pick well names for clones flagged accepted.

=cut
sub distributable_es_cells {
    my ( $self, $ws_rows ) = @_;

    my @dist_es_cells = map { $_->{clone_well_id} }
        grep { $_->{clone_accepted} }
        @{ $self->uniq_ws_rows_by( 'clone_well_id', $ws_rows ) };

    $self->log->debug( 'Project has ' . @dist_es_cells . ' distributable ES cell(s)' );

    return \@dist_es_cells;
}

=head2 distributable_targeting_vectors

Return a list of targeting vector well names for vectors flagged accepted.

=cut
sub distributable_targeting_vectors {
    my ( $self, $ws_rows ) = @_;

    my @dist_targ_vecs = map { $_->{tv_well_id} }
        grep { $_->{tv_accepted} }
        @{ $self->uniq_ws_rows_by( 'tv_well_id', $ws_rows ) };

    $self->log->debug( 'Project has ' . @dist_targ_vecs . ' distributable targeting vector(s)' );

    return \@dist_targ_vecs;
}

=head2 tarmits_status

Retrieve any EMI attempts for the distributable and targeted trap ES
cells from Tarmits.

If we have emi attempts with status of genotype confirmed then the project
status is Mice - genotype confirmed

If we have emi attempts but none are genotype confirmed then the projects
status is Mice - microinjection in progress

If there are no emi attempts return undef

=cut
sub tarmits_status {
    my ( $self, $ws_rows ) = @_;
    my $status;

    my @es_cell_names = map { $_->{clone_plate_name} . '_' . $_->{clone_well_name} }
        grep { $_->{clone_well_id} } @{$ws_rows};

    my $emi_attempt_count = 0;
    for my $es_cell_name ( @es_cell_names ) {
        my $es_cell = $self->tarmits_client->find_es_cell( { name_eq => $es_cell_name } );

        if ( $es_cell->[0] ) {
            my $emi_attempt = $self->tarmits_client->find_mi_attempt(
                es_cell_id_eq       => $es_cell->[0]{id},
                is_active_eq        => 'true',
                report_to_public_eq => 'true',
            );
            my $emi = shift @{ $emi_attempt };
            if ( $emi ) {
                $emi_attempt_count++;
                if ( $emi->{status_name} eq 'Genotype confirmed' ) {
                    return 'Mice - genotype confirmed';
                }
            }
        }
    }

    if ( $emi_attempt_count ) {
        $status = 'Mice - Microinjection in progress';
    }

    return $status;
}

sub uniq_ws_rows_by {
    my ( $self, $key_col, $ws_rows ) = @_;

    my ( %seen, @uniq );
    for my $row ( @{$ws_rows} ) {
        my $key_val = $row->{$key_col};
        next unless defined $key_val and not $seen{$key_val}++;
        push @uniq, $row;
    }

    return \@uniq;
}

=head2 sorted_plate_list

Return a list of plates names of the requested type.

=cut
sub sorted_plate_list {
    my ( $self, $type, $ws_rows ) = @_;

    my $well_id_col = lc($type) . '_well_id';

    my @plates = map{ $_->{ep_plate_name} } @{ $self->uniq_ws_rows_by( $well_id_col, $ws_rows ) };

    $self->log->debug( 'Found ' . @plates . " distinct $type plate(s)" );

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
SELECT
 p.id AS project_id,
 p.htgt_project_id,
 p.gene_id,
 p.targeting_type,
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
AND p.species_id     = 'Mouse'
)
SELECT
 pr.project_id,
 pr.htgt_project_id,
 s.design_gene_id AS gene_id,
 s.design_gene_symbol AS gene_symbol,
 s.final_pick_plate_name AS tv_plate_name,
 s.final_pick_well_name AS tv_well_name,
 s.final_pick_well_id AS tv_well_id,
 s.final_pick_well_accepted AS tv_accepted,
 s.ep_plate_name AS ep_plate_name,
 s.ep_well_name AS ep_well_name,
 s.ep_well_id AS ep_well_id,
 s.ep_pick_plate_name AS clone_plate_name,
 s.ep_pick_well_name AS clone_well_name,
 s.ep_pick_well_id AS clone_well_id,
 s.ep_pick_well_accepted AS clone_accepted
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
AND s.final_pick_well_id > 0
GROUP BY
 pr.project_id,
 pr.htgt_project_id,
 s.design_gene_id,
 s.design_gene_symbol,
 s.final_pick_plate_name,
 s.final_pick_well_name,
 s.final_pick_well_id,
 s.final_pick_well_accepted,
 s.ep_plate_name,
 s.ep_well_name,
 s.ep_well_id,
 s.ep_pick_plate_name,
 s.ep_pick_well_name,
 s.ep_pick_well_id,
 s.ep_pick_well_accepted
ORDER BY
 pr.project_id,
 s.design_gene_id,
 s.final_pick_well_id,
 s.ep_pick_well_id
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

    my %project_well_data;

    for my $datum ( @{ $query_results } ) {
        my $project_id = $datum->{project_id };
        push @{ $project_well_data{$project_id}{ws} }, $datum;

        if ( $datum->{htgt_project_id} && !exists $project_well_data{$project_id}{htgt_project_id} ) {
            $project_well_data{$project_id}{htgt_project_id} = $datum->{htgt_project_id};
        }

        if ( $datum->{gene_symbol} && !exists $project_well_data{$project_id}{gene} ) {
            $project_well_data{$project_id}{gene} = $datum->{gene_symbol};
        }

    }

    return \%project_well_data;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
