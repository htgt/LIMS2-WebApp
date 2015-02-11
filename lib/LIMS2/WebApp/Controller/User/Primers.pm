package LIMS2::WebApp::Controller::User::Primers;

use Moose;
use namespace::autoclean;
use TryCatch;
use JSON;
use LIMS2::Model::Util::PrimerGenerator;
use Data::Dumper;

BEGIN { extends 'Catalyst::Controller' };

# Returns JSON so this can be used in ajax request
sub toggle_genotyping_primer_validation_state : Path( '/user/toggle_genotyping_primer_validation_state' ) : Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $design_id = $c->request->param('design_id');
    my $primer_type = $c->request->param('primer_type');

    my $primer = $c->model('Golgi')->schema->resultset('GenotypingPrimer')->find({
            design_id => $design_id,
            genotyping_primer_type_id => $primer_type,
            is_rejected => [ 0, undef ],
    	});

    if($primer){
        my $orig_state = ( $primer->is_validated ? 1 : 0 );
        my $new_state = ( !$orig_state ? 1 : 0 );
        $c->log->debug("Changing genotyping primer validation state from $orig_state to $new_state");
        $primer->update({ is_validated => $new_state });

        $c->stash->{json_data} = { success => 1, is_validated => $primer->is_validated };
    }
    else{
    	$c->stash->{json_data} = { error => 'Primer not found' };
    }


    $c->forward('View::JSON');
    return;
}

# Returns JSON so this can be used in ajax request
sub toggle_crispr_primer_validation_state : Path( '/user/toggle_crispr_primer_validation_state' ) : Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $primer_type = $c->request->param('primer_type');

    my $search = {
    	primer_name => $primer_type,
        is_rejected => [ 0, undef ],
    };

    my $crispr_key = $c->request->param('crispr_key');
    my ($id,$type) = ($crispr_key =~ / (\d*) \s* \( (\w*) \) /ixms);

    unless ($id and $type){
    	$c->stash->{json_data} = { error => "Could not identify crispr ID and type in string $crispr_key" };
        $c->forward('View::JSON');
        return;
    }

    if($type eq "crispr"){
    	$search->{crispr_id} = $id;
    }
    elsif($type eq "crispr_pair"){
    	$search->{crispr_pair_id} = $id;
    }
    elsif($type eq "crispr_group"){
        $search->{crispr_group_id} = $id;
    }
    else{
        $c->stash->{json_data} = { error => "Crispr type \"$type\" not recognised" };
    }

    my $primer = $c->model('Golgi')->schema->resultset('CrisprPrimer')->find($search);

    if($primer){
        my $orig_state = ( $primer->is_validated ? 1 : 0 );
        my $new_state = ( !$orig_state ? 1 : 0 );
        $c->log->debug("Changing crispr primer validation state from $orig_state to $new_state");
        $primer->update({ is_validated => $new_state });

        $c->stash->{json_data} = { success => 1, is_validated => $primer->is_validated };
    }
    else{
    	$c->stash->{json_data} = { error => 'Primer not found' };
    }


    $c->forward('View::JSON');
    return;
}

sub generate_primers :Path( '/user/generate_primers' ) :Args(0){
    my($self, $c) = @_;

    $c->assert_user_roles('edit');

    $c->stash->{wells} = $c->req->param('wells');
    $c->stash->{plate_name} = $c->req->param('plate_name');
    my $plate_name = $c->req->param('plate_name');
    my @well_names = split /[,\s]+/, $c->req->param('wells');

    if($c->req->param('submit') eq 'get_options'){

        $c->log->debug('Plate wells: ',@well_names);

        unless($plate_name){
            $c->stash->{error_msg} = "You must provide a plate name";
            return;
        }

        my $plate;
        try{
            $plate = $c->model('Golgi')->retrieve_plate({ name => $plate_name });
        }
        catch ($e){
            $c->stash->{error_msg} = "Plate not found: $e";
            return;
        }

        my @wells;
        if(@well_names){
            # check wells are on plate
            foreach my $name (@well_names){
                my ($well) = $plate->search_related('wells', { name => $name })->all;
                unless($well){
                    $c->stash->{error_msg} = "Well $name not found on plate";
                    return;
                }
                push @wells, $well;
            }
        }
        else{
            @wells = $plate->wells;
        }

        my @crispr_plate_types = qw(CRISPR CRISPR_V);
        my @design_plate_types = qw(DESIGN INT POSTINT FINAL FINAL_PICK);
        $c->stash->{plate_type} =  $plate->type_id;

        my $type = $plate->type_id;
        if($type eq 'DNA'){
            # DNA could be from design or crispr so check parent well type instead
            my ($parent) = $wells[0]->parent_wells;
            $type = $parent->plate->type_id;
        }

        if(grep { $_ eq $type } @crispr_plate_types){
            $c->stash->{crispr_type} = 'single';
        }
        elsif(grep { $_ eq $type } @design_plate_types){
            $c->stash->{genotyping} = 1;
        }
        else{
            # is assembly or later
            $c->stash->{genotyping} = 1;
            my $assembly_type = $wells[0]->parent_assembly_process_type;
            $c->log->debug("Assembly process type: $assembly_type");
            my $crispr_types = {
                'single_crispr_assembly' => 'single',
                'paired_crispr_assembly' => 'pair',
                'group_crispr_assembly' => 'group',
            };
            $c->stash->{crispr_type} = $crispr_types->{$assembly_type};
        }

        $c->stash->{step2} = 1;
    }
    elsif($c->req->param('submit') eq 'generate_primers'){
        # actually run the primer generation code
        # redirect to some sort of result or progress view
        my $plate = $c->model('Golgi')->retrieve_plate({ name => $plate_name });
        my $generator = LIMS2::Model::Util::PrimerGenerator->new({
            plate_name       => $plate_name,
            plate_well_names => \@well_names,
            persist_file     => $c->req->param('persist_file'),
            persist_db       => $c->req->param('persist_db'),
            crispr_type      => $c->req->param('crispr_type'),
            overwrite        => 1, # FIXME: need checkbox for this
            species_name     => $plate->species_id,
        });
        my $dir = $generator->base_dir;
        $c->log->debug("Starting primer generation in dir $dir");
        my $primer_results;
        if($c->req->param('crispr_primer_checkbox')){
            my ($file_path, $db_primers) = $generator->generate_crispr_primers;
            $primer_results->{crispr_seq}->{file_path} = $file_path;
            $primer_results->{crispr_seq}->{db_primers} = $db_primers ;
        }

        if($c->req->param('crispr_pcr_checkbox')){
            my ($file_path, $db_primers) = $generator->generate_crispr_PCR_primers;
            $primer_results->{crispr_pcr}->{file_path} = $file_path;
            $primer_results->{crispr_pcr}->{db_primers} = $db_primers ;
        }

        if($c->req->param('genotyping_primer_checkbox')){
            my ($file_path, $db_primers) = $generator->generate_design_genotyping_primers;
            $primer_results->{genotyping}->{file_path} = $file_path;
            $primer_results->{genotyping}->{db_primers} = $db_primers ;
        }
        $c->log->debug(Dumper($primer_results));
        $c->stash->{results} = $primer_results;
        return;
    }
    else{
        $c->stash->{step1} = 1;
        return;
    }

    return;
}

1;
