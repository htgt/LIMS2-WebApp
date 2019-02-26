package LIMS2::WebApp::Controller::API::PointMutation;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::API::PointMutation::VERSION = '0.528';
}
## use critic

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
use LIMS2::Model::Util::ImportCrispressoQC qw( get_data );
use LIMS2::Model::Util::Miseq qw( wells_generator find_file find_folder read_file_lines read_alleles_frequency_file convert_index_to_well_name);

BEGIN {extends 'LIMS2::Catalyst::Controller::REST'; }



sub point_mutation_summary : Path( '/api/point_mutation_summary' ) : Args(0) : ActionClass( 'REST' ) {
}

sub point_mutation_summary_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');
    my $miseq = $c->request->param('miseq');
    my $oligo_index = $c->request->param( 'oligo' );
    my $experiment = $c->request->param( 'exp' );
    my $threshold = $c->request->param( 'limit' );
    my $percentage_bool = $c->request->param( 'perc' );
    my $miseq_well_exp_hash = get_data($c->model('Golgi'), $miseq, $oligo_index, $experiment)->{miseq_well_experiment};

    my @result = read_alleles_frequency_file($c, $miseq, $oligo_index, $experiment, $threshold, $percentage_bool);

    if (ref($result[0]) eq "HASH") {
        $c->response->status( 404 );
        $c->response->body( "Allele frequency table can not be found for Index: " . $oligo_index . "Exp: " . $experiment . ".");
        return;
    }

    my $alleles = {
        data => join("\n", @result),
    };
    $alleles->{crispr} = crispr_seq($c, $miseq, $oligo_index, $experiment);
    my $json = JSON->new->allow_nonref;
    my $body = $json->encode($alleles);

    $c->response->status( 200 );
    $c->response->content_type( 'text/plain' );
    $c->response->body( $body );

    return;
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
                order_by  => { -desc => 'id' }
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





sub crispr_seq {
    my ( $c, $miseq, $index, $exp ) = @_;

    my $job_out = find_file($miseq, $index, $exp, 'CRISPResso_RUNNING_LOG.txt');

    my $fh;
    open ($fh, '<:encoding(UTF-8)', $job_out) or die "$!";
    my @lines = <$fh>;
    my $job_input = $lines[1];
    close $fh;

    my ($amplicon,$crispr) = $job_input =~ /^.*\-a\ ([ACTGactg]+).*\-g\ ([ACTGactg]+).*$/g;
    $amplicon = uc $amplicon;
    $crispr = uc $crispr;
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


sub get_frequency_data{
    my ($c, $miseq_well_experiment_hash) = @_;

    my $limit = $c->request->param('limit');
    my $frequency_rs = $c->model('Golgi')->schema->resultset('MiseqAllelesFrequency')->search( { miseq_well_experiment_id => $miseq_well_experiment_hash->{id} });
    my $cou = $frequency_rs->count;
    my @lines;
    push @lines ,'Aligned Sequence,NHEJ,Unmodified,HDR,Deleted,Inserted,Mutated,Reads,%Reads';
    $limit = $cou if ($limit > $cou);
    if ($limit > 0){
        for my $i (1..$limit){
            my $freq_hash = $frequency_rs->next->as_hash;
            my $sum = $freq_hash->{n_reads};
            my $percentage = $sum/$miseq_well_experiment_hash->{total_reads}*100.0;
            push @lines,
                $freq_hash->{aligned_sequence}   .",".   $freq_hash->{nhej}                       .",".
                $freq_hash->{unmodified}         .",".   $freq_hash->{hdr}                        .",".
                $freq_hash->{n_deleted}          .",".   $freq_hash->{n_inserted}                 .",".
                $freq_hash->{n_mutated}          .",".   $freq_hash->{n_reads}                    .",".
                $percentage;
        }
    }
    elsif($frequency_rs->count < 1){
        print "No results";
    }
    else{
        print "Bug with alleles frequency rs";
    }
    my $data = join("\n", @lines[0..$limit]);
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
