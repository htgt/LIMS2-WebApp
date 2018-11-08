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

use LIMS2::Model::Util::Miseq qw( wells_generator find_file find_folder read_file_lines );

BEGIN {extends 'LIMS2::Catalyst::Controller::REST'; }

sub point_mutation_image : Path( '/api/point_mutation_img' ) : Args(0) : ActionClass( 'REST' ) {
}

sub point_mutation_image_GET {
    my ( $self, $c ) = @_;

    my %whitelist = (
        '1b.Indel_size_distribution_percentage.png' => 1,
        '2.Unmodified_NHEJ_pie_chart.png'           => 1,
    );

    $c->assert_user_roles('read');

    my $miseq = $c->request->param('miseq');
    my $oligo_index = $c->request->param('oligo');
    my $experiment = $c->request->param('exp');
    my $file_name = $c->request->param('name');

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

sub point_mutation_summary : Path( '/api/point_mutation_summary' ) : Args(0) : ActionClass( 'REST' ) {
}

sub point_mutation_summary_GET {
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


1;
