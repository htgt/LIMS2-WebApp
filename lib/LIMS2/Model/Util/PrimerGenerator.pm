package LIMS2::Model::Util::PrimerGenerator;

use warnings FATAL => 'all';

use Moose;
use TryCatch;
use LIMS2::Model;
use Switch;
use Carp;
use Path::Class;
use Data::Dumper;
use LIMS2::Util::QcPrimers;
use Data::UUID;
use MooseX::Types::Path::Class::MoreCoercions qw/AbsDir/;

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
    isa => 'Maybe[HashRef]',
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
            file_suffix => '_single_crispr_primers.csv',
            primer_util_method => 'crispr_single_or_pair_genotyping_primers',
            primer_project_name => 'crispr_single_or_pair',
        };
    }
    elsif($self->crispr_type eq 'pair'){
        $settings = {
            id_field => 'crispr_pair_id',
            id_method => 'get_crispr_pair_id',
            update_design_data_cache => 0,
            file_suffix => '_paired_crispr_primers.csv',
            primer_util_method => 'crispr_single_or_pair_genotyping_primers',
            primer_project_name => 'crispr_single_or_pair',
        };
    }
    elsif($self->crispr_type eq 'group'){
        # FIXME: create generic crispr group project config instead of mgp_recovery??
        $settings = {
            id_field => 'crispr_group_id',
            id_method => 'get_crispr_group_id',
            update_design_data_cache => 0,
            file_suffix => '_group_crispr_primers.csv',
            primer_util_method => 'crispr_group_genotyping_primers',
            primer_project_name => 'mgp_recovery',
        };
    }
    elsif($self->crispr_type eq 'nonsense'){
        $settings = {
            id_field => 'crispr_id',
            id_method => 'get_single_crispr_id',
            update_design_data_cache => 0,
            file_suffix => '_nonsense_crispr_primers.csv',
            primer_util_method => 'crispr_single_or_pair_genotyping_primers',
            primer_project_name => 'nonsense_crispr_trial',
        };
    }
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

# Use this to store the crispr primers for later PCR primer generation
has crispr_primers => (
    is => 'rw',
    isa => 'HashRef',
    required => 0,
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

# By default do not overwrite existing database entries
has overwrite => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
);


# Build base dir if user has not specified one
has job_id => (
    is    => 'ro',
    isa   => 'Str',
    lazy_build => 1,
);

sub _build_job_id {
    return Data::UUID->new->create_str();
};

has base_dir => (
    is     => 'ro',
    isa    => 'Str',
    lazy_build => 1,
);

sub _build_base_dir {
    my $self = shift;
    my $report_dir = dir( $ENV{LIMS2_REPORT_DIR} );
    my $base_dir = $report_dir->subdir( $self->job_id );
    $base_dir->mkpath;
    return "$base_dir";
}

sub verify_and_update_design_data_cache{
    my ($self, $well_id, $crispr_id) = @_;

    # Skip this if design_data_cache is undef
    return unless $self->design_data_cache;

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

sub generate_design_genotyping_primers{
    my $self = shift;

    my $primer_util = LIMS2::Util::QcPrimers->new({
        model               => $self->model,
        primer_project_name => 'design_genotyping',
        base_dir            => $self->base_dir,
        persist_primers     => $self->persist_db,
        overwrite           => $self->overwrite,
    });

    # Hash to store primer db entries we generate
    my $well_db_primers = {};

    # Set up list of columns to use in output csv
    my @headings = qw(well_name gene_symbol design_id strand);
    my @primer_headings =  @{ $primer_util->get_output_headings};
    push @headings, @primer_headings;

    my @out_rows;
    my $heading_csv = join ",",@headings;
    push @out_rows, $heading_csv;

    foreach my $well ( @{$self->wells} ) {
        my $well_id = $well->id;
        my $well_name = $well->name;

        my $design_id = $self->design_data_cache->{$well_id}->{'design_id'};
        my $gene_id = $self->design_data_cache->{$well_id}->{'gene_id'};
        my $gene_name = $self->design_data_cache->{$well_id}->{'gene_symbol'};

        $self->log->info( "$design_id\t$gene_name" );

        my $design;
        try{
            $design = $self->model->c_retrieve_design({ id => $design_id });
        }
        catch($e){
            $self->log->debug("Could not find design $design_id in database - $e");
            next;
        }

        my ($primer_data, $seq, $db_primers) = $primer_util->design_genotyping_primers($design);
        $well_db_primers->{$well_id} = [ map { $_->as_hash } @$db_primers ];

        # generates field names and values using primer names (e.g. SF1, SR1) set in project
        # specific primer generation config files
        my $output_values = $primer_util->get_output_values($primer_data);
        $self->log->info("output values: ",Dumper($output_values));

        my $strand = 'FIXME'; # where to get chromosome strand from?
        my @out_vals = ($well_name, $gene_name, $design_id, $strand );

        push @out_vals, map { $output_values->{$_} // '' } @primer_headings;

        my $csv_row = join( ',' , @out_vals);
        push @out_rows, $csv_row;
    }

    $self->log->debug( 'Generating  '.$self->crispr_type.'crispr primer output file' );
    my $message = "Genotyping primers\n";
    $message .= "Genomic specificity check has been applied to these primers\n";
    my $file_path = $self->create_output_file( $self->plate_name . $self->formatted_well_names . "_genotyping_primers.csv", \@out_rows );

    return $file_path, $well_db_primers;
}

sub generate_crispr_primers{
    my $self = shift;

    my $settings = $self->crispr_settings;

    my $primer_util = LIMS2::Util::QcPrimers->new({
        model               => $self->model,
        primer_project_name => $settings->{primer_project_name},
        base_dir            => $self->base_dir,
        persist_primers     => $self->persist_db,
        overwrite           => $self->overwrite,
    });

    # Hash to store primer db entries we generate
    my $well_db_primers = {};

    # Set up list of columns to use in output csv
    my @headings = qw(well_name gene_symbol design_id strand);
    push @headings, $settings->{id_field};

    # Add primer project specific headings such as "SR1_gc_content"
    my @primer_headings = @{ $primer_util->get_output_headings};
    push @headings, @primer_headings;

    # Add extra crispr related headings
    if($self->crispr_type eq 'single'){
        push @headings, qw(crispr_id crispr_seq);
    }
    elsif($self->crispr_type eq 'pair'){
        push @headings, qw(crispr_left_id crispr_left_seq crispr_right_id crispr_right_seq);
    }

    my @out_rows;
    my $heading_csv = join ",",@headings;
    push @out_rows, $heading_csv;

    # Store crispr primers as we may need them later
    # in order to generate crispr PCR primers
    my $crispr_primers_by_well_id = {};

    foreach my $well ( @{$self->wells} ) {
        my $well_id = $well->id;
        my $well_name = $well->name;

        my $id_method_name = $settings->{id_method};
        my ($crispr_id, $crispr);
        try{
           ($crispr_id, $crispr) = $self->$id_method_name($well);
        }
        catch($e){
            $self->log->debug("Skipping crispr primer generation for well $well_name. Could not find crispr "
                .$self->crispr_type.". Error: $e");
            next;
        }

        if($settings->{update_design_data_cache}){
            $self->verify_and_update_design_data_cache( $well_id, $crispr_id );
        }

        my ($design_id, $gene_id, $gene_name) = ('','','');
        if($self->design_data_cache){
            $design_id = $self->design_data_cache->{$well_id}->{'design_id'};
            $gene_id = $self->design_data_cache->{$well_id}->{'gene_id'};
            $gene_name = $self->design_data_cache->{$well_id}->{'gene_symbol'};
        }

        $self->log->info( "$design_id\t$gene_name\t".$settings->{id_field}.":\t$crispr_id" );

        # Run primer generation using QcPrimers module
        my $util_method_name = $settings->{primer_util_method};
        my ($picked_primers, $seq, $db_primers) = $primer_util->$util_method_name($crispr);
        $well_db_primers->{$well_id} = [ map { $_->as_hash } @$db_primers ];

        # Store crispr primers for each well id
        $crispr_primers_by_well_id->{$well_id}->{primers} = $picked_primers;
        $crispr_primers_by_well_id->{$well_id}->{crispr} = $crispr;

        # generates field names and values using primer names (e.g. SF1, SR1) set in project
        # specific primer generation config files
        my $output_values = $primer_util->get_output_values($picked_primers);
        $self->log->info("output values: ",Dumper($output_values));

        my $strand = 'FIXME'; # where to get chromosome strand from?
        my @out_vals = ($well_name, $gene_name, $design_id, $strand, $crispr_id);

        push @out_vals, map { $output_values->{$_} // '' } @primer_headings;

        if($self->crispr_type eq 'single'){
            push @out_vals, $crispr->id, $crispr->seq;
        }
        elsif($self->crispr_type eq 'pair'){
            push @out_vals, $crispr->left_crispr_id, $crispr->left_crispr->seq,
                            $crispr->right_crispr_id, $crispr->right_crispr->seq;
        }

        my $csv_row = join( ',' , @out_vals);
        push @out_rows, $csv_row;

    }

    # Store crispr primers for later PCR primer generation
    $self->crispr_primers($crispr_primers_by_well_id);

    $self->log->debug( 'Generating  '.$self->crispr_type.'crispr primer output file' );
    my $message = "Sequencing primers\n";
    $message .= "WARNING: These primers are for sequencing a PCR product - no genomic check has been applied to these primers\n";

    my $file_path = $self->create_output_file( $self->plate_name . $self->formatted_well_names . $settings->{file_suffix}, \@out_rows );
    return $file_path, $well_db_primers;
}

sub generate_crispr_PCR_primers{
    my $self = shift;

    # If crispr primers have not yet been generated we need to run that first
    my $crispr_primers;
    unless ($crispr_primers = $self->crispr_primers){
        $self->generate_crispr_primers();
        $crispr_primers = $self->crispr_primers;
    }

    my $primer_util = LIMS2::Util::QcPrimers->new({
        model               => $self->model,
        primer_project_name => 'crispr_pcr',
        base_dir            => $self->base_dir,
        persist_primers     => $self->persist_db,
        overwrite           => $self->overwrite,
    });

    # Hash to store primer db entries we generate
    my $well_db_primers = {};

    # Set up list of columns to use in output csv
    my @headings = qw(well_name gene_symbol design_id strand);

    # Add primer project specific headings such as "SR1_gc_content"
    my @primer_headings = @{ $primer_util->get_output_headings};
    push @headings, @primer_headings;

    my @out_rows;
    my $heading_csv = join ",",@headings;
    push @out_rows, $heading_csv;

    foreach my $well ( @{$self->wells} ) {
        my $well_id = $well->id;
        my $well_name = $well->name;

        my ($design_id, $gene_id, $gene_name) = ('','','');
        if($self->design_data_cache){
            $design_id = $self->design_data_cache->{$well_id}->{'design_id'};
            $gene_id = $self->design_data_cache->{$well_id}->{'gene_id'};
            $gene_name = $self->design_data_cache->{$well_id}->{'gene_symbol'};
        }

        $self->log->info( "$design_id\t$gene_name" );

        my $well_crispr_primers = $crispr_primers->{$well_id}->{primers};
        unless($well_crispr_primers){
            $self->log->info("No crispr primers for well ID $well_id. Cannot generate PCR primers");
            next;
        }

        # Run primer generation using QcPrimers module
        my $crispr = $crispr_primers->{$well_id}->{crispr};
        my ($picked_primers, $seq, $db_primers) = $primer_util->crispr_PCR_primers($well_crispr_primers, $crispr);
        $well_db_primers->{$well_id} = [ map { $_->as_hash } @$db_primers ];

        # generates field names and values using primer names (e.g. SF1, SR1) set in project
        # specific primer generation config files
        my $output_values = $primer_util->get_output_values($picked_primers);
        $self->log->info("output values: ",Dumper($output_values));

        my $strand = 'FIXME'; # where to get chromosome strand from?
        my @out_vals = ($well_name, $gene_name, $design_id, $strand);

        push @out_vals, map { $output_values->{$_} // '' } @primer_headings;

        my $csv_row = join( ',' , @out_vals);
        push @out_rows, $csv_row;

    }

    $self->log->debug( 'Generating crispr PCR primer output file' );
    my $message = "PCR crispr region primers\n";
    $message .= "Genomic specificity check has been applied to these primers\n";
    my $file_path = $self->create_output_file( $self->plate_name . $self->formatted_well_names . '_pcr_primers.csv', \@out_rows );
    return $file_path, $well_db_primers;
}

sub get_single_crispr_id{
    my ($self, $well) = @_;
    my $plate_type = $well->plate->type_id;
    my ($crispr_left, $crispr_right);
    if($plate_type eq 'CRISPR' or $plate_type eq 'CRISPR_V'){
        # For single crispr we may be working on pre-assembly stage plate
        $crispr_left = $well;
    }
    else{
        # If post assembly use left_and_right_crispr_wells method
        ($crispr_left, $crispr_right) = $well->left_and_right_crispr_wells;
    }
    return ($crispr_left->crispr->id, $crispr_left->crispr);
}

sub get_crispr_pair_id{
    my ($self, $well) = @_;
    my $crispr_pair_id;
    my $crispr_pair;
    if ($self->has_crispr_pair_id) {
        $crispr_pair_id = $self->crispr_pair_id;
    }
    elsif ($self->crispr_pair_id_cache
            and $self->crispr_pair_id_cache->{$well->name}){
        $crispr_pair_id = $self->crispr_pair_id_cache->{$well->name};
    }
    elsif ($well->crispr_pair){
        $crispr_pair_id = $well->crispr_pair->id;
        $crispr_pair = $well->crispr_pair;
    }
    else{
        die "No crispr pair identified for well $well";
    }


    unless ($crispr_pair){
        $crispr_pair = $self->model->retrieve_crispr_pair({ id => $crispr_pair_id });
    }
    return ($crispr_pair_id, $crispr_pair);
}

sub get_crispr_group_id{
    my ($self, $well) = @_;

    my @crispr_ids = map { $_->id } $well->crisprs;
    my $group = $self->model->get_crispr_group_by_crispr_ids({
            crispr_ids => \@crispr_ids,
    });

    return ($group->id, $group);
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

    return unless $self->persist_file;

    my $dir = dir($self->base_dir);
    my $file = $dir->file($file_name);

    $self->log->info("Creating file $file");

    my $tab_fh = $file->openw() or die "Can't open file $file for writing: $! \n";
    print $tab_fh join "\n", @$lines;
    close $tab_fh
        or croak "Unable to close $file after writing: $!";

    return $file;
}

1;