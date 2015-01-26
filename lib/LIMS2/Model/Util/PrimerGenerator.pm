package LIMS2::Model::Util::PrimerGenerator;

use warnings FATAL => 'all';

use Moose;
use Try::Tiny;
use LIMS2::Model;
use Switch;
use Carp;
use Path::Class;
use Data::Dumper;

use LIMS2::Model::Util::OligoSelection qw(
        pick_crispr_primers
        pick_single_crispr_primers
);

with qw( MooseX::Log::Log4perl );

has model => (
    is => 'ro',
    isa => 'LIMS2::Model',
    lazy_build => 1,
);

sub _build_model {
	return LIMS2::Model->new( { user => 'lims2' } );
}

has plate_name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

# If not provided will process all wells in plate
has plate_well_names => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    required => 0,
    predicate => 'has_plate_well_names',
);

has wells => (
    is => 'ro',
    isa => 'ArrayRef[LIMS2::Model::Schema::Result::Well]',
    lazy_build => 1,
);

sub _build_wells {
    my $self = shift;
    my @wells;
    my $plate = $self->model->retrieve_plate({ name => $self->plate_name });

    if($self->has_plate_well_names){
        foreach my $well_name (@{ $self->plate_well_names }){
            push @wells, grep { $_->name =~ /$well_name/  } $plate->wells;
        }
    }
    else{
        @wells = $plate->wells;
    }
    return \@wells;
}

has well_ids => (
    is => 'ro',
    isa => 'ArrayRef[Int]',
    lazy_build => 1,
);

sub _build_well_ids {
	my $self = shift;

	my @well_ids = map { $_->id} @{ $self->wells };

	return \@well_ids;
}

has design_data_cache => (
    is => 'ro',
    isa => 'HashRef',
    lazy_build => 1,
);

sub _build_design_data_cache {
	my $self = shift;

    # FIXME: include results of get_short_arm_design_data_for_well_id_list (always or flag?)
	my $design_data_cache = $self->model->get_design_data_for_well_id_list( $self->well_ids );

    $self->update_gene_symbols($design_data_cache,$self->well_ids);

    return $design_data_cache;
}

has species_name => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

# Provide the specific assembly or default to SpeciesDefaultAssembly
has assembly_name => (
    is => 'ro',
    isa => 'Str',
    lazy_build => 1
);

sub _build_assembly_name {
	my $self = shift;

    my $assembly_r = $self->schema->resultset('SpeciesDefaultAssembly')->find( {
    	species_id => $self->species_name,
    } );

    return $assembly_r->assembly_id;
}

has crispr_type => (
    is => 'ro',
    isa => 'Str',
    default => 'pair',
);

has crispr_settings => (
    is => 'ro',
    isa => 'HashRef',
    lazy_build => 1,
);

sub _build_crispr_settings {
    my $self = shift;
    my $settings;
    if($self->crispr_type eq 'single'){
        $settings = {
            id_field => 'crispr_id',
            id_method => 'get_single_crispr_id',
            update_design_data_cache => 1,
            pick_primers_method => 'pick_single_crispr_primers',
        };
    }
    elsif($self->crispr_type eq 'pair'){
        $settings = {
            id_field => 'crispr_pair_id',
            id_method => 'get_crispr_pair_id',
            update_design_data_cache => 0,
            pick_primers_method => 'pick_crispr_primers',
        };
    }
    ## FIXME: groups ##
    return $settings;
}

# Might need format attribute in future

has repeat_mask => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    default => sub{ [ qw(NONE) ] },
);

has design_plate_names => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    required => 0,
);

has disambiguate_designs_cache => (
    is => 'ro',
    isa => 'Maybe[HashRef]',
    lazy_build => 1,
);

sub _build_disambiguate_designs_cache {
    my $self = shift;

    return undef unless $self->has_design_plate_names;

    $self->log->debug("Design plates list defined. Generating disambiguate designs cache");

    my @well_ids;

    foreach my $plate_name( @{ $self->design_plate_names }){
        my $plate = $self->model->retrieve_plate({ name => $plate_name });
        push @well_ids, map { $_->id } $plate->wells;
    }

    # FIXME: include results of get_short_arm_design_data_for_well_id_list (always or flag?)
    return $self->model->get_design_data_for_well_id_list( \@well_ids);
}

has crispr_pair_id => (
    is => 'ro',
    isa => 'Int',
    required => 0,
    predicate => 'has_crispr_pair_id',
);

has left_crispr_plate_name => (
    is => 'ro',
    isa => 'Str',
    required => 0,
    predicate => 'has_left_crispr_plate_name',
);

has right_crispr_plate_name => (
    is => 'ro',
    isa => 'Str',
    required => 0,
    predicate => 'has_right_crispr_plate_name',
);

has crispr_pair_id_cache => (
    is => 'ro',
    isa => 'Maybe[HashRef]',
    lazy_build => 1,
);

sub _build_crispr_pair_id_cache{
    my $self = shift;

    return undef unless ($self->has_left_crispr_plate_name and $self->has_right_crispr_plate_name);

    my $cache;

    my $left_crispr_plate = $self->model->retrieve_plate({ name => $self->left_crispr_plate_name})
       or die "Could not find left crispr plate ".$self->left_crispr_plate_name;
    my $right_crispr_plate = $self->model->retrieve_plate({ name => $self->right_crispr_plate_name})
       or die "Could not find right crispr plate ".$self->right_crispr_plate_name;

    $self->log->info("Building crispr pair ID cache");

    my @left_wells = $left_crispr_plate->wells;
    my @right_wells = $right_crispr_plate->wells;

    foreach my $left_well ( @left_wells) {
        my $left_crispr_data;
        my $left_process_crispr = $left_well->process_output_wells->first->process->process_crispr;
        if ( $left_process_crispr ) {
            $left_crispr_data = $left_process_crispr->crispr->as_hash;
        }
        my $right_crispr_data;
        my ($right_well) = grep { $_->name eq $left_well->name } @right_wells;

        my $right_process_crispr = $right_well->process_output_wells->first->process->process_crispr;
        if ( $right_process_crispr ) {
            $right_crispr_data = $right_process_crispr->crispr->as_hash;
        }

        my $left_crispr_id = $left_crispr_data->{'id'};
        my $right_crispr_id = $right_crispr_data->{'id'};

        my $crispr_pair = $self->model->schema->resultset( 'CrisprPair' )->find({
           'left_crispr_id' => $left_crispr_id,
           'right_crispr_id' => $right_crispr_id,
        });

        $cache->{$left_well->name} = $crispr_pair->id;
    }
    return $cache;

}

has persist_db => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
);

has persist_file => (
    is => 'ro',
    isa => 'Bool',
    default => 1,
);

# By default do not update existing database entries
has update_existing => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
);

sub verify_and_update_design_data_cache{
    my ($self, $well_id, $crispr_id) = @_;

    # In a special edge case, the design data cache will not be populated
    # because designs were not added to the plate. We need to use the crispr locus data for each well
    # to backtrack and locate the design so that the design data cache can be populated.
    # Then we can process as normal.
    my $changed = 0;

    if ( ! exists $self->design_data_cache->{$well_id}->{'design_id'} ){
        $self->log->debug( 'No design id value found for well_id: ' . $well_id);
        # get the design for the crispr
        if ( my ($design_id, $gene_id ) = $self->get_design_for_single_crispr( $crispr_id ) ){
           $self->design_data_cache->{$well_id}->{'design_id'} = $design_id;
           $self->design_data_cache->{$well_id}->{'gene_id'} = $gene_id;
           $changed = 1;
        }
        else {
            $self->log->info( 'No design information found for well_id: ' . $well_id . 'crispr_id: ' . $crispr_id);
        }
    }

    if ($changed) {
        # update gene symbols
        $self->update_gene_symbols($self->design_data_cache, [ $well_id ]);
    }
    return;
}

sub get_design_for_single_crispr {
    my ($self,$crispr_id) = @_;


    my %crispr_data;
    my $crispr = $self->model->schema->retrieve_crispr({ id => $crispr_id });

    my $locus_count = $crispr->loci->count;
    if ($locus_count != 1 ) {
        $self->log->info('Found multiple loci for ' . $crispr_id);
        $self->log->info('Using first found locus' );
    }

    my $locus = $crispr->loci->first;
    $crispr_data{'chr_start'} = $locus->chr_start;
    $crispr_data{'chr_end'} = $locus->chr_end;
    # Do not use the crispr strand information! Use it from the design for the gene
    $crispr_data{'chr_id'} = $locus->chr_id;
    $crispr_data{'chr_name'} = $locus->chr->name;
    $crispr_data{'seq'} = $crispr->seq;


    my $design_rs = $self->model->schema->resultset('GenericDesignBrowser')->search( {},
        {
            bind => [
                $crispr_data{'chr_start'} - 2000,
                $crispr_data{'chr_end'} + 2000,
                $crispr_data{'chr_id'},
                $self->assembly_name,
            ],
        }
    );
    my $design_data;
    my @d_dis_well_keys = keys %{$self->disambiguate_designs_cache};
    my @d_dis_design_ids;
    foreach my $well_key ( @d_dis_well_keys ) {
        push @d_dis_design_ids, $self->disambiguate_designs_cache->{$well_key}->{'design_id'};
    }

    my @design_results;
    if ($design_rs->count > 1) {
        $self->log->warn('Multiple designs found for crispr_id: ' . $crispr_id);
        my $counter = 0;
        while ( my $row = $design_rs->next ) {
            $counter++;
            $self->log->warn($counter . ': Design id: ' . $row->design_id);
            # check which is the correct design in the disambiguation design hash
            my @design_matches = grep {
                $_ == $row->design_id
            } @d_dis_design_ids;
            if ( scalar @design_matches < 1 ) {
                $self->log->warn('No disambiguation designs match');
            }
            else {
                push @design_results, $row;
            }
        }
        # If there was only one design row use it, otherwise disambiguation failed.
        if (scalar @design_results > 1 ){
            $self->log->error('Disambiguation failed..');
            foreach my $design_r ( @design_results ) {
                $self->log->warn('Potential Design: ' . $design_r->design_id);
            }
            # FIXME: temp fudge to keep things going.
            $design_data = $design_results[0];
        }
        else {
            $design_data = $design_results[0];
        }
    }
    else {
        # There was only one design
        $design_data = $design_rs->first;
    }
    my $design_id = $design_data->design_id;
    my $gene_id = $design_data->gene_id;

    return $design_id, $gene_id
}

# We pass a design data cache to this because it might be the cache for the input plate
# or the design disambiguation plate (is it ever this??)
# We pass a list of well_ids so we can do the update for specific wells
sub update_gene_symbols{
    my ($self, $design_data_cache, $well_ids) = @_;

    my $gene_cache;

    foreach my $well_id (@{ $well_ids || [] }){
        my $gene_id = $design_data_cache->{$well_id}->{'gene_id'};
        my $gene_symbol;

        if ( $gene_id ) {
            if ( $gene_cache->{$gene_id} ) {
                $gene_symbol = $gene_cache->{$gene_id};
            }
            else {
                my $gene_name_hr = $self->model->find_gene( {search_term => $gene_id, species => $self->species_name});
                if ( $gene_name_hr ) {
                    $gene_symbol = $gene_name_hr->{'gene_symbol'};
                }
                else {
                    $gene_symbol = '-';
                }
                $gene_cache->{$gene_id} = $gene_symbol;
            }
        }
        else {
            $gene_symbol = '-';
        }
        $design_data_cache->{$well_id}->{'gene_symbol'} = $gene_symbol;
    }
    return;
}

sub generate_crispr_primers{
    my $self = shift;

    switch($self->crispr_type){
        case "single" { $self->generate_single_crispr_primers }
        case "pair" { $self->generate_crispr_pair_primers }
        case "group" { $self->generate_crispr_group_primers }
        else { $self->log->error("Crispr type ".$self->crispr_type." not supported") }
    }
}

sub generate_single_crispr_primers{
    my $self = shift;
    my %primer_clip;

    my $design_row;
    foreach my $well ( @{$self->wells} ) {
        my $well_id = $well->id;
        my $well_name = $well->name;

        my ($crispr_left, $crispr_right) = $well->left_and_right_crispr_wells;
        my $crispr_id = $crispr_left->crispr->id;

        $self->verify_and_update_design_data_cache( $well_id, $crispr_id );

        my $design_id = $self->design_data_cache->{$well_id}->{'design_id'};
        my $gene_id = $self->design_data_cache->{$well_id}->{'gene_id'};
        my $gene_name = $self->design_data_cache->{$well_id}->{'gene_symbol'};
        $self->log->info( "$design_id\t$gene_name\tcrispr_id:\t$crispr_id" );

        if ( my @primers = $self->get_existing_crispr_primers({ crispr_id => $crispr_id }) ){
            $self->log->warn( '++++++++ primers already exist for crispr_id: ' . $crispr_id );
            # TODO: Add code to alter persistence behaviour
        }
        else {
            $self->log->info( '-------- primers not available in the database' );
        }


        my ($crispr_results, $crispr_primers, $chr_strand, $chr_seq_start) = LIMS2::Model::Util::OligoSelection::pick_single_crispr_primers(
                $self->model, {
                design_id => $design_id,
                crispr_id => $crispr_id,
                species => $self->species_name,
                repeat_mask => $self->repeat_mask,
            });
        $primer_clip{$well_name}{'crispr_id'} = $crispr_id;
        $primer_clip{$well_name}{'gene_name'} = $gene_name;
        $primer_clip{$well_name}{'design_id'} = $design_id;
        $primer_clip{$well_name}{'strand'} = $chr_strand;

        $primer_clip{$well_name}{'crispr_seq'} = $crispr_results;
        $primer_clip{$well_name}{'crispr_primers'} = $crispr_primers;
        $primer_clip{$well_name}{'chr_seq_start'} = $chr_seq_start;
    }

    my @out_rows;
    my $rank = 0; # always show the rank 0 primer
    my $primer_type = 'crispr_primers';
    foreach my $well_name ( keys %primer_clip ) {
        my @out_vals = (
            $well_name,
            $primer_clip{$well_name}{'gene_name'},
            $primer_clip{$well_name}{'design_id'},
            $primer_clip{$well_name}{'strand'},
            $primer_clip{$well_name}{'crispr_id'},
        );
        push (@out_vals, (
            $self->data_to_push(\%primer_clip, $primer_type, $well_name, 'left', $rank // '99')
        ));
        $self->persist_seq_primers('SF1', \%primer_clip, $primer_type, $well_name, 'left', $rank // '99');
        push (@out_vals, (
            $self->data_to_push(\%primer_clip, $primer_type, $well_name, 'right', $rank // '99')
        ));
        $self->persist_seq_primers('SR1', \%primer_clip, $primer_type, $well_name, 'right', $rank // '99');
        push (@out_vals,
            $primer_clip{$well_name}->{'crispr_seq'}->{'left_crispr'}->{'id'},
            $primer_clip{$well_name}->{'crispr_seq'}->{'left_crispr'}->{'seq'},
        );
        my $csv_row = join( ',' , @out_vals);
        push @out_rows, $csv_row;
    }

    $self->log->debug( 'Generating single crispr primer output file' );
    my $message = "Sequencing primers\n";
    $message .= "WARNING: These primers are for sequencing a PCR product - no genomic check has been applied to these primers\n";
    my $lines = $self->generate_primer_output( $self->crispr_type, $message, \@out_rows );
    $self->create_output_file( $self->plate_name . $self->formatted_well_names . '_single_crispr_primers.csv', $lines );
    return;
}

sub generate_crispr_pair_primers{
    my $self = shift;
    my %primer_clip;

    my $design_row;
    foreach my $well ( @{$self->wells} ) {
        my $well_id = $well->id;
        my $design_id = $self->design_data_cache->{$well_id}->{'design_id'};
        my $gene_id = $self->design_data_cache->{$well_id}->{'gene_id'};
        my $well_name = $well->name;
        my $gene_name;

        $gene_name = $self->design_data_cache->{$well_id}->{'gene_symbol'};

        my $crispr_pair_id;
        if ($self->has_crispr_pair_id) {
            $crispr_pair_id = $self->crispr_pair_id;
        }
        elsif ($self->crispr_pair_id_cache
                and $self->crispr_pair_id_cache->{$well_name}){
            $crispr_pair_id = $self->crispr_pair_id_cache->{$well_name};
        }
        elsif ($well->crispr_pair){
            $crispr_pair_id = $well->crispr_pair->id;
        }
        else{
            die "No crispr pair identified for well $well_name";
        }


        $self->log->info( "$design_id\t$gene_name\tcrispr_pair_id:\t$crispr_pair_id" );
        # Check whether there are already primers available for this crispr_pair_id
        if ( my @primers = $self->get_existing_crispr_primers({ crispr_pair_id => $crispr_pair_id }) ){
            $self->log->warn( '++++++++ primers already exist for crispr_pair_id: ' . $crispr_pair_id );
            # TODO: Add code to alter persistence behaviour
        }

        my ($crispr_results, $crispr_primers, $chr_strand, $chr_seq_start) = LIMS2::Model::Util::OligoSelection::pick_crispr_primers(
                $self->model,
                {
                    'design_id' => $design_id,
                    'crispr_pair_id' => $crispr_pair_id,
                    'species' => $self->species_name,
                    'repeat_mask' => $self->repeat_mask,
            });

        $primer_clip{$well_name}{'pair_id'} = $crispr_pair_id;
        $primer_clip{$well_name}{'gene_name'} = $gene_name;
        $primer_clip{$well_name}{'design_id'} = $design_id;
        $primer_clip{$well_name}{'strand'} = $chr_strand;

        $primer_clip{$well_name}{'crispr_seq'} = $crispr_results;
        $primer_clip{$well_name}{'crispr_primers'} = $crispr_primers;
        $primer_clip{$well_name}{'chr_seq_start'} = $chr_seq_start;
    }

    my @out_rows;
    my $csv_row;
    my $rank = 0; # always show the rank 0 primer
    my $primer_type = 'crispr_primers';
    foreach my $well_name ( keys %primer_clip ) {
        my @out_vals = (
            $well_name,
            $primer_clip{$well_name}{'gene_name'},
            $primer_clip{$well_name}{'design_id'},
            $primer_clip{$well_name}{'strand'},
            $primer_clip{$well_name}{'pair_id'},
        );
        if ( $primer_clip{$well_name}->{'crispr_primers'}->{'error_flag'} ne 'pass' ){
            push @out_vals
                , 'primer3_explain_left'
                , $primer_clip{$well_name}->{'crispr_primers'}->{'primer3_explain_left'}
                , 'primer3_explain_right'
                , $primer_clip{$well_name}->{'crispr_primers'}->{'primer3_explain_right'};

            $csv_row = join( ',' , @out_vals);
            push @out_rows, $csv_row;

            next;
        }

        push (@out_vals, (
            $self->data_to_push(\%primer_clip, $primer_type, $well_name, 'left', $rank // '99')
        ));
        $self->persist_seq_primers('SF1', \%primer_clip, $primer_type, $well_name, 'left', $rank // '99');
        push (@out_vals, (
            $self->data_to_push(\%primer_clip, $primer_type, $well_name, 'right', $rank // '99')
        ));
        $self->persist_seq_primers('SR1', \%primer_clip, $primer_type, $well_name, 'right', $rank // '99');
        push (@out_vals,
            $primer_clip{$well_name}->{'crispr_seq'}->{'left_crispr'}->{'id'},
            $primer_clip{$well_name}->{'crispr_seq'}->{'left_crispr'}->{'seq'},
        );
        push (@out_vals,
            $primer_clip{$well_name}->{'crispr_seq'}->{'right_crispr'}->{'id'},
            $primer_clip{$well_name}->{'crispr_seq'}->{'right_crispr'}->{'seq'},
        );
        $csv_row = join( ',' , @out_vals);
        push @out_rows, $csv_row;
    }

    $self->log->debug( 'Generating crispr pair primer output file' );
    my $message = "Sequencing primers\n";
    $message .= "WARNING: These primers are for sequencing a PCR product - no genomic check has been applied to these primers\n";
    my $lines = $self->generate_primer_output( $self->crispr_type, $message, \@out_rows );
    $self->create_output_file( $self->plate_name . $self->formatted_well_names . '_paired_crispr_primers.csv', $lines );
    return;
}

sub generate_crispr_group_primers{
    my $self = shift;
    $self->log->error("Crispr group primer generation not yet implemented");
}

sub get_existing_crispr_primers{
    my ($self, $search_atts) = @_;

    return $self->model->schema->resultset('CrisprPrimer')->search($search_atts)->all;
}

sub data_to_push {
    my $self = shift;
    my $pc = shift;
    my $primer_type = shift;
    my $well_name = shift;
    my $lr = shift;
    my $rank = shift;

    my $primer_name = $lr . '_' . $rank;
    return (
        $pc->{$well_name}->{$primer_type}->{$lr}->{$primer_name}->{'seq'} // "'-",
        $pc->{$well_name}->{$primer_type}->{$lr}->{$primer_name}->{'location'}->{'_strand'} // "'-",
        $pc->{$well_name}->{$primer_type}->{$lr}->{$primer_name}->{'length'} // "'-",
        $pc->{$well_name}->{$primer_type}->{$lr}->{$primer_name}->{'gc_content'} // "'-",
        $pc->{$well_name}->{$primer_type}->{$lr}->{$primer_name}->{'melting_temp'} // "'-",
    );
}

=head persist_primers

Write the calculated data to the store

=cut

sub persist_gen_primers {
    return persist_primers( @_, 'genotyping' );
}

sub persist_seq_primers {
    return persist_primers( @_, 'sequencing');
}

sub persist_pcr_primers {
    return persist_primers( @_, 'pcr');
}

sub persist_primers {
    my $self = shift;

    return unless $self->persist_db;

    my $model = $self->model;
    my $primer_label = shift;

    my $pc = shift;
    my $primer_type = shift;
    my $well_name = shift;
    my $lr = shift;
    my $rank = shift;
    my $assembly_id = $self->assembly_name;
    my $primer_class = shift;

    return if ( $rank eq '99'); # no suitable primers generated
    $self->log->info("Persisting $primer_class primers for well $well_name ...");
    my $primer_name = $lr . '_' . $rank;
    my $seq = $pc->{$well_name}->{$primer_type}->{$lr}->{$primer_name}->{'seq'};
    my $gc = $pc->{$well_name}->{$primer_type}->{$lr}->{$primer_name}->{'gc_content'};
    my $tm = $pc->{$well_name}->{$primer_type}->{$lr}->{$primer_name}->{'melting_temp'};
    my $chr_strand = $pc->{$well_name}->{$primer_type}->{$lr}->{$primer_name}->{'location'}->{'_strand'};
    my $chr_start = $pc->{$well_name}->{$primer_type}->{$lr}->{$primer_name}->{'location'}->{'_start'}
        + $pc->{$well_name}->{'chr_seq_start'} - 1;
    my $chr_end = $pc->{$well_name}->{$primer_type}->{$lr}->{$primer_name}->{'location'}->{'_end'}
        + $pc->{$well_name}->{'chr_seq_start'} - 1;
    my $chr_id = $pc->{$well_name}->{'crispr_seq'}->{'left_crispr'}->{'chr_id'}; # not the translated name
    if ( ! $chr_id ) {
    # Probably because we are only dealing with genotyping primers.
        $chr_id = $pc->{$well_name}->{'chr_id'};
    }

    my $crispr_primer_result;
    if ($primer_class eq 'genotyping' ) {
        if ( $seq ) {
            # There is no unique constraint on the GenotypingPrimer resultset.
            # Therefore, check whether this combination already exists before updating
            # the table
            # This must be done in a transaction to prevent a race condition
            my $coderef = sub {
                my $crispr_primer_result_set =
                    $model->schema->resultset( 'GenotypingPrimer' )->search({
                            'design_id' => $pc->{$well_name}->{design_id},
                            'genotyping_primer_type_id' => $primer_label,
                        });
                if ($crispr_primer_result_set->count == 0 ) {
                    $crispr_primer_result = $model->schema->resultset('GenotypingPrimer')->create({
                    'design_id'      => $pc->{$well_name}->{'design_id'},
                    'genotyping_primer_type_id'
                                     => $primer_label,
                    'seq'            => $seq,
                    'tm'             => $tm ,
                    'gc_content'     => $gc,
                        'genotyping_primer_loci' => [{
                             "assembly_id" => $assembly_id,
                             "chr_id" => $chr_id,
                             "chr_start" => $chr_start,
                             "chr_end" => $chr_end,
                             "chr_strand" => $chr_strand,
                         }],
                    });
                }
                else {
                    $self->log->warn('Genotyping design/primer already exists: '
                        . $pc->{$well_name}->{design_id}
                        . '/'
                        . $primer_label
                    );
                }
                return $crispr_primer_result;
            };
            #
            my $rs;
            try {
                $rs = $model->schema->txn_do( $coderef );
            } catch {
                my $error = shift;
                # Transaction failed
                die 'Something went wrong with that transaction: ' . $error;
            };
        }

    }
    else { # it must be sequencing or pcr
        if ( $seq ) {
            my $create_params = {
                'primer_name'    => $primer_label,
                'primer_seq'     => $seq,
                'tm'             => $tm ,
                'gc_content'     => $gc,
                    'crispr_primer_loci' => [{
                         "assembly_id" => $assembly_id,
                         "chr_id" => $chr_id,
                         "chr_start" => $chr_start,
                         "chr_end" => $chr_end,
                         "chr_strand" => $chr_strand,
                     }],
            };
            my $search_params = ();
            if ( $pc->{$well_name}->{'pair_id'} ) {
                $create_params->{'crispr_pair_id'} = $pc->{$well_name}->{'pair_id'};
                $search_params->{'crispr_pair_id'} = $pc->{$well_name}->{'pair_id'};
            }
            else {
                $create_params->{'crispr_id'} = $pc->{$well_name}->{'crispr_id'};
                $search_params->{'crispr_id'} = $pc->{$well_name}->{'crispr_id'};
            }
            # Can't use update_or_create, even though this is a 1-1 relationship, dbix thinks it is multi.
            # Therefore need to check whether exists and update it myself if it does, otherwise create a new
            # database tuple.
            $search_params->{'primer_name'} = $primer_label;
            my $coderef = sub {
                my $crispr_check_r = $model->schema->resultset('CrisprPrimer')->find( $search_params );
                $self->log->info( 'update_existing = ' . $self->update_existing );
                if ( $crispr_check_r && $self->update_existing ) {
                    $self->log->info( 'Deleting entry for '
                        . ($search_params->{'crispr_pair_id'} // $search_params->{'crispr_id'} )
                        . ' label: '
                        . $search_params->{'primer_name'}
                        . ' from the database');
                    if ( ! $crispr_check_r->delete ) {
                        $self->log->info( 'Unable to delete record(s) from the database' );
                        die;
                    }
                }
                $crispr_check_r = $model->schema->resultset('CrisprPrimer')->find( $search_params );
                if ( ! $crispr_check_r ) {
                    $crispr_primer_result = $model->schema->resultset('CrisprPrimer')->create( $create_params );
                    if ( ! $crispr_primer_result ) {
                        $self->log->info('Unable to create crispr primer records for '
                            . ($search_params->{'crispr_pair_id'} // $search_params->{'crispr_id'})
                            . ' label: '
                            . $search_params->{'primer_name'}
                        );
                    }
                    else {
                        $self->log->info('Created '
                            . ($search_params->{'crispr_pair_id'} // $search_params->{'crispr_id'})
                            . ' label: '
                            . $search_params->{'primer_name'}
                        );
                    }
                }
                else {
                        $self->log->info('Existing data prevented update - use the --update_data=YES parameter to override');
                }
                return $crispr_primer_result;
            };
            my $rs;
            try {
                $rs = $model->schema->txn_do( $coderef );
            } catch {
                my $error = shift;
                # Transaction failed
                die 'Something went wrong with that transaction: ' . $error;
            };
        }
    } # End if genotyping
#  print $crispr_primer->in_storage();  ## 1 (TRUE)
    return $crispr_primer_result;
}

sub generate_primer_output{
    my ($self, $primer_type, $message, $out_rows) = @_;

    my $header_method = {
        single => 'single_crispr_headers',
        pair   => 'crispr_pair_headers',
        group  => 'crispr_group_headers',
        pcr    => 'pcr_headers',
        genotyping => 'genotyping_headers',
    };

    my $method_name = $header_method->{$primer_type};
    my $headers = $self->$method_name;
    my $out = $message."\n";
    $out .= $$headers . "\n";

    foreach my $row ( sort @{$out_rows} ) {
         $out .= $row . "\n";
    }
    $out .= "End of File\n";
    return $out;
}

sub formatted_well_names{
    my $self = shift;
    my $formatted = '';
    if($self->has_plate_well_names){
        $formatted = '_' . join('_', @{ $self->plate_well_names });
    }
    return $formatted;
}

sub create_output_file {
    my ($self, $file_name, $lines) = @_;

    my $dir = Path::Class::Dir->new($ENV{'LIMS2_TEMP'} // '/var/tmp');
    my $file = $dir->file($file_name);

    $self->log->info("Creating file $file");

    my $tab_fh = $file->openw() or die "Can't open file $file for writing: $! \n";
    print $tab_fh $lines;
    close $tab_fh
        or croak "Unable to close $file after writing: $!";

    return;
}

sub single_crispr_headers {

    my @crispr_headings = (qw/
        well_name
        gene_symbol
        design_id
        strand
        crispr_id
        SF1
        SF1_strand
        SF1_length
        SF1_gc_content
        SF1_tm
        SR1
        SR1_strand
        SF1_length
        SR1_gc_content
        SR1_tm
        crispr_id
        crispr_seq
    /);

    my $headers = join ',', @crispr_headings;

    return \$headers;
}

sub crispr_pair_headers {

    my @crispr_headings = (qw/
        well_name
        gene_symbol
        design_id
        strand
        crispr_pair_id
        SF1
        SF1_strand
        SF1_length
        SF1_gc_content
        SF1_tm
        SR1
        SR1_strand
        SF1_length
        SR1_gc_content
        SR1_tm
        crispr_left_id
        crispr_left_seq
        crispr_right_id
        crispr_right_seq
    /);

    my $headers = join ',', @crispr_headings;

    return \$headers;
}

sub pcr_headers {

    my @pcr_headings = (qw/
        well_name
        gene_symbol
        design_id
        strand
        PF1
        PF1_strand
        PF1_length
        PF1_gc_content
        PF1_tm
        PR1
        PR1_strand
        PF1_length
        PR1_gc_content
        PR1_tm
        PF2
        PF2_strand
        PF2_length
        PF2_gc_content
        PF2_tm
        PR2
        PR2_strand
        PF2_length
        PR2_gc_content
        PR2_tm
    /);

    my $headers = join ',', @pcr_headings;

    return \$headers;
}

sub genotyping_headers {

    my @genotyping_headings = (qw/
        well_name
        gene_symbol
        design_id
        strand
        GF1
        GF1_strand
        GF1_length
        GF1_gc_content
        GF1_tm
        GR1
        GR1_strand
        GF1_length
        GR1_gc_content
        GR1_tm
        GF2
        GF2_strand
        GF2_length
        GF2_gc_content
        GF2_tm
        GR2
        GR2_strand
        GF2_length
        GR2_gc_content
        GR2_tm
        Design_A
        Oligo_A
        Design_B
        Oligo_B
    /);

    my $headers = join ',', @genotyping_headings;

    return \$headers;
}

1;
