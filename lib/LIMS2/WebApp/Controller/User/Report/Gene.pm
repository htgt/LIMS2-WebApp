package LIMS2::WebApp::Controller::User::Report::Gene;
use Moose;
use Try::Tiny;
use namespace::autoclean;
use Date::Calc qw(Delta_Days);
use LIMS2::Model::Util::Crisprs qw( crisprs_for_design );
use LIMS2::Model::Util::CrisprESQCView qw( crispr_damage_type_for_ep_pick ep_pick_is_het );
use List::MoreUtils qw( uniq );
use Data::Dumper;
use LIMS2::Model;

BEGIN {extends 'Catalyst::Controller'; }

# Uncomment this to add time since last log entry to log output
#Log::Log4perl->easy_init( { level => 'DEBUG', layout => '%d [%P] %p %m (%R)%n' } );

=head1 NAME

LIMS2::WebApp::Controller::User::Report::Gene - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

# I'm going to assume all the designs for this gene are on the same chromosome!
has chromosome => (
    is => 'rw',
    isa => 'Str',
);

sub index :Path( '/user/report/gene' ) :Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'read' );

    $c->stash( template => "user/report/gene_summary_report.tt" );

    my $gene = $c->request->param( 'gene_id' )
        or return;

    my $species_id = $c->request->param('species') || $c->session->{selected_species};

    my $gene_info = try{ $c->model('Golgi')->find_gene( { search_term => $gene, species => $species_id } ) };

    # if we dont find a gene via solr index just search directly against the gene_design table
    my $gene_id;
    if ( $gene_info ) {
        $gene_id = $gene_info->{gene_id};
    }
    else {
        $gene_id = $gene;
        $gene_info->{gene_symbol} = $gene;
    }

    # fetch projects for this gene
    my @projects = $c->model('Golgi')->schema->resultset('Project')->search({
        gene_id  => $gene_id,
    });
    my $sponsor = join (', ', (map {$_->sponsor_ids} @projects) );

    # fetch designs for this gene
    # Uses WebAppCommon::Plugin::Design
    my $designs = $c->model('Golgi')->c_list_assigned_designs_for_gene( { gene_id => $gene_id, species => $species_id } );

    my $dispatch_fetch_values = {
        design     => \&fetch_values_for_type_design,
        int        => \&fetch_values_for_type_int,
        final      => \&fetch_values_for_type_final,
        final_pick => \&fetch_values_for_type_final_pick,
        dna        => \&fetch_values_for_type_dna,
        assembly   => \&fetch_values_for_type_assembly,
        ep         => \&fetch_values_for_type_ep,
        ep_pick    => \&fetch_values_for_type_ep_pick,
        xep        => \&fetch_values_for_type_xep,
        sep        => \&fetch_values_for_type_sep,
        sep_pick   => \&fetch_values_for_type_sep_pick,
        fp         => \&fetch_values_for_type_fp,
        piq        => \&fetch_values_for_type_piq,
        sfp        => \&fetch_values_for_type_sfp,
    };

    my @plate_types = ('design','int','final','final_pick','dna','assembly','ep','ep_pick','xep','sep','sep_pick','fp','sfp','piq');
    my @plate_types_rev = reverse @plate_types;

    my %designs_hash;
    my %wells_hash;

    # for each design fetch its summary table rows and build a hash of well details
    for my $design ( @{$designs} ) {

        my $design_id = $design->id;

        unless ( exists $designs_hash{ $design_id } ) {

            $self->_add_design_details( $design_id, $design, \%designs_hash );

        }

        # for each design fetch all rows from summaries table
        my $design_summaries_rs = $c->model('Golgi')->schema->resultset('Summary')->search(
           {
               'me.design_id'        => $design_id,
           },
        );

        if ($design_summaries_rs->count() > 0) {

            ROW: while ( my $summary_row = $design_summaries_rs->next ) {

                my $summary_id = $summary_row->id;

                # for each summary row append well data to hash rows depending on plate type, do not add if already exists in hash
                for my $curr_plate_type_id( @plate_types_rev ) {
                    my $row_complete = $dispatch_fetch_values->{ $curr_plate_type_id }->( $self, $summary_row, \%wells_hash, $c->model('Golgi'));
                    if($row_complete){
                        #$c->log->debug("Skipping plate types earlier than $curr_plate_type_id");
                        next ROW;
                    }
                }
            }
        }
    }

    # Add well data for the crispr plate types
    my @crispr_plate_types = qw(crispr crispr_vector crispr_dna);
    $self->_add_crispr_well_values($c->model('Golgi'), \%designs_hash, \%wells_hash);

    # created a hash that will contain the sorted data, from the wells_hash
    my %sorted_wells;
    foreach my $type (@plate_types, @crispr_plate_types) {
        if ($wells_hash{$type}) {
            my @sorted = sort { $a->{created_at} cmp $b->{created_at} ||
                                $a->{plate_name} cmp $b->{plate_name} ||
                                $a->{well_name} cmp $b->{well_name} }
                            values %{$wells_hash{$type}};
            $sorted_wells{$type} = \@sorted;
        }
    }

    # prepare data for the top Date Report
    my @timeline;
    my @designs_date;
    my $previous;
    my @product;

    # product type 'Designs' is separate and taken care here
    foreach my $key ( keys %designs_hash ) {
        push @designs_date, $designs_hash{$key}->{design_details}->{created_at};
    }
    @designs_date = sort(@designs_date);
    @product = ( 'Designs', $designs_date[0], $designs_date[-1] );
    $previous = $designs_date[0] // POSIX::strftime( "%Y-%m-%d", localtime() );
    # prepare the product type names
    my $names = {
        'design'     => 'Design Instances',
        'int'        => 'Intermediate Vectors',
        'final'      => 'Final Vectors',
        'final_pick' => 'Final Pick Vectors',
        'dna'        => 'DNA Preparations',
        'assembly'   => 'Assemblies',
        'ep'         => 'First Electroporations',
        'ep_pick'    => 'First Electroporation Picks',
        'xep'        => 'XEP Pools',
        'sep'        => 'Second Electroporations',
        'sep_pick'   => 'Second Electroporation Picks',
        'fp'         => 'First Electroporation Freezer Instances',
        'piq'        => 'Secondary QC',
        'sfp'        => 'Second Electroporation Freezes',
    };

    # all the other product types
    for my $plate_type( @plate_types ) {
        if ( $sorted_wells{$plate_type} ) {
            my $start = $sorted_wells{$plate_type}[0]->{created_at};
            my @start_array = split(/-/, $previous);
            my $end = $sorted_wells{$plate_type}[-1]->{created_at};
            my @end_array = split(/-/, $start);
            push @timeline, [@product, Delta_Days(@start_array, @end_array) ];
            @product = ( $names->{$plate_type}, $start, $end );
            $previous = $start;
        }
    }
    # print the last product, with the current date in transition time
    my @start_array = split(/-/, $previous);
    my @end_array = split(/-/, POSIX::strftime( "%Y-%m-%d", localtime() ) );
    push @timeline, [@product, Delta_Days(@start_array, @end_array) ];
    my $curr = POSIX::strftime( "%Y-%m-%d", localtime());

    my $crispr_qc = $self->crispr_qc_data( \%wells_hash );

    # Get experiments linked to gene
    #my $experiments = [ map { $_->as_hash } map { $_->experiments } @projects ];

    my $experiments = $self->_get_project_experiments(\@projects);

    my @all_crispr_vecs;
    if (defined $sorted_wells{crispr_vector}) {
        foreach my $vec (@{$sorted_wells{crispr_vector}}) {
            push @all_crispr_vecs, $vec->{crispr_id};
        }
    }
    my $crispr_ids_str = join ",", @all_crispr_vecs;

    $c->stash(
        'info'                 => $gene_info,
        'designs'              => \%designs_hash,
        'wells'                => \%wells_hash,
        'sorted_wells'         => \%sorted_wells,
        'all_crispr_vec_ids'   => $crispr_ids_str,
        'timeline'             => \@timeline,
        'sponsor'              => $sponsor,
        'crispr_qc'            => $crispr_qc,
        'experiments'          => $experiments,
    );

    return;
}

sub _get_project_experiments {
    my ( $self, $projects ) = @_;

    my @experiments;
    my $expr_proj;

    foreach my $proj (@$projects) {
        foreach my $exp ($proj->experiments) {
            my $experiment_id = $exp->id;
            if (grep {$_ eq $experiment_id} keys %$expr_proj) {
                push @{$expr_proj->{$experiment_id}}, $proj->id;
                next;
            }
            push @{$expr_proj->{$experiment_id}}, $proj->id;
            my $id_hash = {project_id => $expr_proj->{$experiment_id}};
            push @experiments, {$exp->get_columns, %$id_hash};
        }
    }

    return \@experiments;
}

sub _add_crispr_well_values {
    my ( $self, $model, $designs_hash, $wells_hash ) = @_;

    my @design_ids = keys %$designs_hash;
    my $summary = $model->get_crispr_summaries_for_designs({ id_list => \@design_ids, find_all_crisprs => 1 });
    foreach my $design_id (keys %$summary){
        my $design_summary = $summary->{ $design_id };
        $designs_hash->{$design_id}->{ design_details }->{ crispr_count }
            = scalar(@{ $design_summary->{ all_crisprs } });
        $designs_hash->{$design_id}->{ design_details }->{ crispr_pair_count }
            = scalar(@{ $design_summary->{ all_pairs } });
        $designs_hash->{$design_id}->{ design_details }->{ crispr_group_count }
            = scalar(@{ $design_summary->{ all_groups } });

        foreach my $crispr_id (keys %{ $design_summary->{plated_crisprs} }){

            my $crispr_summary = $design_summary->{plated_crisprs}->{$crispr_id};
            foreach my $crispr_well_id (keys %{ $crispr_summary }){
                my $crispr_well = $model->retrieve_well({ id => $crispr_well_id });
                my $crispr_well_info = {
                    well_id_string => $crispr_well->as_string,
                    well_name      => $crispr_well->name,
                    plate_id       => $crispr_well->plate_id,
                    plate_name     => $crispr_well->plate_name,
                    created_at     => $crispr_well->created_at->ymd,
                    crispr_id      => $crispr_id,
                    design_id      => $design_id,
                };
                $wells_hash->{crispr}->{$crispr_well->as_string} = $crispr_well_info;

                my $crispr_well_id = $crispr_well->id;
                my $crispr_vector_rs = $crispr_summary->{$crispr_well_id}->{CRISPR_V};
                my $crispr_dna_rs = $crispr_summary->{$crispr_well_id}->{DNA};

                while (my $vector_well = $crispr_vector_rs->next){
                    my $vector_well_info = {
                        well_id        => $vector_well->id,
                        well_id_string => $vector_well->as_string,
                        well_name      => $vector_well->name,
                        plate_id       => $vector_well->plate_id,
                        plate_name     => $vector_well->plate_name,
                        created_at     => $vector_well->created_at->ymd,
                        is_accepted    => _accepted_as_text( $vector_well->is_accepted ),
                        crispr_id      => $crispr_id,
                        design_id      => $design_id,
                    };
                    $wells_hash->{crispr_vector}->{ $vector_well->as_string } = $vector_well_info;
                }

                while (my $dna_well = $crispr_dna_rs->next){
                    my $dna_well_info = {
                        well_id        => $dna_well->id,
                        well_id_string => $dna_well->as_string,
                        well_name      => $dna_well->name,
                        plate_id       => $dna_well->plate_id,
                        plate_name     => $dna_well->plate_name,
                        created_at     => $dna_well->created_at->ymd,
                        status_pass    => _status_as_text( $dna_well->well_dna_status ),
                        is_accepted    => _accepted_as_text( $dna_well->is_accepted ),
                        crispr_id      => $crispr_id,
                        design_id      => $design_id,
                    };
                    $wells_hash->{crispr_dna}->{ $dna_well->as_string } = $dna_well_info;
                }
            }
        }
    }
    return;
}

sub _add_design_details {
    my ( $self, $design_id, $design, $designs_hash ) = @_;

    $designs_hash->{ $design_id }->{ 'design_details' } = {
        'name'                    => $design->name,
        'design_type_id'          => $design->design_type_id,
        'created_by_name'         => $design->created_by->name,
        'created_at'              => $design->created_at->ymd,
        'validated_by_annotation' => $design->validated_by_annotation,
        'target_transcript'       => $design->target_transcript,
    };

    my %genes_in_design = ();
    for my $gene ( $design->genes ) {
        $genes_in_design{ $gene->id } = 1;
    }

    $designs_hash->{ $design_id }->{ 'design_details' }->{ 'genes' } = \%genes_in_design;

    return;
}

sub _status_as_text{
    my ($status) = @_;

    if(defined $status){
        if ($status->pass){
            return 'pass';
        }
        else{
            return 'fail';
        }
    }
    else{
        return '';
    }
}

sub _accepted_as_text{
    my ($accepted) = @_;

    if(defined $accepted){
        if($accepted){
            return 'yes';
        }
        else{
            return 'no';
        }
    }
    else{
        return '';
    }

}

sub fetch_values_for_type_design {
    my ( $self, $summary_row, $wells_hash ) = @_;

    if ( defined $summary_row->design_well_id && $summary_row->design_well_id > 0 ) {

        my $plate_name     = $summary_row->design_plate_name;
        my $well_name      = $summary_row->design_well_name;
        my $well_id_string = $plate_name . '_' . $well_name;

        return 1 if exists $wells_hash->{ 'design' }->{ $summary_row->design_well_id };

        my $well_is_accepted;
        if ( $summary_row->design_well_accepted ) {
            $well_is_accepted = 'yes';
        }
        else {
            $well_is_accepted = 'no';
        }

        my $well_hash = {
            'well_id'        => $summary_row->design_well_id,
            'well_id_string' => $well_id_string,
            'plate_id'       => $summary_row->design_plate_id,
            'plate_name'     => $summary_row->design_plate_name,
            'well_name'      => $summary_row->design_well_name,
            'created_at'     => $summary_row->design_well_created_ts->ymd,
            'design_id'      => $summary_row->design_id,
            # 'recombineering_result' => $summary_row-> ?,    well.recombineering_result('rec_result').result
            'is_accepted'    => $well_is_accepted,
        };

        $wells_hash->{ 'design' }->{ $summary_row->design_well_id } = $well_hash;

    }
    return;
}

sub fetch_values_for_type_int {
    my ( $self, $summary_row, $wells_hash ) = @_;

    if ( defined $summary_row->int_well_id && $summary_row->int_well_id > 0 ) {

        my $plate_name     = $summary_row->int_plate_name;
        my $well_name      = $summary_row->int_well_name;
        my $well_id_string = $plate_name . '_' . $well_name;

        return 1 if exists $wells_hash->{ 'int' }->{ $summary_row->int_well_id };

        my $well_is_accepted;
        if ( $summary_row->int_well_accepted ) {
            $well_is_accepted = 'yes';
        }
        else {
            $well_is_accepted = 'no';
        }
        my $qc_seq_pass;
        if (defined $summary_row->int_qc_seq_pass){
            if ( $summary_row->int_qc_seq_pass ) {
                $qc_seq_pass = 'pass';
            }
            else {
                $qc_seq_pass = 'fail';
            }
        } else {
            $qc_seq_pass = '---';
        }

        my $well_hash = {
            'well_id'        => $summary_row->int_well_id,
            'well_id_string' => $well_id_string,
            'plate_id'       => $summary_row->int_plate_id,
            'plate_name'     => $summary_row->int_plate_name,
            'well_name'      => $summary_row->int_well_name,
            'created_at'     => $summary_row->int_well_created_ts->ymd,
            'cassette_name'  => $summary_row->int_cassette_name,
            'backbone_name'  => $summary_row->int_backbone_name,
            'recombinases'   => $summary_row->int_recombinase_id,
            'qc_seq_pass'    => $qc_seq_pass,
            'is_accepted'    => $well_is_accepted,
        };

        $wells_hash->{ 'int' }->{ $summary_row->int_well_id } = $well_hash;

    }
    return;
}

sub fetch_values_for_type_final {
    my ( $self, $summary_row, $wells_hash ) = @_;

    if ( defined $summary_row->final_well_id && $summary_row->final_well_id > 0 ) {

        my $plate_name     = $summary_row->final_plate_name;
        my $well_name      = $summary_row->final_well_name;
        my $well_id_string = $plate_name . '_' . $well_name;

        return 1 if exists $wells_hash->{ 'final' }->{ $summary_row->final_well_id };

        my $well_is_accepted;
        if ( $summary_row->final_well_accepted ) {
            $well_is_accepted = 'yes';
        }
        else {
            $well_is_accepted = 'no';
        }
        my $qc_seq_pass;
        if (defined $summary_row->final_qc_seq_pass){
            if ( $summary_row->final_qc_seq_pass ) {
                $qc_seq_pass = 'pass';
            }
            else {
                $qc_seq_pass = 'fail';
            }
        } else {
            $qc_seq_pass = '---';
        }

        my $well_hash = {
            'well_id'        => $summary_row->final_well_id,
            'well_id_string' => $well_id_string,
            'plate_id'       => $summary_row->final_plate_id,
            'plate_name'     => $summary_row->final_plate_name,
            'well_name'      => $summary_row->final_well_name,
            'created_at'     => $summary_row->final_well_created_ts->ymd,
            'cassette_name'  => $summary_row->final_cassette_name,
            'backbone_name'  => $summary_row->final_backbone_name,
            'recombinases'   => $summary_row->final_recombinase_id,
            'qc_seq_pass'    => $qc_seq_pass,
            'is_accepted'    => $well_is_accepted,
        };

        $wells_hash->{ 'final' }->{ $summary_row->final_well_id } = $well_hash;

    }
    return;
}

sub fetch_values_for_type_final_pick {
    my ( $self, $summary_row, $wells_hash ) = @_;

    if ( defined $summary_row->final_pick_well_id && $summary_row->final_pick_well_id > 0 ) {

        my $plate_name     = $summary_row->final_pick_plate_name;
        my $well_name      = $summary_row->final_pick_well_name;
        my $well_id_string = $plate_name . '_' . $well_name;

        return 1 if exists $wells_hash->{ 'final_pick' }->{ $summary_row->final_pick_well_id };

        my $well_is_accepted;
        if ( $summary_row->final_pick_well_accepted ) {
            $well_is_accepted = 'yes';
        }
        else {
            $well_is_accepted = 'no';
        }
        my $qc_seq_pass;
        if (defined $summary_row->final_pick_qc_seq_pass){
            if ( $summary_row->final_pick_qc_seq_pass ) {
                $qc_seq_pass = 'pass';
            }
            else {
                $qc_seq_pass = 'fail';
            }
        } else {
            $qc_seq_pass = '---';
        }

        my $well_hash = {
            'well_id'        => $summary_row->final_pick_well_id,
            'well_id_string' => $well_id_string,
            'plate_id'       => $summary_row->final_pick_plate_id,
            'plate_name'     => $summary_row->final_pick_plate_name,
            'well_name'      => $summary_row->final_pick_well_name,
            'created_at'     => $summary_row->final_pick_well_created_ts->ymd,
            'cassette_name'  => $summary_row->final_pick_cassette_name,
            'backbone_name'  => $summary_row->final_pick_backbone_name,
            'recombinases'   => $summary_row->final_pick_recombinase_id,
            'qc_seq_pass'    => $qc_seq_pass,
            'is_accepted'    => $well_is_accepted,
        };

        $wells_hash->{ 'final_pick' }->{ $summary_row->final_pick_well_id } = $well_hash;

    }
    return;
}

sub fetch_values_for_type_dna {
    my ( $self, $summary_row, $wells_hash ) = @_;

    if ( defined $summary_row->dna_well_id && $summary_row->dna_well_id > 0 ) {

        my $plate_name     = $summary_row->dna_plate_name;
        my $well_name      = $summary_row->dna_well_name;
        my $well_id_string = $plate_name . '_' . $well_name;

        return 1 if exists $wells_hash->{ 'dna' }->{ $summary_row->dna_well_id };

        my $well_is_accepted;
        if ( $summary_row->dna_well_accepted ) {
            $well_is_accepted = 'yes';
        }
        else {
            $well_is_accepted = 'no';
        }
        my $dna_status_pass;
        if (defined $summary_row->dna_status_pass){
            if ( $summary_row->dna_status_pass ) {
                $dna_status_pass = 'pass';
            }
            else {
                $dna_status_pass = 'fail';
            }
        } else {
            $dna_status_pass = '---';
        }
        my $final_pick_plate_name = $summary_row->final_pick_plate_name ? $summary_row->final_pick_plate_name : '' ;
        my $final_pick_well_name = $summary_row->final_pick_well_name ?  $summary_row->final_pick_well_name : '' ;
        my $final_pick_well = $final_pick_plate_name . '_' . $final_pick_well_name;

        my $well_hash = {
            'well_id'           => $summary_row->dna_well_id,
            'well_id_string'    => $well_id_string,
            'plate_id'          => $summary_row->dna_plate_id,
            'plate_name'        => $summary_row->dna_plate_name,
            'well_name'         => $summary_row->dna_well_name,
            'created_at'        => $summary_row->dna_well_created_ts->ymd,
            'final_pick_well'   => $final_pick_well,
            'quality'           => $summary_row->dna_quality,
            'quality_comment'   => $summary_row->dna_quality_comment,
            'status_pass'       => $dna_status_pass,
            'is_accepted'       => $well_is_accepted,
        };

        $wells_hash->{ 'dna' }->{ $summary_row->dna_well_id } = $well_hash;

    }
    return;
}

sub fetch_values_for_type_assembly {
    my ( $self, $summary_row, $wells_hash, $model ) = @_;

    if ( defined $summary_row->assembly_well_id && $summary_row->assembly_well_id > 0 ) {

        my $plate_name     = $summary_row->assembly_plate_name;
        my $well_name      = $summary_row->assembly_well_name;
        my $well_id      = $summary_row->assembly_well_id;
        my $well_id_string = $plate_name . '_' . $well_name;

        return 1 if exists $wells_hash->{ 'assembly' }->{ $summary_row->assembly_well_id };

        my $well_is_accepted;
        if ( $summary_row->assembly_well_accepted ) {
            $well_is_accepted = 'yes';
        }
        else {
            $well_is_accepted = 'no';
        }

        my $crispr_entity;
        my @exps;
        my $well = $model->schema->resultset('Well')->find( { id => $well_id } );
        if($summary_row->experiments){
            @exps = split ",",$summary_row->experiments;
        }
        if(@exps == 1){
            my $exp = $model->schema->resultset('Experiment')->find({ id => $exps[0] });
            $crispr_entity = $exp->crispr_entity;
        }
        else{
            $crispr_entity = $well->crispr_entity;
        }

        my $crispr_type = !$crispr_entity          ? 'NA'
                        : $crispr_entity->is_pair  ? 'crispr_pair'
                        : $crispr_entity->is_group ? 'crispr_group'
                        :                            'crispr';

        my $well_hash = {
            'well_id'        => $summary_row->assembly_well_id,
            'well_id_string' => $well_id_string,
            'plate_id'       => $summary_row->assembly_plate_id,
            'plate_name'     => $summary_row->assembly_plate_name,
            'well_name'      => $summary_row->assembly_well_name,
            'created_at'     => $summary_row->assembly_well_created_ts->ymd,
            'qc_verified'    => $well->assembly_well_qc_verified // '',
            'design_id'      => $well->design->id,
            'crispr_type'    => $crispr_type,
            'crispr_type_id' => $crispr_entity ? $crispr_entity->id : '',
            'gene_symbol'    => $summary_row->design_gene_symbol,
            'gene_ids'       => $summary_row->design_gene_id,
            'browser_target' => $plate_name . $well_name,

        };

        $wells_hash->{ 'assembly' }->{ $summary_row->assembly_well_id } = $well_hash;

    }
    return;
}

sub fetch_values_for_type_ep {
    my ( $self, $summary_row, $wells_hash, $model ) = @_;

    if ( defined $summary_row->ep_well_id && $summary_row->ep_well_id > 0 ) {
        my $plate_name     = $summary_row->ep_plate_name;
        my $well_name      = $summary_row->ep_well_name;
        my $well_id_string = $plate_name . '_' . $well_name;

        return 1 if exists $wells_hash->{ 'ep' }->{ $summary_row->ep_well_id };

        my $well_is_accepted;
        if ( $summary_row->ep_well_accepted ) {
            $well_is_accepted = 'yes';
        }
        else {
            $well_is_accepted = 'no';
        }
        my $final_pick_plate_name     = $summary_row->final_pick_plate_name ? $summary_row->final_pick_plate_name : '';
        my $final_pick_well_name      = $summary_row->final_pick_well_name ? $summary_row->final_pick_well_name : '';
        my $final_pick_well = $final_pick_plate_name . '_' . $final_pick_well_name;
        my $dna_plate_name     = $summary_row->dna_plate_name;
        my $dna_well_name      = $summary_row->dna_well_name;
        my $dna_well = $dna_plate_name . '_' . $dna_well_name;

        my $well_hash = {
            'well_id'           => $summary_row->ep_well_id,
            'well_id_string'    => $well_id_string,
            'plate_id'          => $summary_row->ep_plate_id,
            'plate_name'        => $summary_row->ep_plate_name,
            'well_name'         => $summary_row->ep_well_name,
            'created_at'        => $summary_row->ep_well_created_ts->ymd,
            'cell_line'         => $summary_row->crispr_ep_well_cell_line,
            'recombinases'      => $summary_row->ep_well_recombinase_id,
            'final_pick_well'   => $final_pick_well,
            'dna_well'          => $dna_well,
            'is_accepted'       => $well_is_accepted,
        };
        $wells_hash->{ 'ep' }->{ $summary_row->ep_well_id } = $well_hash;

    } elsif ( defined $summary_row->crispr_ep_well_id && $summary_row->crispr_ep_well_id > 0 ) {
        my $plate_name     = $summary_row->crispr_ep_plate_name;
        my $well_name      = $summary_row->crispr_ep_well_name;
        my $well_id        = $summary_row->crispr_ep_well_id;
        my $well_id_string = $plate_name . '_' . $well_name;

        return if exists $wells_hash->{ 'ep' }->{ $summary_row->crispr_ep_well_id };

        my $well_is_accepted;
        if ( $summary_row->crispr_ep_well_accepted ) {
            $well_is_accepted = 'yes';
        }
        else {
            $well_is_accepted = 'no';
        }
        my $final_pick_plate_name     = $summary_row->final_pick_plate_name ? $summary_row->final_pick_plate_name : '';
        my $final_pick_well_name      = $summary_row->final_pick_well_name ? $summary_row->final_pick_well_name : '';
        my $final_pick_well = $final_pick_plate_name . '_' . $final_pick_well_name;
        my $dna_plate_name     = $summary_row->dna_plate_name // '?';
        my $dna_well_name      = $summary_row->dna_well_name // '?';
        my $dna_well = $dna_plate_name . '_' . $dna_well_name;
        my $assembly_plate_name = $summary_row->assembly_plate_name ? $summary_row->assembly_plate_name : '';
        my $assembly_well_name  = $summary_row->assembly_well_name ? $summary_row->assembly_well_name : '';
        my $assembly_well = $assembly_plate_name . '_' . $assembly_well_name;

        # Fetch list of
        my @exps;
        my @crisprs;
        if($summary_row->experiments){
            @exps = split ",", $summary_row->experiments;
        }
        if(@exps == 1){
            my $exp = $model->schema->resultset('Experiment')->find( { id => $exps[0] } );
            @crisprs = map { $_->id } $exp->crisprs;
        }
        else{
            my $well = $model->retrieve_well( { id => $well_id } );
            @crisprs = map { $_->id } $well->crisprs;
        }

        my $well_hash = {
            'well_id'           => $summary_row->crispr_ep_well_id,
            'well_id_string'    => $well_id_string,
            'plate_id'          => $summary_row->crispr_ep_plate_id,
            'plate_name'        => $summary_row->crispr_ep_plate_name,
            'well_name'         => $summary_row->crispr_ep_well_name,
            'created_at'        => $summary_row->crispr_ep_well_created_ts->ymd,
            'cell_line'         => $summary_row->crispr_ep_well_cell_line,
            'recombinases'      => $summary_row->crispr_ep_well_nuclease,
            'crisprs'           => \@crisprs,
            'dna_well'          => $dna_well,
            'assembly_well'     => $assembly_well,
            'final_pick_well'   => $final_pick_well,
            'is_accepted'       => $well_is_accepted,
            'to_report'         => $summary_row->to_report,
        };

        $wells_hash->{ 'ep' }->{ $summary_row->crispr_ep_well_id } = $well_hash;

    }

    return;
}

sub fetch_values_for_type_ep_pick {
    my ( $self, $summary_row, $wells_hash, $model ) = @_;

    if ( defined $summary_row->ep_pick_well_id && $summary_row->ep_pick_well_id > 0 ) {

        my $plate_name     = $summary_row->ep_pick_plate_name;
        my $well_name      = $summary_row->ep_pick_well_name;
        my $well_id_string = $plate_name . '_' . $well_name;

        return 1 if exists $wells_hash->{ 'ep_pick' }->{ $summary_row->ep_pick_well_id };

        my $well_is_accepted;
        if ( $summary_row->ep_pick_well_accepted ) {
            $well_is_accepted = 'yes';
        }
        else {
            $well_is_accepted = 'no';
        }
        my $ep_plate_name     = $summary_row->ep_plate_name // $summary_row->crispr_ep_plate_name;
        my $ep_well_name      = $summary_row->ep_well_name // $summary_row->crispr_ep_well_name;
        my $ep_well = $ep_plate_name . '_' . $ep_well_name;

        my $chromosome = $self->chromosome;
        unless($chromosome){
            my $design = $model->schema->resultset('Design')->find({
                id => $summary_row->design_id,
            });

            my $species = $model->schema->resultset('Species')->find({ id => $summary_row->design_species_id});
            my $assembly_id = $species->default_assembly->assembly_id;
            my $design_oligo_locus = $design->oligos->first->search_related( 'loci', { assembly_id => $assembly_id } )->first;
            $chromosome = $design_oligo_locus->chr->name;
            $self->chromosome($chromosome);
        }

        my $is_het;
        my $damage_type;

        try {
            $damage_type = $summary_row->ep_pick_well_crispr_es_qc_well_call // '---';
            $is_het = ep_pick_is_het($model,$summary_row->ep_pick_well_id,$chromosome,$damage_type) // '---';
            if ( $is_het eq '1' ) {
                $is_het = 'yes';
            }
            elsif ( $is_het eq '0' ){
                $is_het = 'no';
            }
        };

        my $well_hash = {
            'well_id'           => $summary_row->ep_pick_well_id,
            'well_id_string'    => $well_id_string,
            'plate_id'          => $summary_row->ep_pick_plate_id,
            'plate_name'        => $summary_row->ep_pick_plate_name,
            'well_name'         => $summary_row->ep_pick_well_name,
            'created_at'        => $summary_row->ep_pick_well_created_ts->ymd,
            'recombinases'      => $summary_row->ep_pick_well_recombinase_id,
            'ep_well'           => $ep_well,
            'is_accepted'       => $well_is_accepted,
            'is_het'            => $is_het,
            'to_report'         => $summary_row->to_report,
            'damage_type'       => $damage_type,
        };

        if ( $summary_row->crispr_ep_well_id and $summary_row->ep_pick_well_accepted ) {
            $well_hash->{crispr_es_qc_well_id} = $summary_row->ep_pick_well_crispr_es_qc_well_id;
        }

        $wells_hash->{ 'ep_pick' }->{ $summary_row->ep_pick_well_id } = $well_hash;

    }
    return;
}

sub fetch_values_for_type_xep {
    my ( $self, $summary_row, $wells_hash ) = @_;

    if ( defined $summary_row->xep_well_id && $summary_row->xep_well_id > 0 ) {

        my $plate_name     = $summary_row->xep_plate_name;
        my $well_name      = $summary_row->xep_well_name;
        my $well_id_string = $plate_name . '_' . $well_name;

        return 1 if exists $wells_hash->{ 'xep' }->{ $summary_row->xep_well_id };

        my $fepd_plate_name = $summary_row->ep_pick_plate_name ? $summary_row->ep_pick_plate_name : '';
        my $fepd_well_name = $summary_row->ep_pick_well_name ? $summary_row->ep_pick_well_name : '';
        my $fepd_id_string = $fepd_plate_name . '_' . $fepd_well_name;
        my $ep_plate_name = $summary_row->ep_plate_name;
        my $ep_well_name = $summary_row->ep_well_name;
        my $ep_id_string = $ep_plate_name . '_' . $ep_well_name;

        my $fepd_parents = {$fepd_id_string => 1} ;
        my $ep_parents = {$ep_id_string => 1} ;

        my $well_hash = {
            'well_id'        => $summary_row->xep_well_id,
            'well_id_string' => $well_id_string,
            'plate_id'       => $summary_row->xep_plate_id,
            'plate_name'     => $summary_row->xep_plate_name,
            'well_name'      => $summary_row->xep_well_name,
            'fepd_parents'   => $fepd_parents,
            'ep_parents'     => $ep_parents,
            'created_at'     => $summary_row->xep_well_created_ts->ymd,
        };
        $wells_hash->{ 'xep' }->{ $summary_row->xep_well_id } = $well_hash;

    }
    return;
}

sub fetch_values_for_type_sep {
    my ( $self, $summary_row, $wells_hash ) = @_;

    if ( defined $summary_row->sep_well_id && $summary_row->sep_well_id > 0 ) {

        my $plate_name     = $summary_row->sep_plate_name;
        my $well_name      = $summary_row->sep_well_name;
        my $well_id_string = $plate_name . '_' . $well_name;

        return if exists $wells_hash->{ 'sep' }->{ $summary_row->sep_well_id };

        my $well_is_accepted;
        if ( $summary_row->sep_well_accepted ) {
            $well_is_accepted = 'yes';
        }
        else {
            $well_is_accepted = 'no';
        }

        my $final_pick_plate_name = $summary_row->final_pick_plate_name;
        my $final_pick_well_name = $summary_row->final_pick_well_name;

        my $first_fpick_id_string = '';
        my $second_fpick_id_string = '';

        if ( defined($summary_row->ep_plate_name) && $summary_row->final_pick_plate_name ) {
            $first_fpick_id_string = $final_pick_plate_name . '_' . $final_pick_well_name;
        } elsif ( !defined($summary_row->ep_plate_name) && $summary_row->final_pick_plate_name )  {
            $second_fpick_id_string = $final_pick_plate_name . '_' . $final_pick_well_name;
        }

        if ( !exists $wells_hash->{ 'sep' }->{ $summary_row->sep_well_id } ) {
            my $well_hash = {
                'well_id'        => $summary_row->sep_well_id,
                'well_id_string' => $well_id_string,
                'plate_id'       => $summary_row->sep_plate_id,
                'plate_name'     => $summary_row->sep_plate_name,
                'well_name'      => $summary_row->sep_well_name,
                'created_at'     => $summary_row->sep_well_created_ts->ymd,
                'first_fpick'    => $first_fpick_id_string,
                'second_fpick'   => $second_fpick_id_string,
                'is_accepted'    => $well_is_accepted,
            };

            $wells_hash->{ 'sep' }->{ $summary_row->sep_well_id } = $well_hash;

        } else {
            if ($first_fpick_id_string) {
                $wells_hash->{ 'sep' }->{ $summary_row->sep_well_id }->{'first_fpick'} = $first_fpick_id_string;
            }
            if ($second_fpick_id_string) {
                $wells_hash->{ 'sep' }->{ $summary_row->sep_well_id }->{'second_fpick'} = $second_fpick_id_string;
            }
        }
    }
    return;
}

sub fetch_values_for_type_sep_pick {
    my ( $self, $summary_row, $wells_hash ) = @_;

    if ( defined $summary_row->sep_pick_well_id && $summary_row->sep_pick_well_id > 0 ) {

        my $plate_name     = $summary_row->sep_pick_plate_name;
        my $well_name      = $summary_row->sep_pick_well_name;
        my $well_id_string = $plate_name . '_' . $well_name;

        return if exists $wells_hash->{ 'sep_pick' }->{ $summary_row->sep_pick_well_id };

        my $well_is_accepted;
        if ( $summary_row->sep_pick_well_accepted ) {
            $well_is_accepted = 'yes';
        }
        else {
            $well_is_accepted = 'no';
        }
        my $sep_plate_name     = $summary_row->sep_plate_name;
        my $sep_well_name      = $summary_row->sep_well_name;
        my $sep_well = $sep_plate_name . '_' . $sep_well_name;

        my $well_hash = {
            'well_id'           => $summary_row->sep_pick_well_id,
            'well_id_string'    => $well_id_string,
            'plate_id'          => $summary_row->sep_pick_plate_id,
            'plate_name'        => $summary_row->sep_pick_plate_name,
            'well_name'         => $summary_row->sep_pick_well_name,
            'created_at'        => $summary_row->sep_pick_well_created_ts->ymd,
            'recombinases'      => $summary_row->sep_pick_well_recombinase_id,
            'sep_well'          => $sep_well,
            'is_accepted'       => $well_is_accepted,
        };

        $wells_hash->{ 'sep_pick' }->{ $summary_row->sep_pick_well_id } = $well_hash;

    }
    return;
}

sub fetch_values_for_type_fp {
    my ( $self, $summary_row, $wells_hash ) = @_;

    if ( defined $summary_row->fp_well_id && $summary_row->fp_well_id > 0 ) {

        my $plate_name     = $summary_row->fp_plate_name;
        my $well_name      = $summary_row->fp_well_name;
        my $well_id_string = $plate_name . '_' . $well_name;

        return 1 if exists $wells_hash->{ 'fp' }->{ $summary_row->fp_well_id };

        my $well_is_accepted;
        if ( $summary_row->fp_well_accepted ) {
            $well_is_accepted = 'yes';
        }
        else {
            $well_is_accepted = 'no';
        }
        my $ep_plate_name     = $summary_row->ep_plate_name // $summary_row->crispr_ep_plate_name;
        my $ep_well_name      = $summary_row->ep_well_name // $summary_row->crispr_ep_well_name;
        my $ep_well = $ep_plate_name . '_' . $ep_well_name;
        my $ep_pick_plate_name     = $summary_row->ep_pick_plate_name;
        my $ep_pick_well_name      = $summary_row->ep_pick_well_name;
        my $ep_pick_well = $ep_pick_plate_name . '_' . $ep_pick_well_name;

        my $piq_well = '';
        if ( defined $summary_row->piq_plate_name ) {
            my $piq_plate_name     = $summary_row->piq_plate_name;
            my $piq_well_name      = $summary_row->piq_well_name;
            $piq_well = $piq_plate_name . '_' . $piq_well_name;
        }

        my $well_hash = {
            'well_id'           => $summary_row->fp_well_id,
            'well_id_string'    => $well_id_string,
            'plate_id'          => $summary_row->fp_plate_id,
            'plate_name'        => $summary_row->fp_plate_name,
            'well_name'         => $summary_row->fp_well_name,
            'created_at'        => $summary_row->fp_well_created_ts->ymd,
            'ep_well'           => $ep_well,
            'ep_pick_well'      => $ep_pick_well,
            'is_accepted'       => $well_is_accepted,
            'piq_well'          => $piq_well,
        };


        $wells_hash->{ 'fp' }->{ $summary_row->fp_well_id } = $well_hash;

    }
    return;
}

sub fetch_values_for_type_piq {
    my ( $self, $summary_row, $wells_hash, $model ) = @_;

    if ( defined $summary_row->piq_well_id && $summary_row->piq_well_id > 0 ) {

        my $plate_name     = $summary_row->piq_plate_name;
        my $well_name      = $summary_row->piq_well_name;
        my $well_id_string = $plate_name . '_' . $well_name;

        return 1 if exists $wells_hash->{ 'piq' }->{ $summary_row->piq_well_id };

        my $well_is_accepted;
        if ( $summary_row->piq_well_accepted ) {
            $well_is_accepted = 'yes';
        }
        else {
            $well_is_accepted = 'no';
        }

        my $fp_well = $model->schema->resultset('Well')->find({
            id => $summary_row->fp_well_id,
        });


        my $design = $model->schema->resultset('Design')->find({
            id => $summary_row->design_id,
        });

        my $species = $model->schema->resultset('Species')->find({ id => $summary_row->design_species_id});
        my $assembly_id = $species->default_assembly->assembly_id;
        my $design_oligo_locus = $design->oligos->first->search_related( 'loci', { assembly_id => $assembly_id } )->first;
        my $chromosome = $design_oligo_locus->chr->name;

        my $is_het;
        my $damage_type;

        try {
            $damage_type = $summary_row->piq_crispr_es_qc_well_call // '---';
            $is_het = ep_pick_is_het($model,$summary_row->piq_well_id,$chromosome,$damage_type) // '---';
            if ( $is_het eq '1' ) {
                $is_het = 'yes';
            }
            elsif ( $is_het eq '0' ){
                $is_het = 'no';
            }
        };

        my $well_hash = {
            'well_id'           => $summary_row->piq_well_id,
            'well_id_string'    => $well_id_string,
            'plate_id'          => $summary_row->piq_plate_id,
            'plate_name'        => $summary_row->piq_plate_name,
            'well_name'         => $summary_row->piq_well_name,
            'created_at'        => $summary_row->piq_well_created_ts->ymd,
            'fp_well'           => $fp_well->last_known_location_str,
            'is_het'            => $is_het,
            'is_accepted'       => $well_is_accepted,
            'ep_pick_well_id'   => $summary_row->ep_pick_well_id,
            'to_report'         => $summary_row->to_report,
            'damage_type'       => $damage_type,
        };

        if ( $summary_row->crispr_ep_well_id ) {
            $well_hash->{crispr_es_qc_well_id} = $summary_row->piq_crispr_es_qc_well_id;
        }

        $wells_hash->{ 'piq' }->{ $summary_row->piq_well_id } = $well_hash;

        # Ancestor PIQ is required for reporting
        if ( defined $summary_row->ancestor_piq_well_id && $summary_row->ancestor_piq_well_id > 0 ) {

            my $ancestor_plate_name = $summary_row->ancestor_piq_plate_name;
            my $ancestor_well_name = $summary_row->ancestor_piq_well_name;
            my $ancestor_well_id_string = $ancestor_plate_name . '_' . $ancestor_well_name;

            my $ancestor_well_is_accepted;
            if ( $summary_row->ancestor_piq_well_accepted ) {
                $ancestor_well_is_accepted = 'yes';
            }
            else {
                $ancestor_well_is_accepted = 'no';
            }

            undef $is_het;
            undef $damage_type;

            try {
                $damage_type = crispr_damage_type_for_ep_pick($model,$summary_row->ancestor_piq_well_id) // '---';
                $is_het = ep_pick_is_het($model,$summary_row->ancestor_piq_well_id,$chromosome,$damage_type) // '---';
                if ( $is_het eq '1' ) {
                    $is_het = 'yes';
                }
                elsif ( $is_het eq '0' ){
                    $is_het = 'no';
                }
            };

            unless ( exists $wells_hash->{ 'piq' }->{ $ancestor_well_id_string } ) {
                $well_hash = {
                    'well_id'           => $summary_row->ancestor_piq_well_id,
                    'well_id_string'    => $ancestor_well_id_string,
                    'plate_id'          => $summary_row->ancestor_piq_plate_id,
                    'plate_name'        => $summary_row->ancestor_piq_plate_name,
                    'well_name'         => $summary_row->ancestor_piq_well_name,
                    'created_at'        => $summary_row->ancestor_piq_well_created_ts->ymd,
                    'fp_well'           => $fp_well->last_known_location_str,
                    'is_accepted'       => $ancestor_well_is_accepted,
                    'is_het'            => $is_het,
                    'ep_pick_well_id'   => $summary_row->ep_pick_well_id,
                    'to_report'         => $summary_row->to_report,
                    'damage_type'       => $damage_type,
                };

                if ( $summary_row->crispr_ep_well_name ) {
                    my @qc_wells = $model->schema->resultset('CrisprEsQcWell')->search(
                        {
                            well_id  => $summary_row->ancestor_piq_well_id,
                            accepted => 1,
                        },
                    );

                    if ( my $accepted_qc_well = shift @qc_wells ) {
                        $well_hash->{crispr_es_qc_well_id} = $accepted_qc_well->id;
                    }
                }

                $wells_hash->{ 'piq' }->{ $summary_row->ancestor_piq_well_id } = $well_hash;
            }

        }

    }
    return;
}

sub fetch_values_for_type_sfp {
    my ( $self, $summary_row, $wells_hash ) = @_;

    if ( defined $summary_row->sfp_well_id && $summary_row->sfp_well_id > 0 ) {

        my $plate_name     = $summary_row->sfp_plate_name;
        my $well_name      = $summary_row->sfp_well_name;
        my $well_id_string = $plate_name . '_' . $well_name;

        my $sepd_plate_name     = $summary_row->sep_pick_plate_name;
        my $sepd_well_name      = $summary_row->sep_pick_well_name;
        my $sepd_well_id_string = $sepd_plate_name . '_' . $sepd_well_name;

        my $sep_plate_name     = $summary_row->sep_plate_name;
        my $sep_well_name      = $summary_row->sep_well_name;
        my $sep_well_id_string = $sep_plate_name . '_' . $sep_well_name;


        my $well_is_accepted;
        if ( $summary_row->sfp_well_accepted ) {
            $well_is_accepted = 'yes';
        }
        else {
            $well_is_accepted = 'no';
        }

        my $ep_id_string = '';

        if ( defined($summary_row->ep_plate_name)   ) {
            my $ep_plate_name     = $summary_row->ep_plate_name;
            my $ep_well_name      = $summary_row->ep_well_name;
            $ep_id_string = $ep_plate_name . '_' . $ep_well_name;
        }


        if ( !exists $wells_hash->{ 'sfp' }->{ $summary_row->sfp_well_id } ) {
            my $well_hash = {
                'well_id'        => $summary_row->sfp_well_id,
                'well_id_string' => $well_id_string,
                'plate_id'       => $summary_row->sfp_plate_id,
                'plate_name'     => $summary_row->sfp_plate_name,
                'well_name'      => $summary_row->sfp_well_name,
                'created_at'     => $summary_row->sfp_well_created_ts->ymd,
                'ep_well'        => $ep_id_string,
                'sep_well'       => $sep_well_id_string,
                'sepd_well'      => $sepd_well_id_string,
                'is_accepted'    => $well_is_accepted,
             };

             $wells_hash->{ 'sfp' }->{ $summary_row->sfp_well_id } = $well_hash;
        } else {
            if ($ep_id_string) {
                $wells_hash->{ 'sfp' }->{ $summary_row->sfp_well_id }->{'ep_well'} = $ep_id_string;
            }
        }

    }
    return;
}

sub crispr_qc_data {
    my ( $self, $wells_hash ) = @_;
    my @crispr_qc;

    return unless exists $wells_hash->{ep_pick};
    my $ep_picks = $wells_hash->{ep_pick};

    # build piq crispr qc
    my %piq_crispr_qc;
    if ( my $piq_wells = $wells_hash->{piq} ) {
        for my $piq_well ( keys %{ $piq_wells } ) {
            my $well_data = $piq_wells->{ $piq_well };
            next unless $well_data->{is_accepted} eq 'yes';
            push @{ $piq_crispr_qc{ $well_data->{ep_pick_well_id} } }, {
                qc_well_id => $well_data->{crispr_es_qc_well_id},
                piq_well => $well_data->{well_id_string},
                accepted => $well_data->{is_accepted},
            };
        }
    }

    for my $ep_pick ( keys %{ $ep_picks } ) {
        my $well_data = $ep_picks->{ $ep_pick };
        next unless $well_data->{is_accepted} eq 'yes';

        # ep_pick crispr qc
        my $well_id = $well_data->{well_id};
        next unless $well_data->{crispr_es_qc_well_id};

        # piq_crispr_qc
        if ( exists $piq_crispr_qc{ $well_id } ) {
            for my $piq_qc ( @{ $piq_crispr_qc{ $well_id } } ) {
                push @crispr_qc, {
                    epd_well     => $piq_qc->{well_id_string},
                    epd_qc_well_id => $well_data->{crispr_es_qc_well_id},
                    piq_qc_well_id => $piq_qc->{qc_well_id},
                    piq_well     => $piq_qc->{piq_well},
                    piq_accepted => $piq_qc->{accepted},
                    to_report    => $well_data->{to_report},
                };
            }
        }
        else {
            push @crispr_qc, {
                epd_well  => $well_data->{well_id_string},
                epd_qc_well_id => $well_data->{crispr_es_qc_well_id},
                to_report => $well_data->{to_report},
            };
        }

    }

    my @sorted = sort { $a->{epd_well} cmp $b->{epd_well} } @crispr_qc;
    return \@sorted;
}

=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
