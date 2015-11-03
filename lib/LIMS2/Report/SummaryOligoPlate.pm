package LIMS2::Report::SummaryOligoPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::SummaryOligoPlate::VERSION = '0.350';
}
## use critic


use warnings;
use strict;

use Moose;
use Log::Log4perl qw(:easy);
use namespace::autoclean;
use List::MoreUtils qw( uniq all );
use Try::Tiny;

extends qw( LIMS2::ReportGenerator );

has species => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has plate_name => (
    is       => 'ro',
    isa      => 'Str',
    required => 0
);

has '+param_names' => (
    default => sub { [ 'species' ] }
);

override _build_name => sub {
    my $self = shift;
    if ( $self->plate_name ) {
        return 'Summary by Well for Oligo Plate '. $self->plate_name;
    } else {
        return 'Summary by Oligo Plate';
    }
};

override _build_columns => sub {
    my $self = shift;

    if ( $self->plate_name ) {
        return [
            'Well',
            'Design ID',
            'Gene ID',
            'Gene Symbol',
            'crispr design oligos',
            'crispr vectors',
            'DNA crispr vectors',
            'DNA QC-passing crispr vectors',
            'DNA QC-passing crispr pairs',
            'DNA QC-passing crispr groups',
            'design oligos',
            "5'-PCR",
            "3'-PCR",
            'final vector clones',
            'QC-verified vectors',
            'DNA QC-passing vectors',
            'electroporations',
            'colonies picked',
            'targeted clones'
        ];
    } else {
        return [
            'Plate Name',
            'Gene Count',
            'Genes with crispr design oligos',
            'Genes with crispr vectors',
            'Genes with DNA crispr vectors',
            'Genes with DNA QC-passing crispr vectors',
            'Genes with DNA QC-passing crispr pairs',
            'Genes with DNA QC-passing crispr groups',
            'Genes with design oligos',
            "Genes with 5' and 3'-PCR passes",
            'Genes with final vector clones',
            'Genes with QC-verified vectors',
            'Genes with DNA QC-passing vectors',
            'Genes with electroporations',
            'Genes with colonies picked',
            'Genes with targeted clones'
        ];
    }
};

override iterator => sub {
    my ( $self ) = @_;

    my $data;

    if ( $self->plate_name ) {
        DEBUG "Well by Well report...";
        $data = $self->build_well_based_data ();
    } else {
        DEBUG "Plate by Plate report...";
        $data = $self->build_plate_based_data ();
    }


    return Iterator::Simple::iter( $data );

};


sub build_plate_based_data {
    my ( $self ) = @_;

    my $species = $self->species;

    my @rs = $self->model->schema->resultset( 'Plate' )->search({
            type_id => 'DESIGN',
            species_id => $self->species,
        }, {order_by => { -asc => 'name' }
    });

    my @data;
    foreach my $plate_rs (@rs) {
        my $design_name = $plate_rs->name;

        my $plate = $self->model->retrieve_plate( { id => $plate_rs->id } );

        my @design_list = get_designs_for_plate( $plate );

        my $row_data = $self->get_row_plate_by_plate( \@design_list ,$plate->name );
        unshift @{$row_data}, $plate->name;
        push @data, $row_data;

    }

    return \@data;

}




## no critic(ProhibitExcessComplexity)
sub get_row_plate_by_plate {
    my ($self, $design_list, $plate_name) = @_;


    my $search_condition = join(',', @{$design_list} );

    my $sql =  <<"SQL_END";
SELECT design_gene_id, design_id,
concat(design_plate_name, '_', design_well_name) AS DESIGN,
concat(int_plate_name, '_', int_well_name) AS INT,
concat(final_plate_name, '_', final_well_name, final_well_accepted) AS FINAL,
concat(dna_plate_name, '_', dna_well_name, dna_well_accepted) AS DNA,
concat(ep_plate_name, '_', ep_well_name) AS EP,
concat(crispr_ep_plate_name, '_', crispr_ep_well_name) AS CRISPR_EP,
concat(ep_pick_plate_name, '_', ep_pick_well_name, ep_pick_well_accepted) AS EP_PICK
FROM summaries where design_plate_name = '$plate_name' AND design_id IN ($search_condition) ORDER BY design_gene_id;
SQL_END


    # run the query
    my $results = $self->run_select_query( $sql );

    my ($gene_count, $gene_design_count, $pcr_count, $gene_final_count, $gene_final_pass_count, $gene_dna_pass_count, $gene_ep_count, $gene_ep_pick_count, $gene_ep_pick_pass_count) = (0, 0, 0, 0, 0, 0, 0, 0, 0);
    my ($gene_crispr_count, $gene_crispr_vector_count, $gene_crispr_dna_count, $gene_crispr_dna_accepted_count, $gene_crispr_pair_accepted_count, $gene_crispr_group_accepted_count) = (0, 0, 0, 0, 0, 0);

    # get the plates into arrays

    my $gene_id = @{$results}[0]->{design_gene_id};

    my (@design, @int, @final_info, @dna_info, @ep, @ep_pick_info, @design_ids);
    foreach my $row (@$results) {

        if ( $gene_id ne $row->{design_gene_id} ) {

            $gene_count++;
            $gene_id = $row->{design_gene_id};

            # DESIGN
            @design = uniq @design;
            if (scalar @design) {
                $gene_design_count++;
            };

            my $pcr_passes;
            foreach my $well (@design) {
                $well =~ s/^(.*?)_([a-z]\d\d)$/$2/i;

                my ($l_pcr, $r_pcr) = ('', '');
                try{
                    my $well_id = $self->model->retrieve_well( { plate_name => $plate_name, well_name => $well } )->id;

                    $l_pcr = $self->model->schema->resultset('WellRecombineeringResult')->find({
                        well_id     => $well_id,
                        result_type_id => 'pcr_u',
                    },{
                        select => [ 'result' ],
                    })->result;

                    $r_pcr = $self->model->schema->resultset('WellRecombineeringResult')->find({
                        well_id     => $well_id,
                        result_type_id => 'pcr_d',
                    },{
                        select => [ 'result' ],
                    })->result;
                }catch{
                    DEBUG "No pcr status found for well " . $well;
                };

                if ($l_pcr eq 'pass' && $r_pcr eq 'pass') {
                    $pcr_passes++;
                }
            }
            if ($pcr_passes) {
                $pcr_count++;
            }


            # FINAL / INT
            my ($final_count, $final_pass_count) = get_well_counts(\@final_info);

            if ($final_pass_count) {$gene_final_pass_count++};

            my $sum = 0;
            @int = uniq @int;

            foreach my $plate (@int) {
                $plate =~ s/^(.*?)(_[a-z]\d\d)$/$1/i;

                my $plate_id = $self->model->retrieve_plate({
                    name => $plate,
                })->id;

                my $comment = '';

                try{
                    $comment = $self->model->schema->resultset('PlateComment')->find({
                        plate_id     => $plate_id,
                        comment_text => { like => '% post-gateway wells planned for wells on plate ' . $plate }
                    },{
                        select => [ 'comment_text' ],
                    })->comment_text;
                }catch{
                    DEBUG "No comment found for plate " . $plate;
                };

                if ( $comment =~ m/(\d*) post-gateway wells planned for wells on plate / ) {
                    $sum += $1;
                }
            }
            if ($sum) {
                $final_count = $sum;
            }

            if ($final_count) {$gene_final_count++};

            # DNA
            my ($dna_count, $dna_pass_count) = get_well_counts(\@dna_info);
            if ($dna_pass_count) {$gene_dna_pass_count++};

            # EP/CRISPR_EP
            @ep = uniq @ep;
            if (scalar @ep) {$gene_ep_count++};

            # EP_PICK
            my ($ep_pick_count, $ep_pick_pass_count) = get_well_counts(\@ep_pick_info);
            if ($ep_pick_count) {$gene_ep_pick_count++};
            if ($ep_pick_pass_count) {$gene_ep_pick_pass_count++};

            # CRISPR PLATES
            @design_ids = uniq @design_ids;
            my ($crispr_count, $crispr_vector_count, $crispr_dna_count, $crispr_dna_accepted_count, $crispr_pair_accepted_count, $crispr_group_accepted_count) = $self->crispr_counts(\@design_ids);
            if ($crispr_count) {$gene_crispr_count++};
            if ($crispr_vector_count) {$gene_crispr_vector_count++};
            if ($crispr_dna_count) {$gene_crispr_dna_count++};
            if ($crispr_dna_accepted_count) {$gene_crispr_dna_accepted_count++};
            if ($crispr_pair_accepted_count) {$gene_crispr_pair_accepted_count++};
            if ($crispr_group_accepted_count) {$gene_crispr_group_accepted_count++};

            (@design_ids, @design, @final_info, @dna_info, @ep, @ep_pick_info) = ();
        }

        push @design_ids, $row->{design_id};
        push (@int, $row->{int}) unless ($row->{int} eq '_');
        push (@design, $row->{design}) unless ($row->{design} eq '_');
        push (@final_info, $row->{final}) unless ($row->{final} eq '_');
        push (@dna_info, $row->{dna}) unless ($row->{dna} eq '_');
        push (@ep, $row->{ep}) unless ($row->{ep} eq '_');
        push (@ep, $row->{crispr_ep}) unless ($row->{crispr_ep} eq '_');
        push (@ep_pick_info, $row->{ep_pick}) unless ($row->{ep_pick} eq '_');


    }

    # Last gene has all the arrays for counting on waiting... needs to be done out of the cycle
    $gene_count++;

    # DESIGN
    @design = uniq @design;
    if (scalar @design) {
        $gene_design_count++;
    };

    # FINAL
    my ($final_count, $final_pass_count) = get_well_counts(\@final_info);
    if ($final_count) {$gene_final_count++};
    if ($final_pass_count) {$gene_final_pass_count++};

    # DNA
    my ($dna_count, $dna_pass_count) = get_well_counts(\@dna_info);
    if ($dna_pass_count) {$gene_dna_pass_count++};

    # EP/CRISPR_EP
    @ep = uniq @ep;
    if (scalar @ep) {$gene_ep_count++};

    # EP_PICK
    my ($ep_pick_count, $ep_pick_pass_count) = get_well_counts(\@ep_pick_info);
    if ($ep_pick_count) {$gene_ep_pick_count++};
    if ($ep_pick_pass_count) {$gene_ep_pick_pass_count++};

    # CRISPR PLATES
    @design_ids = uniq @design_ids;
    my ($crispr_count, $crispr_vector_count, $crispr_dna_count, $crispr_dna_accepted_count, $crispr_pair_accepted_count, $crispr_group_accepted_count) = $self->crispr_counts(\@design_ids);
    if ($crispr_count) {$gene_crispr_count++};
    if ($crispr_vector_count) {$gene_crispr_vector_count++};
    if ($crispr_dna_count) {$gene_crispr_dna_count++};
    if ($crispr_dna_accepted_count) {$gene_crispr_dna_accepted_count++};
    if ($crispr_pair_accepted_count) {$gene_crispr_pair_accepted_count++};
    if ($crispr_group_accepted_count) {$gene_crispr_group_accepted_count++};


    # report the row of the genes with plates count

    my $data_row = [
        $gene_count,
        $gene_crispr_count,
        $gene_crispr_vector_count,
        $gene_crispr_dna_count,
        $gene_crispr_dna_accepted_count,
        $gene_crispr_pair_accepted_count,
        $gene_crispr_group_accepted_count,
        $gene_design_count,
        $pcr_count,
        $gene_final_count,
        $gene_final_pass_count,
        $gene_dna_pass_count,
        $gene_ep_count,
        $gene_ep_pick_count,
        $gene_ep_pick_pass_count,
    ];


    return $data_row;
}
## use critic


sub crispr_counts {
    my ($self, $design_ids) = @_;

    DEBUG "Fetching crispr counts";

    my $crispr_count = 0;
    my $crispr_vector_count = 0;
    my $crispr_dna_count = 0;
    my $crispr_dna_accepted_count = 0;
    my $crispr_pair_accepted_count = 0;
    my $crispr_group_accepted_count = 0;

    my $design_crispr_summary = $self->model->get_crispr_summaries_for_designs({ id_list => $design_ids });

    foreach my $design_id (@{$design_ids}) {
        my $plated_crispr_summary = $design_crispr_summary->{$design_id}->{plated_crisprs};
        my %has_accepted_dna;
        foreach my $crispr_id (keys %$plated_crispr_summary){
            my @crispr_well_ids = keys %{ $plated_crispr_summary->{$crispr_id} };
            $crispr_count += scalar( @crispr_well_ids );
            foreach my $crispr_well_id (@crispr_well_ids){

                # CRISPR_V well count
                my $vector_rs = $plated_crispr_summary->{$crispr_id}->{$crispr_well_id}->{CRISPR_V};
                $crispr_vector_count += $vector_rs->count;

                # DNA well counts
                my $dna_rs = $plated_crispr_summary->{$crispr_id}->{$crispr_well_id}->{DNA};
                $crispr_dna_count += $dna_rs->count;
                my @accepted = grep { $_->is_accepted } $dna_rs->all;
                $crispr_dna_accepted_count += scalar(@accepted);

                if(@accepted){
                    $has_accepted_dna{$crispr_id} = 1;
                }
            }
        }

        # Count pairs for this design which have accepted DNA for both left and right crisprs
        my $crispr_pairs = $design_crispr_summary->{$design_id}->{plated_pairs} || {};
        foreach my $pair_id (keys %$crispr_pairs){
            my $left_id = $crispr_pairs->{$pair_id}->{left_id};
            my $right_id = $crispr_pairs->{$pair_id}->{right_id};
            if ($has_accepted_dna{$left_id} and $has_accepted_dna{$right_id}){
                DEBUG "Crispr pair $pair_id accepted";
                $crispr_pair_accepted_count++;
            }
        }

        # Count groups for this design which have accepted DNA for all crisprs in group 
        my $crispr_groups = $design_crispr_summary->{$design_id}{plated_groups} || {};
        foreach my $group_id (keys %$crispr_groups){
            if ( all { $has_accepted_dna{$_} } @{ $crispr_groups->{$group_id} } ) {
                DEBUG "Crispr group $group_id accepted";
                $crispr_group_accepted_count++;
            }
        }
        DEBUG "crispr counts done";
    }

    return ($crispr_count, $crispr_vector_count, $crispr_dna_count, $crispr_dna_accepted_count, $crispr_pair_accepted_count, $crispr_group_accepted_count);
}


sub build_well_based_data {
    my ( $self ) = @_;

    my $plate = $self->model->retrieve_plate( { name => $self->plate_name } );

    my $plate_id = $plate->id;

    my @data;
    for my $well ( $plate->wells ) {

        my $design_id = $well->design->id;

        my $row_data = $self->get_row_well_by_well( [$design_id], $self->plate_name, $well->name );

        unshift @{$row_data}, $well->name, $design_id;
        push @data, $row_data;


    }

    return \@data;

}


## no critic(ProhibitExcessComplexity)
sub get_row_well_by_well {
    my ($self, $design_list, $plate_name, $well_name) = @_;

    my $search_condition = join(',', @{$design_list} );

    my $sql =  <<"SQL_END";
SELECT
design_gene_id, design_gene_symbol,
concat(design_plate_name, '_', design_well_name) AS DESIGN,
concat(int_plate_name, '_', int_well_name) AS INT,
concat(final_plate_name, '_', final_well_name, final_well_accepted) AS FINAL,
concat(dna_plate_name, '_', dna_well_name, dna_well_accepted) AS DNA,
concat(ep_plate_name, '_', ep_well_name) AS EP,
concat(crispr_ep_plate_name, '_', crispr_ep_well_name) AS CRISPR_EP,
concat(ep_pick_plate_name, '_', ep_pick_well_name, ep_pick_well_accepted) AS EP_PICK
FROM summaries where design_plate_name = '$plate_name' AND design_well_name = '$well_name' AND design_id IN ($search_condition);
SQL_END

    # run the query
    my $results = $self->run_select_query( $sql );

    # get the plates into arrays
    my (@gene_ids, @int, @gene_symbols, @design, @final_info, @dna_info, @ep, @ep_pick_info, @design_ids);
    foreach my $row (@$results) {
        push @gene_ids, $row->{design_gene_id};
        push @gene_symbols, $row->{design_gene_symbol};
        push @design_ids, $row->{design_id};
        push (@int, $row->{int}) unless ($row->{int} eq '_');
        push (@design, $row->{design}) unless ($row->{design} eq '_');
        push (@final_info, $row->{final}) unless ($row->{final} eq '_');
        push (@dna_info, $row->{dna}) unless ($row->{dna} eq '_');
        push (@ep, $row->{ep}) unless ($row->{ep} eq '_');
        push (@ep, $row->{crispr_ep}) unless ($row->{crispr_ep} eq '_');
        push (@ep_pick_info, $row->{ep_pick}) unless ($row->{ep_pick} eq '_');
    }

    # Gene info
    @gene_ids = uniq @gene_ids;
    my $gene_id = join(', ', @gene_ids );
    @gene_symbols = uniq @gene_symbols;
    my $gene_symbol = join(', ', @gene_symbols );

    # DESIGN
    @design = uniq @design;

    my ($l_pcr, $r_pcr) = ('', '');

    try{
        my $well_id = $self->model->retrieve_well( { plate_name => $plate_name, well_name => $well_name } )->id;

        $l_pcr = $self->model->schema->resultset('WellRecombineeringResult')->find({
            well_id     => $well_id,
            result_type_id => 'pcr_u',
        },{
            select => [ 'result' ],
        })->result;

        $r_pcr = $self->model->schema->resultset('WellRecombineeringResult')->find({
            well_id     => $well_id,
            result_type_id => 'pcr_d',
        },{
            select => [ 'result' ],
        })->result;
    }catch{
        DEBUG "No pcr status found for well " . $well_name;
    };

    # FINAL / INT
    my ($final_count, $final_pass_count) = get_well_counts(\@final_info);

    my $sum = 0;
    @int = uniq @int;

    foreach my $well (@int) {
        $well =~ s/^(.*?)(_[a-z]\d\d)$/$1/i;


        my $plate_id = $self->model->retrieve_plate({
            name => $well,
        })->id;

        my $comment = '';

        try{
            $comment = $self->model->schema->resultset('PlateComment')->find({
                plate_id     => $plate_id,
                comment_text => { like => '% post-gateway wells planned for wells on plate ' . $well }
            },{
                select => [ 'comment_text' ],
            })->comment_text;
        }catch{
            DEBUG "No comment found for well " . $well;
        };

        if ( $comment =~ m/(\d*) post-gateway wells planned for wells on plate / ) {
            $sum += $1;
        }
    }
    if ($sum) {
        $final_count = $sum;
    }

    # DNA
    my ($dna_count, $dna_pass_count) = get_well_counts(\@dna_info);

    # EP/CRISPR_EP
    @ep = uniq @ep;

    # EP_PICK
    my ($ep_pick_count, $ep_pick_pass_count) = get_well_counts(\@ep_pick_info);

    my ( $crispr_count, $crispr_vector_count, $crispr_dna_count, $crispr_dna_accepted_count,
        $crispr_pair_accepted_count, $crispr_group_accepted_count )
        = $self->crispr_counts($design_list);

    DEBUG "crispr counts done";

    my $data_row = [
        $gene_id,
        $gene_symbol,
        $crispr_count,
        $crispr_vector_count,
        $crispr_dna_count,
        $crispr_dna_accepted_count,
        $crispr_pair_accepted_count,
        $crispr_group_accepted_count,
        scalar @design,
        $l_pcr,
        $r_pcr,
        $final_count,
        $final_pass_count,
        $dna_pass_count,
        scalar @ep,
        $ep_pick_count,
        $ep_pick_pass_count,
    ];

    return $data_row;
}
## use critic


sub get_designs_for_plate {
    my $plate = shift;

    my @design_list;
    foreach my $well ( $plate->wells ) {
        push (@design_list, $well->design->id);
    }

    return uniq @design_list;

}


sub get_well_counts {
    my ($list) = @_;

    my (@well, @well_pass);
    foreach my $row ( @{$list} ) {
        if ( $row =~ m/(.*?)([^\d]*)$/ ) {
            my ($well_well, $well_well_pass) = ($1, $2);
            push (@well, $well_well);
            if ($well_well_pass eq 't') {
                push (@well_pass, $well_well);
            }
        }
    }
    @well = uniq @well;
    @well_pass = uniq @well_pass;

    return (scalar @well, scalar @well_pass);
}

# Generic method to run select SQL
sub run_select_query {
   my ( $self, $sql_query ) = @_;

   my $sql_result = $self->model->schema->storage->dbh_do(
      sub {
         my ( $storage, $dbh ) = @_;
         my $sth = $dbh->prepare( $sql_query );
         $sth->execute or die "Unable to execute query: $dbh->errstr\n";
         $sth->fetchall_arrayref({

         });
      }
    );

    return $sql_result;
}


__PACKAGE__->meta->make_immutable;

1;

__END__
