package LIMS2::WebApp::Controller::User::Primers;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::Primers::VERSION = '0.521';
}
## use critic


use Moose;
use namespace::autoclean;
use TryCatch;
use JSON;
use Path::Class;
use LIMS2::Model::Util::PrimerGenerator;
use Data::Dumper;
use LIMS2::Exception;
use DateTime;
use Date::Parse;
use Log::Log4perl qw( :easy );
use List::MoreUtils qw( any );

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
        $c->forward('View::JSON');
        return;
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
            $type = $parent->plate_type;
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

        if($c->stash->{genotyping}){
            $c->log->debug("Checking for short arm designs");
            my $well_ids = [ map { $_->id} @wells ];
            my $short_designs = $c->model('Golgi')->get_short_arm_design_data_for_well_id_list($well_ids);
            $c->stash->{has_short_arm_designs} = 1 if $short_designs;
            $c->log->debug("has_short_arm_designs: ".$c->stash->{has_short_arm_designs});
        }

        $c->stash->{step2} = 1;
    }
    elsif($c->req->param('submit') eq 'generate_primers'){
        # actually run the primer generation code
        # redirect to some sort of result or progress view
        my $plate = $c->model('Golgi')->retrieve_plate({ name => $plate_name });
        my $generator_params = {
            plate_name       => $plate_name,
            persist_file     => $c->req->param('persist_file') // 0,
            persist_db       => $c->req->param('persist_db') // 0,
            crispr_type      => $c->req->param('crispr_type'),
            overwrite        => $c->req->param('overwrite_checkbox') // 0,
            use_short_arm_designs => $c->req->param('short_arm_designs_checkbox') // 0,
            species_name     => $plate->species_id,
            run_on_farm      => 0,
        };
        if(@well_names){
            $generator_params->{plate_well_names} = \@well_names;
        }
        my $generator = LIMS2::Model::Util::PrimerGenerator->new($generator_params);
        my $dir = dir($generator->base_dir);
        $c->log->debug("Starting primer generation in dir $dir");
        $generator_params->{start_time} = DateTime->now()->datetime;
        $dir->file('params.json')->spew( encode_json $generator_params );
        generate_primers_in_background($generator, $c->req->params);

        $c->res->redirect( $c->uri_for( '/user/generate_primers_results', $generator->job_id ));
        return;
    }
    else{
        $c->stash->{step1} = 1;
        return;
    }

    return;
}

sub generate_primers_in_background{
    my ($generator, $params) = @_;

    # tried setting this to IGNORE to avoid zombie processes
    # but this caused problems with later system call to primer3
    local $SIG{CHLD} = 'DEFAULT';

    defined( my $pid = fork() )
        or LIMS2::Exception::System->throw( "Fork failed: $!" );

    if ( $pid == 0 ) { # child
        my $primer_results = {};
        my $dir = dir($generator->base_dir);
        Log::Log4perl->easy_init( { level => $WARN, file => $dir->file( 'log.txt' ) } );

        try{
            if($params->{crispr_primer_checkbox}){
                my ($file_path, $db_primers, $errors) = $generator->generate_crispr_primers;
                $primer_results->{crispr_seq} = _primer_results_hash($dir, $file_path, $db_primers, $errors);
            }

            if($params->{crispr_pcr_checkbox}){
                my ($file_path, $db_primers, $errors) = $generator->generate_crispr_PCR_primers;
                $primer_results->{crispr_pcr} = _primer_results_hash($dir, $file_path, $db_primers, $errors);
            }

            if($params->{genotyping_primer_checkbox}){
                my ($file_path, $db_primers, $errors) = $generator->generate_design_genotyping_primers;
                $primer_results->{genotyping} = _primer_results_hash($dir, $file_path, $db_primers, $errors);
            }

            my $json = encode_json($primer_results);
            my $file = $dir->file('results.json');
            $file->spew($json);
        }
        catch($e){
            my $error_file = $dir->file('error.txt');
            $error_file->spew($e);
        }
        exit 0;
    }

    return;
}

sub _primer_results_hash{
    my ($dir, $file_path, $db_primers, $errors) = @_;

    my $results;
    if($file_path){
        my $file_rel = $file_path->relative( $dir );
        $results->{file_path} = "$file_rel";
    }
    $results->{db_primers} = $db_primers ;
    $results->{errors} = $errors;
    return $results;
}

sub generate_primers_results :Path( '/user/generate_primers_results' ) :Args(1){
    my ($self, $c, $job_id) = @_;

    $c->assert_user_roles('read');

    my $primer_dir = dir( $ENV{LIMS2_PRIMER_DIR} );
    $c->stash->{job_id} = $job_id;

    my ($dir, $params);
    try{
        $dir = $primer_dir->subdir($job_id);
        $c->log->debug("primer generation directory: $dir");
        my $params_file = $dir->file('params.json');
        $params = decode_json($params_file->slurp);
    }
    catch($e){
        $c->stash->{error_msg} = "Could not find details for primer generation job $job_id: $e";
        return;
    }

    $c->stash->{params} = $params;

    my $error_file = $dir->file('error.txt');
    if($dir->contains($error_file)){
        $c->stash->{error_msg} = $error_file->slurp;
        return;
    }

    # Default is to refresh page every 5 seconds
    my $timeout = 5000;
    my $start_time = DateTime->from_epoch( epoch => str2time( $params->{start_time} ) );
    my $time_taken = DateTime->now->subtract_datetime($start_time);
    if($time_taken->minutes > 1){
        # Reduce the refresh rate the longer we wait
        $timeout = 5000 * $time_taken->minutes;
    }

    # Report possible failure and stop refreshing if job has take 15 mins+
    if($time_taken->minutes > 14){
        $c->stash->{possible_fail} = 1;
    }

    my $file = $dir->file('results.json');
    if($dir->contains($file)){
        my $results = decode_json($file->slurp);
        my $plate = $c->model('Golgi')->retrieve_plate({ name => $params->{plate_name} });
        my %well_names = map { $_->id => $_->name } $plate->wells;
        my $file_time = DateTime->from_epoch( epoch => $file->stat->mtime );
        my $duration = $file_time->subtract_datetime($start_time);

        # Store results and well names to display
        $c->stash->{results} = $results;
        $c->stash->{plate_id} = $plate->id;
        $c->stash->{well_names} = \%well_names;
        $c->stash->{time_taken_string} = $duration->minutes." minutes and "
                                        .$duration->seconds." seconds";
    }
    else{
        my $time_taken_string = $time_taken->seconds ." seconds so far...";
        if($time_taken->minutes){
            $time_taken_string = $time_taken->minutes ." minutes and ".$time_taken_string;
        }
        $c->stash->{time_taken_string} = $time_taken_string;
        $c->log->debug("next page refresh in $timeout milliseconds");
        $c->stash->{timeout} = $timeout;
    }
    return;
}

sub download_primer_file :Path( '/user/download_primer_file' ) :Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'read' );

    my $primer_dir = dir( $ENV{LIMS2_PRIMER_DIR});
    my $file = $primer_dir->file( $c->req->param('job_id'), $c->req->param('file') );

    my $filename = $file->basename;
    my $fh;
    try{
        $fh = $file->openr;
    }
    catch($e){
        $c->flash->{error_msg} = "Could not open file $file for download";
        return $c->res->redirect( $c->uri_for('/user/generate_primers') );
    }

    $c->response->status( 200 );
    $c->response->content_type( 'text/csv' );
    $c->response->header( 'Content-Disposition' => "attachment; filename=$filename" );
    $c->response->body( $fh );
    return;
}

1;
