package LIMS2::WebApp::Controller::User::CrisprQC;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::CrisprQC::VERSION = '0.213';
}
## use critic


use Moose;
use namespace::autoclean;
use Path::Class;
use JSON;
use List::Util qw ( min max );
use List::MoreUtils qw( uniq );
use LIMS2::Model::Util::CrisprESQC;
use TryCatch;
use Log::Log4perl::Level;

BEGIN { extends 'Catalyst::Controller' };

with qw(
    MooseX::Log::Log4perl
    WebAppCommon::Crispr::SubmitInterface
);

sub crispr_es_qc_run :Path( '/user/crisprqc/es_qc_run' ) :Args(1) {
    my ( $self, $c, $qc_run_id ) = @_;

    my $params = $c->request->params;

    #default is to truncate
    my $truncate_seqs = defined $params->{truncate} ? $params->{"truncate"} : 1;

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
        my $well_data = $self->format_crispr_es_qc_well_data( $c, $qc_well, $run, $truncate_seqs, $params );
        push @qc_wells, $well_data;
    }

    $c->stash(
        qc_run_id   => $run->id,
        seq_project => $run->sequencing_project,
        sub_project => $run->sub_project,
        species     => $run->species_id,
        wells       => [ sort { $a->{well_name} cmp $b->{well_name} } @qc_wells ]
    );

    return;
}

sub crispr_es_qc_vcf_file :Path( '/user/crisprqc/vcf_file' ) :Args(1) {
    my ( $self, $c, $qc_well_id ) = @_;

    my $crispr_es_qc_well = $c->model('Golgi')->schema->resultset('CrisprEsQcWell')->find(
        { id => $qc_well_id },
    );
    unless ( $crispr_es_qc_well ) {
        $c->stash( error_msg => "Crispr ES QC Well id $qc_well_id not found" );
        return;
    }

    my $filename = 'es_crispr_qc.vcf';
    $c->res->content_type('text/plain');
    $c->res->header('Content-Disposition', qq[filename="$filename"]);
    $c->res->body( $crispr_es_qc_well->vcf_file );
    return;
}

sub crispr_es_qc_vep_file :Path( '/user/crisprqc/vep_file' ) :Args(1) {
    my ( $self, $c, $qc_well_id ) = @_;

    my $crispr_es_qc_well = $c->model('Golgi')->schema->resultset('CrisprEsQcWell')->find(
        { id => $qc_well_id },
    );
    unless ( $crispr_es_qc_well ) {
        $c->stash( error_msg => "Crispr ES QC Well id $qc_well_id not found" );
        return;
    }
    my $json = decode_json( $crispr_es_qc_well->analysis_data );

    $c->res->content_type('text/plain');
    $c->res->body( $json->{vep_output} );
    return;
}

sub crispr_es_qc_reads :Path( '/user/crisprqc/read' ) :Args(2) {
    my ( $self, $c, $read_type, $qc_well_id ) = @_;

    my $crispr_es_qc_well = $c->model('Golgi')->schema->resultset('CrisprEsQcWell')->find(
        { id => $qc_well_id },
    );
    unless ( $crispr_es_qc_well ) {
        $c->stash( error_msg => "Crispr ES QC Well id $qc_well_id not found" );
        return;
    }
    my $read_name = $read_type . '_read';
    my $read = $crispr_es_qc_well->$read_name;

    $c->res->content_type('text/plain');
    $c->res->body( $read );
    return;
}

sub crispr_es_qc_aa_file :Path( '/user/crisprqc/aa_file' ) :Args(2) {
    my ( $self, $c, $seq_type, $qc_well_id ) = @_;

    my $crispr_es_qc_well = $c->model('Golgi')->schema->resultset('CrisprEsQcWell')->find(
        { id => $qc_well_id },
    );
    unless ( $crispr_es_qc_well ) {
        $c->stash( error_msg => "Crispr ES QC Well id $qc_well_id not found" );
        return;
    }
    my $json = decode_json( $crispr_es_qc_well->analysis_data );
    my $seq_name = $seq_type . '_aa_seq';
    my $aa_seq = exists $json->{ $seq_name } ? $json->{$seq_name} : 'Sequence Not Available';

    $c->res->content_type('text/plain');
    $c->res->body( $aa_seq );
    return;
}

sub format_crispr_es_qc_well_data {
    my ( $self, $c, $qc_well, $run, $truncate_seqs, $params ) = @_;

    my $json = decode_json( $qc_well->analysis_data );

    my ( $rs, $options );
    if ( $json->{is_pair} ) {
        $rs = 'CrisprPair';
        $options = { prefetch => [ 'left_crispr', 'right_crispr', 'crispr_designs' ] };
    }
    else {
        $rs = 'Crispr';
        $options = { prefetch => [ 'crispr_designs' ] };
    }

    my $pair = $c->model('Golgi')->schema->resultset($rs)->find(
        { id => $json->{crispr_id} },
        $options
    );

    #get HGNC/MGI ids
    my @gene_ids = uniq map { $_->gene_id }
                            map { $_->genes }
                                $pair->related_designs;

    #get gene symbol from the solr
    my @genes = map { $_->{gene_symbol} }
                values %{ $c->model('Golgi')->find_genes( $run->species_id, \@gene_ids ) };

    my ( $alignment_data, $insertions, $deletions )
        = $self->format_alignment_strings( $params, $pair, $json, $truncate_seqs, $qc_well );

    my $well_accepted = $qc_well->well->accepted;
    my $show_checkbox = 1; #by default we show the accepted checkbox
    #if the well itself is accepted, we need to see if it was this run that made it so
    if ( $well_accepted && ! $qc_well->accepted ) {
        #the well was accepted on another QC run
        $show_checkbox = 0;
    }
    my $has_vcf_file = $qc_well->vcf_file ? 1 : 0;
    my $has_vep_file = exists $json->{vep_output} ? 1 : 0;
    my $has_ref_aa_file = exists $json->{ref_aa_seq} ? 1 : 0;
    my $has_mut_aa_file = exists $json->{mut_aa_seq} ? 1 : 0;

    return {
        es_qc_well_id   => $qc_well->id,
        well_id         => $qc_well->well->id,
        well_name       => $qc_well->well->name, #fetch the well and get name
        crispr_id       => $json->{crispr_id},
        is_crispr_pair  => $json->{is_pair},
        gene            => join( ",", @genes ),
        alignment       => $alignment_data,
        longest_indel   => $json->{concordant_indel} || "",
        well_accepted   => $well_accepted,
        show_checkbox   => $show_checkbox,
        insertions      => $insertions,
        deletions       => $deletions,
        has_vcf_file    => $has_vcf_file,
        has_vep_file    => $has_vep_file,
        has_ref_aa_file => $has_ref_aa_file,
        has_mut_aa_file => $has_mut_aa_file,
        fwd_read        => $qc_well->fwd_read,
        rev_read        => $qc_well->rev_read,
    };
}

## no critic(ProhibitExcessComplexity)
sub format_alignment_strings {
    my ( $self, $params, $pair, $json, $truncate_seqs, $qc_well ) = @_;

    return { forward => 'No Read', reverse => 'No Read' } if $json->{no_reads};

    # TODO refactor this
    my $insertion_data = $json->{insertions};
    my $insertions;
    for my $position ( keys %{ $insertion_data } ) {
        for my $insertion ( @{ $insertion_data->{$position} } ) {
            $insertions->{ $insertion->{read} }{ $position } = $insertion;
        }
    }

    my $deletion_data = $json->{deletions};
    my $deletions;
    for my $position ( keys %{ $deletion_data } ) {
        for my $deletion ( @{ $deletion_data->{$position} } ) {
            $deletions->{ $deletion->{read} }{ $position } = $deletion;
        }
    }

    #get start, end and size data relative to our seq strings
    my $localised = get_localised_pair_coords( $pair, $json );

    #extract read sequence and its match string
    my %alignment_data = (
        forward => $json->{forward_sequence} || '',
        reverse => $json->{reverse_sequence} || '',
    );

    #forward and reverse will have the same target_align_str
    #this is the reference sequence
    my $seq = $json->{ref_sequence} || "";

    #truncate sequences if necessary,
    #and split the target align seq into three parts: before, crispr, after
    my $padding;
    if ( $truncate_seqs ) {
        $padding = defined $params->{padding} ? $params->{padding} : 25;
        my $padded_start = max(0, ($localised->{pair_start}-$padding));
        my $end = ($localised->{pair_start}+$localised->{pair_size}+$padding);

        # TODO refactor this
        #loop through all the insertions, and see if they are inside our new truncated range.
        for my $read ( values %{ $insertions } ) {
            while ( my ( $loc, $insertion ) = each %{ $read } ) {
                #its not inside the region we're viewing so delete it
                delete $read->{$loc} if $loc < $padded_start || $loc > $end;
            }
        }

        #loop through all the deletions, and see if they are inside our new truncated range.
        for my $read ( values %{ $deletions } ) {
            while ( my ( $loc, $deletion ) = each %{ $read } ) {
                #its not inside the region we're viewing so delete it
                delete $read->{$loc} if $loc < $padded_start || $loc > $end;
            }
        }

        #truncate all the seqs
        for my $s ( values %alignment_data ) {
            next if $s eq "" or $s eq "No alignment";

            #use split sequence to get crispr and surrounding region then merge back
            $s = join "", split_sequence( $s, $localised->{pair_start}, $localised->{pair_size}, $padding );
        }
    }

    #split ref sequence into crispr and its surrounding sequence
    @alignment_data{qw(ref_start crispr_seq ref_end)}
        = split_sequence( $seq, $localised->{pair_start}, $localised->{pair_size}, $padding );

    if ( !$qc_well->fwd_read ) {
        $alignment_data{no_forward_read} = 1;
    }
    elsif ( !$qc_well->rev_read ) {
        $alignment_data{no_reverse_read} = 1;
    }

    if ( $json->{forward_no_alignment} ) {
        $alignment_data{no_forward_alignment} = 1;
    }
    elsif ( $json->{reverse_no_alignment} ) {
        $alignment_data{no_reverse_alignment} = 1;
    }

    return ( \%alignment_data, $insertions, $deletions );
}
## use critic

#pair is a pair resultset, json is the analysis_data from crispr_es_qc_wells
sub get_localised_pair_coords {
    my ( $pair, $json ) = @_;

    my $data = {
        pair_start => $pair->start - $json->{target_sequence_start},
        pair_end   => $json->{target_sequence_end} - $pair->end,
        pair_size  => ($pair->end - $pair->start) + 1,
    };

    #$data->{pair_start} = 0 if $json->{target_sequence_start} > $pair->start;
    # Fix errors introduced by insertion symbol (Q) in ref sequence
    if ( my $ref = $json->{ref_sequence} ) {
        my $start_substr = substr( $ref, 0, $data->{pair_start} );
        my $start_Q_count = () = $start_substr =~ /Q/g;
        $data->{pair_start} += $start_Q_count;

        my $crispr_substr = substr( $ref, $data->{pair_start}, $data->{pair_size} );
        my $crispr_Q_count = () = $crispr_substr =~ /Q/g;
        $data->{pair_size} += $crispr_Q_count;
    }

    return $data;
}

#split a string containing a crispr into 3 parts
sub split_sequence {
    my ( $seq, $crispr_start, $crispr_size, $padding ) = @_;

    return ( "" ) x 3 unless $seq;

    my $crispr_end = $crispr_start + $crispr_size;

    # if the crispr is not in the sequence return empty strings
    return ("") x 3 if $crispr_end <= 0;

    my $ref_end = "";
    my $start = 0; #default is beginning of string
    if ( $padding ) {
        $start = max(0, $crispr_start-$padding);
        #make sure we don't go over the end of the sequence
        #$last_size = min($padding, $last_size);

        #if the string is too short, add Xs to the right hand side to fill the space
        #this should really be done in the qc
        if ( length($seq) < $crispr_end+$padding ) {
            $seq .= "X" x (($crispr_end+$padding) - length($seq));
        }

        $ref_end = substr( $seq, $crispr_end, $padding );

        unless ( $ref_end ) {
            print $seq . "\n";
            print join ", ", $crispr_start, $crispr_end, $padding, "\n";
        }
    }
    else {
        #we want to the end of the string with no padding
        $ref_end = substr( $seq, $crispr_end );
    }

    #start can be 0 to do untruncated
    my $ref_start  =  substr( $seq, $start, $crispr_start-$start );
    #the actual crispr seq
    my $crispr_seq = substr( $seq, $crispr_start, $crispr_size );
    if ( $crispr_start <= 0 ) {
        $ref_start = '' if $crispr_start <= 0;
        $crispr_seq = substr( $seq, 0, $crispr_size + $crispr_start );
    }

    return $ref_start, $crispr_seq, $ref_end;
}

sub crispr_es_qc_runs :Path( '/user/crisprqc/es_qc_runs' ) :Args(0) {
    my ( $self, $c ) = @_;

    my @runs = $c->model('Golgi')->schema->resultset('CrisprEsQcRuns')->search(
        { 'me.species_id' => $c->session->{selected_species} },
        {
            prefetch => [ 'created_by', {'crispr_es_qc_wells' => { well => 'plate' }} ],
            rows     => 20,
            order_by => { -desc => "me.created_at" }
        }
    );

    $c->stash(
        runs => [ map { $_->as_hash({ include_plate_name => 1}) } @runs ],
    );

    return;
}

sub submit_crispr_es_qc :Path('/user/crisprqc/submit_qc_run') :Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'edit' );

    my $requirements = {
    	ep_pick_plate          => { validate => 'existing_plate_name' },
    	sequencing_project     => { validate => 'non_empty_string' },
    	sequencing_sub_project => { validate => 'non_empty_string' },
    	forward_primer_name    => { validate => 'non_empty_string' },
    	reverse_primer_name    => { validate => 'non_empty_string' },
    	submit_crispr_es_qc    => { optional => 0 },
    };

	# Store form values
	$c->stash->{sequencing_project}     = $c->req->param('sequencing_project');
	$c->stash->{sequencing_sub_project} = $c->req->param('sequencing_sub_project');
	$c->stash->{ep_pick_plate}          = $c->req->param('ep_pick_plate');
	$c->stash->{forward_primer_name}    = $c->req->param('forward_primer_name');
	$c->stash->{reverse_primer_name}    = $c->req->param('reverse_primer_name');

	if ( $c->req->param( 'submit_crispr_es_qc' ) ) {
        my $validated_params;
        try {
			$validated_params = $c->model( 'Golgi' )->check_params( $c->req->params, $requirements );
        }
        catch ( LIMS2::Exception::Validation $err ) {
            $c->stash( error_msg => $err->as_webapp_string );
            return;
        }

        my $qc_run;
		try {

            my %params = (
                model                   => $c->model('Golgi'),
                plate_name              => $validated_params->{ep_pick_plate},
                sequencing_project_name => $validated_params->{sequencing_project},
                sub_seq_project         => $validated_params->{sequencing_sub_project},
                forward_primer_name     => $validated_params->{forward_primer_name},
                reverse_primer_name     => $validated_params->{reverse_primer_name},
                commit                  => 1,
                user                    => $c->user->name,
                species                 => $c->session->{selected_species},
            );

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
                    { level => $DEBUG, file => $qc_runner->base_dir->file( 'log' ), layout => '%p %m%n' }
                );

                #run analyse plate in child
                try {
                    $qc_runner->analyse_plate;
                    $c->log->debug("Analyse plate for " . $qc_run->id . " finished");
                }
                catch ( $err ) {
                    $qc_runner->log->debug( "Analyse plate failed: $err" );
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

__PACKAGE__->meta->make_immutable;

1;
