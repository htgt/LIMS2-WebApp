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
use LIMS2::Model::Util::Miseq qw( wells_generator find_file find_folder read_file_lines convert_index_to_well_name );
use List::Util 'max';

BEGIN {extends 'LIMS2::Catalyst::Controller::REST'; }

sub point_mutation_image : Path( '/api/point_mutation_img' ) : Args(0) : ActionClass( 'REST' ) {
}

sub point_mutation_image_GET {
    my ( $self, $c ) = @_;
    #my %whitelist = (
    #    '1b.Indel_size_distribution_percentage.png' => 1,
    #    '2.Unmodified_NHEJ_pie_chart.png'           => 1,
    #);

    $c->assert_user_roles('read');

    my $miseq = $c->request->param('miseq');
    my $oligo_index = $c->request->param( 'oligo' );
    my $experiment = $c->request->param( 'exp');
    my $file_name = $c->request->param( 'name' );

    my $miseq_well_experiment_hash = get_miseq_well_experiment_hash($c, $miseq, $oligo_index, $experiment);
    
    unless($miseq_well_experiment_hash->{id}){
        $c->response->status( 404 );
        $c->response->body( "Database entry for filename: " . $file_name . " can not be found.");
        return;
    }
     
    my $raw_string = get_raw_image($c, $miseq_well_experiment_hash->{id});
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


sub point_mutation_summary : Path( '/api/point_mutation_summary' ) : Args(0) : ActionClass( 'REST' ) {
}

sub point_mutation_summary_GET {
    my ( $self, $c ) = @_;
    $c->assert_user_roles('read');
    my $miseq = $c->request->param('miseq');
    my $oligo_index = $c->request->param( 'oligo' );
    my $experiment = $c->request->param( 'exp' );
    my $limit = $c->request->param( 'limit' );

    my $miseq_well_experiment_hash = get_miseq_well_experiment_hash($c, $miseq, $oligo_index, $experiment);
  
    unless($miseq_well_experiment_hash->{id}){
        $c->response->status( 404 );
        $c->response->body( "Database entry for miseq well experiment id: " . $miseq_well_experiment_hash->{id} . " can not be found for $miseq, $oligo_index and $experiment");
        return; 
    }

    my $res->{data} = get_frequency_data($c, $miseq_well_experiment_hash);
        
    $res->{crispr} = crispr_seq($c, $miseq, $experiment);
    my $json = JSON->new->allow_nonref;
    my $body = $json->encode($res);

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
    if( @plates == 1 ) {
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
    my $protocol = $c->req->headers->header('X-FORWARDED-PROTO') // '';

    if($protocol eq 'HTTPS'){
        my $base = $c->req->base;
        $base =~ s/^http:/https:/;
        $c->req->base(URI->new($base));
        $c->req->secure(1);
    }
    $c->require_ssl;

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
        @results = map { $_->parent_plate } $c->model('Golgi')->schema->resultset('MiseqExperiment')->search(
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
    my ( $c, $miseq, $req ) = @_;

    my $sum_dir = $ENV{LIMS2_RNA_SEQ} . $miseq . '/summary.csv';
    my $fh;

    my $csv = Text::CSV->new ({
        binary    => 1,
    });

    my @lines;
    open ($fh, '<:encoding(UTF-8)', $sum_dir) or die "$!";
    while (my $row = $csv->getline($fh)) {
        push (@lines, $row);
    }
    close $fh;
    shift @lines;

    my $res;
    foreach my $exp (@lines) {
        if (@$exp[0] eq $req) {
            my $index = index(@$exp[4], @$exp[2]); #Pos of Crispr in Amplicon string
            if ($index == -1) {
                try {
                    $index = index(@$exp[4], revcom(@$exp[2])->seq);
                } catch {
                    $c->log->debug('Miseq allele frequency summary API: Can not find crispr in forward or reverse compliment');
                };
            }
            $res->{crispr} = @$exp[2];
            $res->{position} = $index;
        }
    }

    return $res;
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
   $DB::single=1; 
    my $limit = $c->request->param('limit');
    my $frequency_rs = $c->model('Golgi')->schema->resultset('MiseqAllelesFrequency')->search( { miseq_well_experiment_id => $miseq_well_experiment_hash->{id} });
    my $cou = $frequency_rs->count;
    my @lines;
    push @lines ,'Aligned Sequence,NHEJ,Unmodified,HDR,Deleted,Inserted,Mutated,Reads,%Reads';
    $limit = $cou if ($limit > $cou);
    if ($limit > 0){
            for my $i (1..$limit){
                my $hash = $frequency_rs->next->as_hash;
                my $sum = $hash->{n_reads};
                my $percentage = $sum/$miseq_well_experiment_hash->{total_reads}*100.0;
                push @lines, 
                    $hash->{aligned_sequence}   .",".   $hash->{nhej}                       .",".   
                    $hash->{unmodified}         .",".   $hash->{hdr}                        .",".
                    $hash->{n_deleted}          .",".   $hash->{n_inserted}                 .",".
                    $hash->{n_mutated}          .",".   $hash->{n_reads}                    .",".
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





sub get_miseq_well_experiment_hash{
    my ($c, $miseq, $well, $exp) = @_;
my $tmp;
    my $model = LIMS2::Model->new({ user => 'tasks' });
    

    #First, extract the plate_id, using the miseq name
    
    my $plate_rs = $c->model('Golgi')->schema->resultset('Plate')->search({ name => $miseq });
    my $plate_hash;
    my $plate;
    if ($plate_rs->count > 1) {
        print("Search returned multiple plates for given id \n");
        next;
    }
    elsif ($plate_rs->count <  1){
        print("Search returned empty \n");
        next;
    }

    else{
        $plate = $plate_rs->first;
        $plate_hash =$plate->as_hash;
    }
$tmp = $plate_hash->{id};

    #Then get the miseq plate id

    my $miseq_plate_hash;
    $miseq_plate_hash = $plate->miseq_details;
   
$tmp = $miseq_plate_hash->{id};

#Plate id to well name gives well

    my $well_hash;
    my $well_name = convert_index_to_well_name($well);  
    my $well_rs = $c->model('Golgi')->schema->resultset('Well')->search(
        {   -and => 
            [
                'plate_id' => $plate_hash->{id},
                'name'     => $well_name         
            ]
        });
        
    if ($well_rs->count > 1) {
        print("Search returned multiple wells for given plate id and well name \n");
        next;
    }
    elsif ($well_rs->count <  1){
        print("Search returned empty \n");
        next;
    }
    else{
        $well_hash = $well_rs->first->as_hash;
    }
$tmp = $well_hash->{id};

#Query miseq experiment for name(extracted from the path and converted) and plate id

    my $miseq_experiment_hash; 
    my $miseq_experiment_rs = $c->model('Golgi')->schema->resultset('MiseqExperiment')->search(
        {   -and =>
            [   
                'miseq_id' => $miseq_plate_hash->{id},
                'name'     => $exp                    
            ]
        }
    );
    if ($miseq_experiment_rs->count > 1) {
        print("Search returned multiple miseq experiments for given miseq id and experiment name \n");
        next;
    }
    elsif ($miseq_experiment_rs->count <  1){
        print("Search returned empty \n");
        next;
    }
    else{
        $miseq_experiment_hash = $miseq_experiment_rs->first()->as_hash;
    }

$tmp = $miseq_experiment_hash->{id};
    #Finally, query miseq well experiment for miseq experiment id and well id to get the miseq well experiment id.

    my $miseq_well_experiment_hash; 
    my $miseq_well_experiment_rs = $c->model('Golgi')->schema->resultset('MiseqWellExperiment')->search(
        {   -and =>
            [
                'miseq_exp_id'    => $miseq_experiment_hash->{id} ,
                'well_id'         => $well_hash->{id}
            ]
        }
    );
    if ($miseq_well_experiment_rs->count > 1) {
       print("Search returned multiple miseq well experiments for given miseq experiment id and well id \n");
       next;
    }
    elsif ($miseq_well_experiment_rs->count <  1){
       print("Search returned empty \n");
       next;
    }
    else{
       $miseq_well_experiment_hash = $miseq_well_experiment_rs->first->as_hash;
   } 
$tmp = $miseq_well_experiment_hash->{id};
    return $miseq_well_experiment_hash;
}

1;
