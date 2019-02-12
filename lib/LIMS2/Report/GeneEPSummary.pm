package LIMS2::Report::GeneEPSummary;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::GeneEPSummary::VERSION = '0.527';
}
## use critic


use Moose;
use namespace::autoclean;
use Log::Log4perl qw( :easy );


extends qw( LIMS2::ReportGenerator );

has species => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has sponsor => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_sponsor'
);

has '+param_names' => (
    default => sub { [ 'species', 'sponsor' ] }
);

override _build_name => sub {
    return 'Gene Electroporation Summary';
};

override _build_columns => sub {
    return [
        'Row id',
        'Gene Symbol',
        'Design Id',
        'Sponsor',
        'Accepted Final DNA', # dna_ from summaries
        'Crispr DNA',
        'Assembly Wells', # with vector, left and right crispr DNA wells
        'EP wells', # crispr_ep from summaries with parent assembly well
        'Accepted EP pick wells', # ep_picks from summaries
    ];
};

has concat_str => (
    is      => 'rw',
    isa     => 'Str',
    default => ', ',
);

has any_accepted_attribute => (
    is      => 'rw',
    isa     => 'Str',
    default => "{ '=', [ 't', 'f', undef ] },",
);

has only_accepted_attribute => (
    is      => 'rw',
    isa     => 'Str',
    default => 't',
);

sub design_summary {
    my $self = shift;
    my $design_id = shift;

    my $summary_design = $self->model->schema->resultset('Summary')->search({
        'design_id' => $design_id,
    });

    return $summary_design;
}

sub final_dna_wells {
    my $self = shift;
    my $source_rs = shift;

    my $source_conditions = {
#        'dna_well_accepted' => eval($self->any_accepted_attribute),
         'dna_well_accepted' => $self->only_accepted_attribute,
    };

    my $other_conditions = {
        columns => [ qw/dna_plate_name dna_well_name/ ],
        distinct => 1,
        order_by => 'dna_plate_name, dna_well_name',
    };
    my $dna_data = $source_rs->search(
        $source_conditions,
        $other_conditions,
    );
    my $final_dna_wells;
    my @dna_wells;
    while ( my $dna_well = $dna_data->next ) {
        push @dna_wells, ($dna_well->dna_plate_name . '[' . $dna_well->dna_well_name . ']');
    }
    if ( scalar(@dna_wells) > 0 ) {
        $final_dna_wells = join( $self->concat_str, @dna_wells);
    }
    else {
        $final_dna_wells = 'None';
    }

    return $final_dna_wells;
}

sub final_dna_wells_as_hash {
    my $self = shift;
    my $source_rs = shift;

    my $source_conditions = {
#        'dna_well_accepted' => eval($self->any_accepted_attribute),
         'dna_well_accepted' => $self->only_accepted_attribute,
    };

    my $other_conditions = {
        'columns' => [ qw/dna_plate_name dna_well_name/ ],
        'distinct' => 1,
        'order_by' => 'dna_plate_name, dna_well_name',
        'result_class' => 'DBIx::Class::ResultClass::HashRefInflator',
    };
    my $dna_data = $source_rs->search(
        $source_conditions,
        $other_conditions,
    );
    my $final_dna_wells;
    my @dna_wells;
    while ( my $dna_well = $dna_data->next ) {
        push @dna_wells, ($dna_well->{dna_plate_name} . '[' . $dna_well->{dna_well_name} . ']');
    }
    if ( scalar(@dna_wells) > 0 ) {
        $final_dna_wells = join( $self->concat_str, @dna_wells);
    }
    else {
        $final_dna_wells = 'None';
    }

    return $final_dna_wells;
}


sub assembly_wells {
    my $self = shift;
    my $source_rs = shift;

    my $source_conditions = {
#        'assembly_well_accepted' => 't',
    };

    my $other_conditions = {
        columns => [ qw/assembly_well_id assembly_plate_name assembly_well_name/ ],
        distinct => 1,
        order_by => 'assembly_well_id, assembly_plate_name, assembly_well_name',
    };

    my $assembly_data = $source_rs->search(
        $source_conditions,
        $other_conditions,
    );

    my $assembly_wells;
    my @assembly_wells_list;
    while ( my $assembly_well_data = $assembly_data->next ) {
        if ( $assembly_well_data->assembly_well_id ) {
            my $assembly_well = $self->model->schema->resultset('Well')->find({ id => $assembly_well_data->assembly_well_id });
            my @crispr_wells = $assembly_well->parent_crispr_wells;
            my $assembly_details = $assembly_well_data->assembly_plate_name . '[' . $assembly_well_data->assembly_well_name . ']' . ':' . join( ':', map{ $_->as_string } @crispr_wells );
            push @assembly_wells_list, $assembly_details;
        }
    }
    if ( scalar(@assembly_wells_list) > 0 ) {
        $assembly_wells = join( $self->concat_str , @assembly_wells_list );
    }
    else {
        $assembly_wells = 'None';
    }

    return $assembly_wells;
}

sub assembly_wells_as_hash {
    my $self = shift;
    my $source_rs = shift;

    my $source_conditions = {
#        'assembly_well_accepted' => 't',
    };

    my $other_conditions = {
        columns => [ qw/assembly_well_id assembly_plate_name assembly_well_name/ ],
        distinct => 1,
        order_by => 'assembly_well_id, assembly_plate_name, assembly_well_name',
        'result_class' => 'DBIx::Class::ResultClass::HashRefInflator',
    };

    my $assembly_data = $source_rs->search(
        $source_conditions,
        $other_conditions,
    );

    my $assembly_wells;
    my @assembly_wells_list;
    while ( my $assembly_well_data = $assembly_data->next ) {
        if ( $assembly_well_data->{assembly_well_id} ) {
            my $assembly_well =  $self->model->schema->resultset('Well')->find({ id => $assembly_well_data->{assembly_well_id} });
            my @crispr_wells = $assembly_well->parent_crispr_wells;
            my $assembly_details = $assembly_well_data->{assembly_plate_name} . '[' . $assembly_well_data->{assembly_well_name} . ']' . ':' . join( ':', map{ $_->as_string } @crispr_wells );
            push @assembly_wells_list, $assembly_details;
        }
    }
    if ( scalar(@assembly_wells_list) > 0 ) {
        $assembly_wells = join( $self->concat_str , @assembly_wells_list );
    }
    else {
        $assembly_wells = 'None';
    }

    return $assembly_wells;
}

sub crispr_ep_wells {
    my $self = shift;
    my $source_rs = shift;
    my $search_conditions = shift; # hashref for dbic
    my $other_conditions = shift; # hashref for dbic

    my $crispr_data;

    $search_conditions = {
        -and => [
            'crispr_ep_plate_name' => { '!=', undef },
            'crispr_ep_well_name' => { '!=', undef },
        ],
    };

    $other_conditions = {
         columns => [ qw/crispr_ep_plate_name crispr_ep_well_name/ ],
         distinct => 1,
         order_by => 'crispr_ep_plate_name, crispr_ep_well_name',
    };

    if ( $search_conditions && $other_conditions) {
        $crispr_data = $source_rs->search(
            $search_conditions,
            $other_conditions,
        );
    }
    else {
        $crispr_data = $source_rs;
    }
    my $final_crispr_ep_wells;
    my @crispr_ep_wells;
    while ( my $crispr_ep_well = $crispr_data->next ) {
        if ( $crispr_ep_well->crispr_ep_plate_name && $crispr_ep_well->crispr_ep_well_name ) {
            push @crispr_ep_wells, ($crispr_ep_well->crispr_ep_plate_name . '[' . $crispr_ep_well->crispr_ep_well_name . ']');
        }
    }
    if (scalar (@crispr_ep_wells) > 0 ) {
        $final_crispr_ep_wells = join( $self->concat_str, @crispr_ep_wells);
    }
    else {
        $final_crispr_ep_wells = 'None';
    }

    return $final_crispr_ep_wells;
}

sub ep_pick_wells {
    my $self = shift;
    my $source_rs = shift;

    my $source_conditions = {
        'ep_pick_well_accepted' => 't',
    };
    my $other_conditions = {
        columns => [ qw/ep_pick_plate_name ep_pick_well_name/ ],
        distinct => 1,
        order_by => 'ep_pick_plate_name, ep_pick_well_name',
    };

    my $ep_pick_data = $source_rs->search(
        $source_conditions,
        $other_conditions,
    );


    my $ep_pick_wells;
    my @ep_wells;
    while ( my $ep_pick_well = $ep_pick_data->next ) {
        push @ep_wells, ($ep_pick_well->ep_pick_plate_name . '[' . $ep_pick_well->ep_pick_well_name . ']');
    }

    if (scalar (@ep_wells) > 0 ) {
        $ep_pick_wells = join( $self->concat_str, @ep_wells);
    }
    else {
        $ep_pick_wells = 'None';
    }

    return $ep_pick_wells;
}

sub crispr_acc_wells {
    my $self = shift;
    my $design_id = shift;

    my @crispr_design_wells = $self->model->get_crispr_wells_for_design( $design_id);
    my $crispr_acc_wells;
    if (scalar (@crispr_design_wells) > 0 ) {
        my @crispr_well_names;
        foreach my $crispr_well ( @crispr_design_wells ) {
            push @crispr_well_names, $crispr_well->plate_name . '[' . $crispr_well->well_name . ']';
        }
        $crispr_acc_wells = join($self->concat_str, @crispr_well_names);
    }
    else {
        $crispr_acc_wells = 'None';
    }

    return $crispr_acc_wells;
}

sub sponsor_list_as_string {
    my $self = shift;
    my $gene_id = shift;
    my $gene_hashref = shift;

    my $sponsors_arrayref = $gene_hashref->{$gene_id};

    my $sponsor_string = join(', ', @$sponsors_arrayref);

    return $sponsor_string;
}


override iterator => sub {
    my ( $self ) = @_;

    my @sponsors;
    ERROR ('Starting report generation for Gene Electroporation Summary (Human)');

    if ( $self->sponsor ne 'Sponsors' ) {
        @sponsors = ($self->sponsor);
    }
    else {
        if ($self->species eq 'Mouse') {
                @sponsors = ('Core', 'Syboss', 'Pathogens');
        }
        elsif ( $self->species eq 'Human') {
                @sponsors = ('All', 'Experimental Cancer Genetics', 'Mutation', 'Pathogen', 'Stem Cell Engineering', 'Transfacs');
        }
    }

    INFO( 'Sponsors: ' . (join ", ", @sponsors) );
    my $project_rs = $self->model->schema->resultset('Project')->search({
        'project_sponsors.sponsor_id' => { -in => [@sponsors] },
    },{
        prefetch => ['project_sponsors'],
    });
    INFO ( 'Project count: ' . $project_rs->count );

    my %gene_sponsor_hash;

    while (my $project = $project_rs->next) {
    # create list of genes
       push @{$gene_sponsor_hash{$project->gene_id}}, $project->sponsor_ids;
    }
    my @gene_list = keys %gene_sponsor_hash;
    my $gene_designs_rs = $self->model->schema->resultset('GeneDesign')->search({
        gene_id => { -in => [@gene_list] },
    },{
        select => [ 'design_id' ],
    });
    # Further restrict the design_id list by checking whether there are any rows for them in the summaries table
    #

    my @design_id_list;
    while ( my $gene_design = $gene_designs_rs->next ) {
        push @design_id_list, $gene_design->design_id;
    }
    INFO ( 'First pass design_id count: ' . scalar(@design_id_list) );
    my $summary_design_id_rs = $self->model->schema->resultset('Summary')->search({
            design_id => { -in => [@design_id_list] },
        },
        {
            select => [ 'design_id', 'design_gene_symbol' ],
            distinct => 1,
            order_by => 'design_gene_symbol',
        });
    INFO ( 'Summary design_id count: ' . $summary_design_id_rs->count );

    my $row_id =  0;
    return Iterator::Simple::iter sub {

        my $gene_design = $summary_design_id_rs->next
            or return;
        INFO ( 'Preparing row for design_id: ' . $gene_design->design_id);

        my @table_row;
        my $summary_design = $self->design_summary( $gene_design->design_id );

        my $gene_symbol;
        my $gene_id;

        if ($summary_design->count > 0) {
            push @table_row, ++$row_id;
            $gene_symbol = $summary_design->first->design_gene_symbol;
            $gene_id = $summary_design->first->design_gene_id;
            push @table_row,
                $gene_symbol;                                               # Gene
            push @table_row, $gene_design->design_id;                       # Design
            push @table_row, $self->sponsor_list_as_string(
                $gene_id, \%gene_sponsor_hash );                        # Sponsor

            push @table_row,
                $self->final_dna_wells_as_hash( $summary_design );
            push @table_row,
                $self->crispr_acc_wells( $gene_design->design_id );
            push @table_row,
                $self->assembly_wells( $summary_design );
            push @table_row,
                $self->crispr_ep_wells( $summary_design );
            push @table_row,
                $self->ep_pick_wells( $summary_design );
        }
        INFO ( join( '::', @table_row));

        return \@table_row;
    }

};

__PACKAGE__->meta->make_immutable;

1;

__END__
