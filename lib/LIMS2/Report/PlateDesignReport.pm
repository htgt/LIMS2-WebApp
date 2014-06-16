package LIMS2::Report::PlateDesignReport;

use warnings;
use strict;

use Moose;
use Log::Log4perl qw(:easy);
use namespace::autoclean;
use List::MoreUtils qw( uniq );

use Smart::Comments;

extends qw( LIMS2::ReportGenerator );

has plate_name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has species => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has '+param_names' => (
    default => sub { [ 'plate_name' ] }
);



override _build_name => sub {
    my $self = shift;

    return 'Plate '. $self->plate_name .' well by well Report';
};

override _build_columns => sub {
    return [
        'Well',
        'Design ID',
        'Gene ID',
        'Gene Symbol',
        'crispr wells',
        'crispr vector wells',
        'crispr dna wells',
        'accepted crispr dna wells',
        'accepted crispr pairs',
        'design oligos',
        'final vector clones',
        'QC-verified vectors',
        'DNA QC-passing vectors',
        'electroporations',
        'colonies picked',
        'targeted clones'
    ];
};

override iterator => sub {
    my ( $self ) = @_;


    my $plate = $self->model->retrieve_plate( { name => $self->plate_name } );





    my $plate_id = $plate->id;
### $plate_id


    my @data;
    for my $well ( $plate->wells ) {
        my @row;

        my $design_id = $well->design->id;
        ### $design_id

        my $row_data = $self->get_row_for_design_list( [$design_id], $self->plate_name, $well->name );

        unshift @{$row_data}, $well->name, $design_id;
        push @data, $row_data;


    }



# my @data = (['1', '2', '3'], ['4', '5', '6']);


    return Iterator::Simple::iter( \@data );


};





sub get_row_for_design_list {
    my ($self, $design_list, $plate_name, $well_name) = @_;

    my $search_condition = join(',', @{$design_list} );
    ### $search_condition

    my $sql =  <<"SQL_END";
SELECT
design_gene_id, design_gene_symbol,
concat(design_plate_name, '_', design_well_name) AS DESIGN,
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
    my (@gene_ids, @gene_symbols, @design, @final_info, @dna_info, @ep, @ep_pick_info, @design_ids);
    foreach my $row (@$results) {
        push @gene_ids, $row->{design_gene_id};
        push @gene_symbols, $row->{design_gene_symbol};
        push @design_ids, $row->{design_id};
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

    # FINAL
    my ($final_count, $final_pass_count) = get_well_counts(\@final_info);

    # DNA
    my ($dna_count, $dna_pass_count) = get_well_counts(\@dna_info);

    # EP/CRISPR_EP
    @ep = uniq @ep;

    # EP_PICK
    my ($ep_pick_count, $ep_pick_pass_count) = get_well_counts(\@ep_pick_info);



    # Only used in the single targeted report... for now
    # if($self->targeting_type eq 'single_targeted'){
        # Get the crispr summary information for all designs found in previous gene loop
        # We do this after the main loop so we do not have to search for the designs for each gene again
        DEBUG "Fetching crispr summary info for report";
        my $design_crispr_summary = $self->model->get_crispr_summaries_for_designs({ id_list => $design_list });
        ## $design_crispr_summary
        DEBUG "Adding crispr counts to gene data";

        # add_crispr_well_counts_for_gene($gene_data, $designs_for_gene, $design_crispr_summary);


    my $crispr_count = 0;
    my $crispr_vector_count = 0;
    my $crispr_dna_count = 0;
    my $crispr_dna_accepted_count = 0;
    my $crispr_pair_accepted_count = 0;
    foreach my $design_id (@{$design_list}) {
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
    }



    DEBUG "crispr counts done";





    my $data_row = [
        $gene_id,
        $gene_symbol,
        $crispr_count,
        $crispr_vector_count,
        $crispr_dna_count,
        $crispr_dna_accepted_count,
        $crispr_pair_accepted_count,
        scalar @design,
        $final_count,
        $final_pass_count,
        $dna_pass_count,
        scalar @ep,
        $ep_pick_count,
        $ep_pick_pass_count,
    ];

    return $data_row;
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