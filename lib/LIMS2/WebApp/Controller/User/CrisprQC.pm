package LIMS2::WebApp::Controller::User::CrisprQC;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::CrisprQC::VERSION = '0.509';
}
## use critic


use Moose;
use namespace::autoclean;
use Path::Class;
use JSON;
use List::Util qw ( min max );
use List::MoreUtils qw( uniq );
use LIMS2::Model::Util::CrisprESQC;
use LIMS2::Model::Util::CrisprESQCView qw( find_gene_crispr_es_qc );
use LIMS2::Model::Util::DataUpload qw(process_het_status_file);
use TryCatch;
use Log::Log4perl::Level;
use Bio::Perl qw( revcom );

BEGIN { extends 'Catalyst::Controller' };

with qw(
    MooseX::Log::Log4perl
    WebAppCommon::Crispr::SubmitInterface
);

sub crispr_es_qc_run :Path( '/user/crisprqc/es_qc_run' ) :Args(1) {
    my ( $self, $c, $qc_run_id ) = @_;

    my $params = $c->request->params;

    #truncate sequences by default
    if ( ! defined $params->{truncate} ) {
        $params->{truncate} = 1;
    }

    #should prefetch wells too
    my $run = $c->model('Golgi')->schema->resultset('CrisprEsQcRuns')->find(
        { id => $qc_run_id },
        { prefetch => {'crispr_es_qc_wells' => 'well'} }
    );

    unless ( $run ) {
        $c->stash( error_msg => "Run id $qc_run_id not found" );
        return;
    }

    my @qc_wells;
    for my $qc_well ( $run->crispr_es_qc_wells ) {
        my $well_data = $qc_well->format_well_data(
            sub { $c->model('Golgi')->find_genes( @_ ); }, #gene finder method
            $params,
            $run
        );

        my $het_status = $c->model('Golgi')->schema->resultset( 'WellHetStatus' )->find({ well_id => $well_data->{well_id} });

        if ($het_status) {
            $well_data->{het_status} = { five_prime => $het_status->five_prime, three_prime => $het_status->three_prime };
        }

        push @qc_wells, $well_data;
    }

    my @crispr_damage_types = $c->model('Golgi')->schema->resultset( 'CrisprDamageType' )->all;

    my $can_accept_wells = 0;
    my $hide_crispr_validation = 1;
    my $hide_het_validation = 0;
    if ( my $qc_well = $run->crispr_es_qc_wells->first ) {
        my $plate_type  = $qc_well->well->plate_type;
        if ( $plate_type eq 'EP_PICK' or $plate_type eq 'SEP_PICK') {
            # only do crispr validation of ES cells in EP_PICK plates
            $hide_crispr_validation = 0;
            $can_accept_wells = 1;
        }
        elsif ( $plate_type eq 'PIQ' or $plate_type eq 'S_PIQ') {
            $can_accept_wells = 1;
        }
    }

    if($run->sequencing_data_version){
        $c->stash->{info_msg} = "The data for sequencing project ".$run->sequencing_project
                                ." has been updated since this QC run was performed."
                                ." This page shows the old data used by the QC run which is stored as backup version "
                                .$run->sequencing_data_version;
    }

    $c->stash(
        qc_run_id              => $run->id,
        plate_name             => $run->plate_name,
        gene_number            => $run->allele_number,
        seq_project            => $run->sequencing_project,
        sub_project            => $run->sub_project,
        sequencing_data_version => $run->sequencing_data_version,
        species                => $run->species_id,
        wells                  => [ sort { $a->{well_name} cmp $b->{well_name} } @qc_wells ],
        damage_types           => [ map{ $_->id } @crispr_damage_types ],
        run_validated          => $run->validated,
        can_accept_wells       => $can_accept_wells,
        truncate               => $params->{truncate},
        hide_crispr_validation => $hide_crispr_validation,
        hide_het_validation    => $hide_het_validation,
    );

    return;
}

#
# START OF CHAINED METHODS
# Used to display files associated with a crispr es qc well
#

sub crispr_qc_well : PathPart('user/crispr_qc_well') Chained('/') CaptureArgs(1) {
    my ( $self, $c, $qc_well_id ) = @_;

    my $crispr_es_qc_well = $c->model('Golgi')->schema->resultset('CrisprEsQcWell')->find(
        { id => $qc_well_id },
    );
    unless ( $crispr_es_qc_well ) {
        $c->stash( error_msg => "Crispr ES QC Well id $qc_well_id not found" );
        return;
    }
    my $json = decode_json( $crispr_es_qc_well->analysis_data );

    $c->log->debug( "Retrived crispr es qc well, id: $qc_well_id" );

    $c->stash(
        crispr_es_qc_well => $crispr_es_qc_well,
        analysis_data     => $json,
    );

    return;
}

sub crispr_es_qc_vcf_file :PathPart( 'vcf_file' ) Chained('crispr_qc_well') :Args(0) {
    my ( $self, $c ) = @_;

    $c->res->content_type('text/plain');
    $c->res->header('Content-Disposition', qq[filename="es_crispr_qc_vcf"]);
    $c->res->body( $c->stash->{crispr_es_qc_well}->vcf_file );
    return;
}

sub crispr_es_qc_non_merged_vcf_file :PathPart( 'non_merged_vcf_file' ) Chained('crispr_qc_well') :Args(0) {
    my ( $self, $c ) = @_;

    my $data = $c->stash->{analysis_data}{non_merged_vcf} || '';
    $c->res->content_type('text/plain');
    $c->res->body( $data );
    return;
}

sub crispr_es_qc_vep_file :PathPart( 'vep_file' ) Chained('crispr_qc_well') :Args(0) {
    my ( $self, $c ) = @_;

    my $data = $c->stash->{analysis_data}{vep_output} || '';
    $c->res->content_type('text/plain');
    $c->res->body( $data );
    return;
}

sub crispr_es_qc_reads :PathPart( 'read' ) Chained('crispr_qc_well') :Args(1) {
    my ( $self, $c, $read_type ) = @_;

    unless ( $read_type eq 'fwd' || $read_type eq 'rev' ) {
        $c->stash( error_msg => "Not a valid read type: $read_type" );
        return $c->go( 'Controller::User::CrisprQC', 'crispr_es_qc_runs' );
    }

    my $read_name = $read_type . '_read';
    my $crispr_es_qc_well = $c->stash->{crispr_es_qc_well};
    my $read = $crispr_es_qc_well->$read_name;

    $c->res->content_type('text/plain');
    $c->res->body( $read );
    return;
}

sub crispr_es_qc_aa_file :PathPart( 'aa_file' ) Chained('crispr_qc_well') :Args(1) {
    my ( $self, $c, $seq_type ) = @_;

    unless ( $seq_type eq 'mut' || $seq_type eq 'ref' ) {
        $c->stash( error_msg => "Not a valid protein sequence type: $seq_type" );
        return $c->go( 'Controller::User::CrisprQC', 'crispr_es_qc_runs' );
    }
    my $seq_name = $seq_type . '_aa_seq';
    my $analysis_data = $c->stash->{analysis_data};
    my $aa_seq = exists $analysis_data->{ $seq_name } ? $analysis_data->{$seq_name} : 'Sequence Not Available';

    $c->res->content_type('text/plain');
    $c->res->body( $aa_seq );
    return;
}

#
# END OF CHAINED METHODS
#

sub crispr_es_qc_runs :Path( '/user/crisprqc/es_qc_runs' ) :Args(0) {
    my ( $self, $c ) = @_;

    my $params = $c->request->params;

    if ( defined $params->{show_all} ) {
        delete @{$params}{ qw( show_all sequencing_project plate_name ) };
    }

    #filter isnt in the pspec so remove it to avoid an error
    delete $params->{filter} if defined $params->{filter};

    $params->{species} ||= $c->session->{selected_species};

    if ($params->{sequencing_project}) {
        $params->{sequencing_project} =~ s/^\s+//;
        $params->{sequencing_project} =~ s/\s+$//;
    }
    if ($params->{plate_name}) {
        $params->{plate_name} =~ s/^\s+//;
        $params->{plate_name} =~ s/\s+$//;
    }

    my ( $runs, $pager ) = $c->model('Golgi')->list_crispr_es_qc_runs( $params );

    my $pageset = LIMS2::WebApp::Pageset->new(
        {
            total_entries    => $pager->total_entries,
            entries_per_page => $pager->entries_per_page,
            current_page     => $pager->current_page,
            pages_per_set    => 5,
            mode             => 'slide',
            base_uri         => $c->uri_for( '/user/crisprqc/es_qc_runs', $params )
        }
    );

    $c->stash(
        runs               => $runs,
        pageset            => $pageset,
        plate_name         => $params->{plate_name},
        sequencing_project => $params->{sequencing_project},
    );

    return;
}

sub submit_crispr_es_qc :Path('/user/crisprqc/submit_qc_run') :Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'edit' );

    my $requirements = {
    	plate_name             => { validate => 'existing_plate_name' },
    	sequencing_project     => { validate => 'non_empty_string' },
    	sequencing_sub_project => { validate => 'non_empty_string' },
    	forward_primer_name    => { validate => 'non_empty_string' },
    	reverse_primer_name    => { validate => 'non_empty_string' },
    	submit_crispr_es_qc    => { optional => 0 },
        gene_number            => { validate => 'integer', optional => 1},
    };

	# Store form values
	$c->stash->{sequencing_project}     = $c->req->param('sequencing_project');
	$c->stash->{sequencing_sub_project} = $c->req->param('sequencing_sub_project');
	$c->stash->{plate_name}             = $c->req->param('plate_name');
	$c->stash->{forward_primer_name}    = $c->req->param('forward_primer_name');
	$c->stash->{reverse_primer_name}    = $c->req->param('reverse_primer_name');
    $c->stash->{gene_number}            = $c->req->param('gene_number');

	if ( $c->req->param( 'submit_crispr_es_qc' ) ) {
        my $validated_params;
        try {
			$validated_params = $c->model( 'Golgi' )->check_params( $c->req->params, $requirements );
        }
        catch ( LIMS2::Exception::Validation $err ) {
            $c->stash( error_msg => $err->as_webapp_string );
            return;
        }
        my $plate = $c->model('Golgi')->retrieve_plate( { name => $validated_params->{plate_name} } );
        my $plate_species = $plate->{_column_data}->{species_id};
        unless ($plate->{_column_data}->{species_id} eq $c->session->{selected_species}) {
            $c->stash( error_msg =>  $validated_params->{plate_name} . " is a " . $plate_species . " plate whereas your session is set to "
                . $c->session->{selected_species} . ". Please set your session to " . $plate_species . " and resubmit.");
            return;
        }

        # Decide which gene/allele to run QC on for double targeted plate types
        my $allele_number;
        if($plate->type_id eq 'SEP_PICK'){
            # QC second allele only for SEP_PICK
            $allele_number = 2;
        }
        elsif($plate->type_id eq 'S_PIQ'){
            # User must specify which allele the seq project is for
            $allele_number = $c->req->param('gene_number');
            unless($allele_number){
                $c->stash->{error_msg} = "You must specify which gene to run QC for when using S_PIQ double targeted plate";
            }
        }

        my $qc_run;
		try {

            my %params = (
                model                   => $c->model('Golgi'),
                plate                   => $plate,
                sequencing_project_name => $validated_params->{sequencing_project},
                sub_seq_project         => $validated_params->{sequencing_sub_project},
                forward_primer_name     => $validated_params->{forward_primer_name},
                reverse_primer_name     => $validated_params->{reverse_primer_name},
                commit                  => 1,
                user                    => $c->user->name,
                species                 => $c->session->{selected_species},
            );

            if($allele_number){
                $params{allele_number} = $allele_number;
            }

            my $qc_runner = LIMS2::Model::Util::CrisprESQC->new( %params );

            #initialize lazy build
            $qc_run = $qc_runner->qc_run;

            my $pid = fork();
            if ( $pid ) { #parent
                $c->log->debug( "Child pid $pid created" );
            }
            elsif ( $pid == 0 ) {
                $c->log->debug("Running analyse plate for " . $qc_run->id . " in child process");

                $qc_runner->model->clear_schema; #force refresh

                #re-initialise logger into work dir
                Log::Log4perl->easy_init(
                    { level => $DEBUG, file => $qc_runner->base_dir->file( 'log' ), layout => '%p %d %m%n' }
                );

                #run analyse plate in child
                try {
                    $qc_runner->analyse_plate;
                    $c->log->debug("Analyse plate for " . $qc_run->id . " finished");
                }
                catch ( $err ) {
                    $qc_runner->log->error( "Analyse plate failed: $err" );
                }

                exit 0; #exits immediately, avoiding trycatch
            }
            else {
                die "Couldn't fork: $!";
            }

            # TODO forward to the qc page .. which will eventually update

		}
		catch ( $err ) {
            $c->log->warn( $err );
			$c->stash( error_msg => "$err" );
			return;
		}

        $c->stash(
            run_id => $qc_run->id,
            success_msg => "Your QC job has been submitted with ID " . $qc_run->id
        );
	}

	return;
}

sub delete_crispr_es_qc :Path('/user/crisprqc/delete_qc_run') :Args(1) {
    my ( $self, $c, $qc_run_id ) = @_;

    $c->assert_user_roles( 'edit' );

    $c->model('Golgi')->txn_do(
        sub {
            try {
                $c->model('Golgi')->delete_crispr_es_qc_run( { id => $qc_run_id } );
                $c->flash( success_msg => "Deleted QC Run $qc_run_id" );
                $c->res->redirect( $c->uri_for('/user/crisprqc/es_qc_runs') );
            }
            catch ( $err ) {
                $c->flash( error_msg => "Error encountered while deleting QC run: $err" );
                $c->model('Golgi')->txn_rollback;
                $c->res->redirect( $c->uri_for("/user/crisprqc/es_qc_run", $qc_run_id) );
            }
        }
    );

    return;
}

sub gene_crispr_es_qc :Path('/user/crisprqc/gene_crispr_es_qc') :Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'read' );

    my $gene = $c->request->param( 'gene_id' )
        or return;
    $self->log->info( "Generate crispr es qc view for gene: $gene" );

    my $species_id = $c->request->param('species') || $c->session->{selected_species};

    my ( $gene_info, $sorted_crispr_qc ) = find_gene_crispr_es_qc( $c->model('Golgi'), $gene, $species_id );
    my @crispr_damage_types = $c->model('Golgi')->schema->resultset( 'CrisprDamageType' )->all;

    $c->stash(
        gene         => $gene_info,
        crispr_qc    => $sorted_crispr_qc,
        damage_types => [ map{ $_->id } @crispr_damage_types ],
    );
    return;
}

sub upload_het_status_file :Path('/user/crisprqc/upload_het_status_file') :Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'edit' );

    return unless $c->req->param('upload_het_status');

    my $het_status = $c->request->upload('datafile');
    unless ( $het_status ) {
        $c->stash->{error_msg} = 'No csv file with het status data specified';
        return;
    }

    my $model = $c->model('Golgi');
    $model->txn_do(
        sub{
            try{
                my $messages = process_het_status_file($model,$het_status->fh,$c->user->name);
                $c->stash->{success_msg} = "Uploaded het status values from ".$het_status->basename.":<br>"
                                           .join("<br>", @$messages);
            }
            catch ($err){
               $c->stash->{error_msg} = "Error processing ".$het_status->basename.". Nothing has been updated.<br> Error message: $err";
               $model->txn_rollback;
            }
        }
    );

    return;
}

# Used by ajax get in the gene summary page to populate alignment details on demand
# Uses HTML_fragment view because the standard HTML view adds wrapper.tt to the html
sub qc_well_alignment :Path('/user/crisprqc/well_alignment') :Args(1) {
    my ($self, $c, $qc_well_id) = @_;

    $c->assert_user_roles('read');

    my $qc_well = $c->model('Golgi')->retrieve_crispr_es_qc_well({ id => $qc_well_id });
    my $gene_finder = sub { $c->model('Golgi')->find_genes(@_) };
    my $qc_data = $qc_well->format_well_data( $gene_finder, { truncate => 1 } );
    $c->stash->{qc} = $qc_data;


    $c->stash->{template} = 'crispr_qc_alignment.tt';
    $c->forward( $c->view('HTML_fragment') );
    return;
}

sub qc_well_details :Path('/user/crisprqc/qc_well_details') :Args(1){
    my ($self, $c, $qc_well_id) = @_;

    $c->assert_user_roles('read');

    my $qc_well = $c->model('Golgi')->retrieve_crispr_es_qc_well({ id => $qc_well_id });
    my $gene_finder = sub { $c->model('Golgi')->find_genes(@_) };
    my $qc_data = $qc_well->format_well_data( $gene_finder, { truncate => 1 });

    $c->stash({
        template               => 'crispr_qc_view.tt',
        row                    => $qc_data,
        accept                 => 0,
        edit                   => 0,
        hide_crispr_well_id    => 1,
        complete_info          => 0,
        hide_well_name         => 1,
        hide_gene              => 1,
        hide_crispr_validation => 1,
        hide_het_validation    => 1,
    });
    $c->forward( $c->view('HTML_fragment') );
    return;
}

__PACKAGE__->meta->make_immutable;

1;
