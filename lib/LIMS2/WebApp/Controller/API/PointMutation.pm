package LIMS2::WebApp::Controller::API::PointMutation;
use Moose;
use Hash::MoreUtils qw( slice_def );
use namespace::autoclean;
use JSON;
use Image::PNG;
use File::Slurp;
use MIME::Base64;
use Bio::Perl;
use POSIX;
use Try::Tiny;
use List::Util 'max';
use LIMS2::Model::Util::Miseq qw/
    wells_generator
    find_file
    find_folder
    read_file_lines
    read_alleles_frequency_file
    convert_index_to_well_name
    convert_well_name_to_index
    get_api
/;
use LIMS2::Model::Util::ImportCrispressoQC;

BEGIN {extends 'LIMS2::Catalyst::Controller::REST'; }

my $API = get_api($ENV{LIMS2_RNA_SEQ});

sub point_mutation_summary : Path( '/api/point_mutation_summary' ) : Args(0) : ActionClass( 'REST' ) {
}

sub point_mutation_summary_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');
    my $miseq = $c->request->param('miseq');
    my $oligo_index = $c->request->param( 'oligo' );
    my $experiment = $c->request->param( 'exp' );
    my $threshold = $c->request->param( 'limit' );
    my $threshold_as_percentage = $c->request->param( 'perc' );
    my $well_name = convert_index_to_well_name($oligo_index);
    my $plate_rs = $c->model('Golgi')->schema->resultset('Plate')->find({ name => $miseq }, { prefetch => 'miseq_plates' });
    my $well_rs = $c->model('Golgi')->schema->resultset('Well')->find({ plate_id => $plate_rs->id, name => $well_name });
    my $miseq_exp = $c->model('Golgi')->schema->resultset('MiseqExperiment')->find({ name => $experiment, miseq_id => $plate_rs->miseq_plates->first->id })->as_hash;
    my $miseq_well_exp_hash = $c->model('Golgi')->schema->resultset('MiseqWellExperiment')->find({ miseq_exp_id => $miseq_exp->{id}, well_id => $well_rs->id })->as_hash;
    my $data;
    if ($threshold and $threshold <= 10) {
        $data = get_frequency_data($c, $miseq_well_exp_hash)
    }

    unless ($data) {
        try {
            my @result = read_alleles_frequency_file($API, $miseq, $oligo_index, $experiment, $threshold, $threshold_as_percentage);
            $data = join("\n", @result);
        } catch {
            $c->response->status( 404 );
            $c->response->body( "Allele frequency table can not be found for Index: " . $oligo_index . "Exp: " . $experiment . ".");
            return;
        };
    }
    my $alleles = { data => $data };
    $alleles->{crispr} = _retrieve_crispr_seq_from_job_output($c, $miseq, $oligo_index, $experiment);

    my $json = JSON->new->allow_nonref;
    my $body = $json->encode($alleles);
    $c->response->status( 200 );
    $c->response->content_type( 'text/plain' );
    $c->response->body( $body );

    return;
}

sub _retrieve_crispr_seq_from_job_output {
    my ($c, $miseq, $oligo_index, $experiment) = @_;

    my $crispr_details;
    my $importer = LIMS2::Model::Util::ImportCrispressoQC->new;
    my $path = $importer->construct_miseq_path($miseq, $oligo_index, $experiment, 'job.out');
    my $data = $importer->get_remote_file($path);
    if ($data) {
        my $crispr_amp = _extract_crispr_from_job_file($c, $data);
        $crispr_details = _precompute_crispr_loc($c, $crispr_amp->{crispr}, $crispr_amp->{amp});
    }

    return $crispr_details;
}

sub _extract_crispr_from_job_file {
    my ($c, $job) = @_;

    my $job_upper = uc $job;
    my ($amplicon, $crispr) = $job_upper =~ /.*\-A\ ([ACTG]+).*\-G\ ([ACTG]+).*/g;

    return {
        amp     => $amplicon,
        crispr  => $crispr
    };
}

sub _precompute_crispr_loc {
    my ($c, $crispr, $amplicon) = @_;

    my $rev_crispr = revcom($crispr)->seq;

    my $pos = index($amplicon, $crispr);
    if ($pos == -1) {
        try {
            $pos = index($amplicon, $rev_crispr);
        } catch {
            $c->log->debug('Miseq allele frequency summary API: Can not find crispr in forward or reverse compliment');
        };
    }

    my $result = {
        crispr      => $crispr,
        rev_crispr  => $rev_crispr,
        position    => $pos,
    };

    return $result;
}


sub experiment_summary : Path( '/api/experiment_summary' ) : Args(0) : ActionClass( 'REST' ) {
}

sub experiment_summary_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');
    my $miseq = $c->request->param('miseq');
    my $experiment = $c->request->param( 'exp' );
    my $offset_well_names = $c->request->param('offset');
    my $plate_rs = $c->model('Golgi')->schema->resultset('Plate')->find({ name => $miseq }, { prefetch => 'miseq_plates' });
    my $miseq_exp = $c->model('Golgi')->schema->resultset('MiseqExperiment')->find({ name => $experiment, miseq_id => $plate_rs->miseq_plates->first->id })->as_hash;
    my @miseq_well_exps = $c->model('Golgi')->schema->resultset('MiseqWellExperiment')->search({ miseq_exp_id => $miseq_exp->{id} });
    my ($headers, @results) = get_experiment_data($c, $miseq, $experiment, $offset_well_names, @miseq_well_exps);
    if (! @results) {
        $c->response->status( 500 );
        $c->response->body( "No alleles frequency data found for $experiment" );
        return;
    }
    my $data = { data => join("\n", ($headers, @results)) };
    my $json = JSON->new->allow_nonref;
    my $body = $json->encode($data);
    $c->response->status( 200 );
    $c->response->content_type( 'text/plain' );
    $c->response->body( $body );

    return;
}

sub get_experiment_data {
    my ($c, $miseq, $experiment, $offset_well_names, @miseq_well_exps) = @_;
    my $headers;
    my @experiment_data;
    foreach my $miseq_well_exp (@miseq_well_exps) {
        my $miseq_well_exp_hash = $c->model('Golgi')->schema->resultset('MiseqWellExperiment')->find({ id => $miseq_well_exp->id })->as_hash;
        my $well_name = $miseq_well_exp_hash->{well_name};
        my $index = convert_well_name_to_index($well_name);
        if (! $index) {
            $c->log->debug("Warning: well name not found for id $miseq_well_exp_hash->{id}");
        }
        my @alleles_freq_data;
        @alleles_freq_data = split("\n", get_frequency_data($c, $miseq_well_exp_hash));
        if (! @alleles_freq_data) {
            try {
                @alleles_freq_data = read_alleles_frequency_file($API, $miseq, $index, $experiment, 10);
            } catch {
                next;
            };
        }
        my @well_data = modify_data($offset_well_names, $index, $well_name, @alleles_freq_data);
        $headers = shift @well_data;
        push @experiment_data, @well_data;
    }
    return ($headers, @experiment_data);
}

sub modify_data {
    my ($offset_well_names, $index, $well_name, @data) = @_;
    if ($offset_well_names) {
        my $quadrant;
        ($well_name, $quadrant) = offset_well($index);
        # add quadrant column to separate wells from different quadrants
        @data = add_column('Quadrant', $quadrant, @data);
    }
    # add well name column to separate data from different wells
    my @data_with_well_name = add_column('Well_Name', $well_name, @data);
    return @data_with_well_name;
}

sub offset_well {
    my $index = shift;
    my $quadrant = 0;
    if ($index >= 1 && $index <= 96) {
        $quadrant = 1;
    } elsif ($index >= 97 && $index <= 192) {
        $index -= 96;
        $quadrant = 2;
    } elsif ($index >= 193 && $index <= 288) {
        $index -= 192;
        $quadrant = 3;
    } elsif ($index >= 289 && $index <= 384) {
        $index -= 288;
        $quadrant = 4;
    }
    return (convert_index_to_well_name($index), $quadrant);
}

sub add_column {
    my ($new_header, $item, $headers, @data) = @_;
    $headers = "$new_header,$headers";
    my @modified_data = add_item_to_data($item, @data);
    return ($headers, @modified_data);
}

sub add_item_to_data {
    my ($item, @data) = @_;
    my @modified_data;
    foreach my $row (@data) {
        push @modified_data, "$item,$row";
    }
    return @modified_data;
}


sub miseq_summary : Path( '/api/miseq_summary' ) : Args(0) : ActionClass( 'REST' ) {
}

sub miseq_summary_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');
    my $miseq = $c->request->param('miseq');
    my $offset_well_names = $c->request->param('offset');
    my $plate_rs = $c->model('Golgi')->schema->resultset('Plate')->find({ name => $miseq }, { prefetch => 'miseq_plates' });
    my @miseq_exps = map { $_->as_hash } $c->model('Golgi')->schema->resultset('MiseqExperiment')->search({ miseq_id => $plate_rs->miseq_plates->first->id });
    my ($headers, @miseq_data) = get_miseq_data($c, $miseq, $offset_well_names, @miseq_exps);
    if (! @miseq_data) {
        $c->response->status( 500 );
        $c->response->body( "No alleles frequency data found for $miseq" );
        return;
    }
    my $data = { data => join("\n", ($headers, @miseq_data)) };
    my $json = JSON->new->allow_nonref;
    my $body = $json->encode($data);
    $c->response->status( 200 );
    $c->response->content_type( 'text/plain' );
    $c->response->body( $body );

    return;
}

sub get_miseq_data {
    my ($c, $miseq, $offset_well_names, @miseq_exps) = @_;
    my $headers;
    my @miseq_data;
    foreach my $miseq_exp (@miseq_exps) {
        my $exp_name = $miseq_exp->{name};
        my @miseq_well_exps = $c->model('Golgi')->schema->resultset('MiseqWellExperiment')->search({ miseq_exp_id => $miseq_exp->{id} });
        my @exp_data = get_experiment_data($c, $miseq, $exp_name, $offset_well_names, @miseq_well_exps);
        # add experiment column to separate different experiments
        ($headers, @exp_data) = add_column('Experiment', $exp_name, @exp_data);
        push @miseq_data, @exp_data;
    }
    return ($headers, @miseq_data);
}


sub freezer_wells : Path( '/api/freezer_wells' ) : Args(0) : ActionClass( 'REST' ) {
}

sub freezer_wells_GET {
    my ( $self, $c ) = @_;
    my $fp = $c->request->param('name');

    my $fp_id = $c->model('Golgi')->schema->resultset('Plate')->find({ name => $fp })->id;

    my @wells = map { $_->name } $c->model('Golgi')->schema->resultset('Well')->search({ plate_id => $fp_id });

    my $json = JSON->new->allow_nonref;
    my $summary->{$fp} = \@wells;

    my $body = $json->encode($summary);
    $c->response->status( 200 );
    $c->response->content_type( 'text/plain' );
    $c->response->body( $body );

    return;
}

sub miseq_parent_plate_type : Path( '/api/miseq_parent_plate_type' ) : Args(0) : ActionClass( 'REST' ) {
}

sub miseq_parent_plate_type_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'read' );

    my $name = $c->request->param('name');
    my @plates = $c->model('Golgi')->schema->resultset('Plate')->search(
        { name => $name, type_id => { in => [qw/FP MISEQ PIQ/] } },
        { columns => [qw/type_id/] },
    );

    if ( @plates == 1 ) {
        $c->stash->{json_data} = {
            name => $name,
            type => $plates[0]->type_id,
        };
    }
    else {
        $c->stash->{json_data} = { error => "No valid plate found named '$name'" };
    }

    $c->forward('View::JSON');

    return;
}

sub miseq_plate : Path( '/api/miseq_plate' ) : Args(0) : ActionClass( 'REST' ) {
}

sub miseq_plate_POST {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $json = $c->request->param('json');
    my $data = decode_json $json;
    $data->{user} = $c->user->name;
    $data->{species} = $c->session->{selected_species};
    $data->{time} = strftime("%Y-%m-%dT%H:%M:%S", localtime(time));
    foreach my $fp (keys %{$data->{data}}) {
        $data->{data}->{$fp}->{wells} = flatten_wells($fp, $data->{data});
    }

    my $miseq = $c->model('Golgi')->miseq_plate_creation_json($data);

    return $self->status_created(
        $c,
        location => $c->uri_for( '/api/miseq_plate', { id => $miseq->id } ),
        entity   => $miseq
    );
}

sub miseq_plate_GET {
    my ( $self, $c ) = @_;

    my $body = $c->model('Golgi')->schema->resultset('MiseqPlate')->find ({ id => $c->request->param('id') })->as_hash;

    $c->response->status( 200 );
    $c->response->content_type( 'text/plain' );
    $c->response->body( $body );

    return;
}

sub miseq_exp_parent :Path( '/api/miseq_exp_parent' ) :Args(0) :ActionClass('REST') {
}

sub miseq_exp_parent_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $term = lc($c->request->param('term'));

    my @results;
    try {
        @results = map { $_->miseq_plate } $c->model('Golgi')->schema->resultset('MiseqExperiment')->search(
            {
                'LOWER(gene)' => { 'LIKE' => '%' . $term . '%' },
            },
            {
                join => { 'miseq' => 'plate' },
                order_by  => [ { -desc => 'plate.name' }, { -asc => 'name' } ],
            }
        );
    }
    catch {
        $c->log->error($_);
    };

    return $self->status_ok($c, entity => \@results);
}

sub miseq_preset_names :Path( '/api/miseq_preset_names' ) :Args(0) :ActionClass('REST') {
}

sub miseq_preset_names_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my @results;
    try {
        @results = map { $_->name } $c->model('Golgi')->schema->resultset('MiseqDesignPreset')->all;
    }
    catch {
        $c->log->error($_);
    };

    return $self->status_ok($c, entity => \@results);
}



#Quads had to to be introduced in a way to preserve data in the view.
#Messy to deal with in the back end
sub flatten_wells {
    my ($fp, $wells) = @_;

    my $fp_data = $wells->{$fp}->{wells};

    my $new_structure;
    foreach my $quad (keys %{$fp_data}) {
        if (ref $fp_data->{$quad} eq 'HASH') {
            foreach my $well (sort keys %{$fp_data->{$quad}}) {
                $new_structure->{$well} = $fp_data->{$quad}->{$well};
            }
        }
    }

    return $new_structure;
}


sub get_frequency_data {
    my ($c, $miseq_well_experiment_hash) = @_;

    my $limit = $c->request->param('limit');

    my $frequency_rs = $c->model('Golgi')->schema->resultset('MiseqAllelesFrequency')->search({
        miseq_well_experiment_id => $miseq_well_experiment_hash->{id},
    }, {
        order_by => { -desc => 'n_reads' }
    });
    my $freq_count = $frequency_rs->count;

    my @lines;
    my @headers;
    my $freq_hash;
    $limit = $freq_count if (!defined $limit || $limit > $freq_count);
    if ($limit > 0){
        $freq_hash = $frequency_rs->next->as_hash;

        if ($freq_hash->{reference_sequence}) {
            if ($freq_hash->{quality_score}) {
                unshift @lines ,'Aligned_Sequence,Reference_Sequence,Phred_Quality,NHEJ,UNMODIFIED,HDR,n_deleted,n_inserted,n_mutated,#Reads,%Reads';
                @headers = ("aligned_sequence","reference_sequence","quality_score","nhej","unmodified","hdr","n_deleted","n_inserted","n_mutated","n_reads");
            }
            else {
                unshift @lines ,'Aligned_Sequence,Reference_Sequence,NHEJ,UNMODIFIED,HDR,n_deleted,n_inserted,n_mutated,#Reads,%Reads';
                @headers = ("aligned_sequence","reference_sequence","nhej","unmodified","hdr","n_deleted","n_inserted","n_mutated","n_reads");
            }
        }
        else {
                unshift @lines ,'Aligned_Sequence,NHEJ,UNMODIFIED,HDR,n_deleted,n_inserted,n_mutated,#Reads,%Reads';
                @headers = ("aligned_sequence","nhej","unmodified","hdr","n_deleted","n_inserted","n_mutated","n_reads");
        }

        for my $i (1..$limit) {
            my $percentage = $freq_hash->{n_reads} / $miseq_well_experiment_hash->{total_reads} * 100.0;
            my $line = join(',', map { $freq_hash->{$_} } @headers) . ',' . $percentage;
            push @lines, $line;

            if (my $next = $frequency_rs->next) {
                    $freq_hash = $next->as_hash;
            }
            else {
                last;
            }
        }
    }
    elsif ($frequency_rs->count < 1) {
        print "No results";
    }
    else {
        print "Bug with alleles frequency rs";
    }

    my $data = join ("\n", @lines[0..$limit]);

    return $data;
}
#The bellow methods are not used anymore. They were used to handle data from the local files. They were replaced after database migration. 
#The new methods now operate using data stored in the database.

sub get_raw_image{
    my ($c, $miseq_well_experiment_id) = @_;

    my $indel_graph_hash;
    my $indel_graph_rs = $c->model('Golgi')->schema->resultset('IndelDistributionGraph')->search( { id => $miseq_well_experiment_id });

    if ($indel_graph_rs->count > 1){
        print "More than 1";
    }
    elsif($indel_graph_rs->count < 1){
        print "No results";
    }
    else{
        $indel_graph_hash = $indel_graph_rs->first->as_hash;
    }
    return $indel_graph_hash->{indel_size_distribution_graph};
}



sub point_mutation_image_old : Path( '/api/point_mutation_img_old' ) : Args(0) : ActionClass( 'REST' ) {
}

sub point_mutation_image_old_GET {
    my ( $self, $c ) = @_;

    my %whitelist = (
        '1b.Indel_size_distribution_percentage.png' => 1,
        '2.Unmodified_NHEJ_pie_chart.png'           => 1,
    );

    $c->assert_user_roles('read');

    my $miseq = $c->request->param('miseq');
    my $oligo_index = $c->request->param( 'oligo' );
    my $experiment = $c->request->param( 'exp');
    my $file_name = $c->request->param( 'name' );

    #Sanitise inputs since it's a broad search
    unless (exists($whitelist{$file_name})) {
        $c->response->status( 406 );
        $c->response->body( "File name: " . $file_name . " is not acceptable. This query has been terminated.");
        return;
    }

    my $graph_dir = find_file($miseq, $oligo_index, $experiment, $file_name);

    unless ($graph_dir) {
        $c->response->status( 404 );
        $c->response->body( "File name: " . $file_name . " can not be found.");
        return;
    }

    open my $fh, '<', $graph_dir or die "$!";
    my $raw_string = do{ local $/ = undef; <$fh>; };
    close $fh;

    my $body = encode_base64( $raw_string );

    $c->response->status( 200 );
    $c->response->content_type( 'image/png' );
    $c->response->content_encoding( 'base64' );
    $c->response->header( 'Content-Disposition' => 'attachment; filename='
            . 'S' . $oligo_index . '_exp' . $experiment
    );
    $c->response->body( $body );

    return;
}

sub point_mutation_summary_old : Path( '/api/point_mutation_summary_old' ) : Args(0) : ActionClass( 'REST' ) {
}

sub point_mutation_summary_old_GET {
    my ( $self, $c ) = @_;
    $c->assert_user_roles('read');
    my $miseq = $c->request->param('miseq');
    my $oligo_index = $c->request->param( 'oligo' );
    my $experiment = $c->request->param( 'exp' );
    my $limit = $c->request->param( 'limit' );

    my $sum_dir = find_file($miseq, $oligo_index, $experiment, 'Alleles_frequency_table.txt');

    unless ($sum_dir) {
        $c->response->status( 404 );
        $c->response->body( "Allele frequency table can not be found for Index: " . $oligo_index . "Exp: " . $experiment . ".");
        return;
    }

    my $fh;
    open ($fh, '<:encoding(UTF-8)', $sum_dir) or die "$!";
    my @lines = read_file_lines($fh);
    close $fh;

    my $res;
    if ($limit) {
        $res->{data} = join("\n", @lines[0..$limit]);
    } else {
        $res->{data} = join("\n", @lines);
    }
    $res->{crispr} = crispr_seq($c, $miseq, $experiment);

    my $json = JSON->new->allow_nonref;
    my $body = $json->encode($res);

    $c->response->status( 200 );
    $c->response->content_type( 'text/plain' );
    $c->response->body( $body );

    return;
}

1;
