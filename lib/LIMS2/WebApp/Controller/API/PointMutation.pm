package LIMS2::WebApp::Controller::API::PointMutation;
use Moose;
use Hash::MoreUtils qw( slice_def );
use namespace::autoclean;
use JSON;
use File::Find;
use Image::PNG;
use File::Slurp;
use MIME::Base64;
use Bio::Perl;
use POSIX;

use LIMS2::Model::Util::Miseq qw( miseq_plate_from_json );

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

sub point_mutation_frameshifts : Path( '/api/point_mutation_frameshifts' ) : Args(0) : ActionClass( 'REST' ) {
}

sub point_mutation_frameshifts_GET {
    my ( $self, $c ) = @_;
    my $miseq = $c->request->param('miseq');

    my $miseq_id = $c->model('Golgi')->schema->resultset('MiseqProject')->find({ name => $miseq })->id;
    my $miseq_wells = $c->model('Golgi')->schema->resultset('MiseqProjectWell')->search({ 'miseq_plate_id' => $miseq_id });#->search_related('miseq_well',{ 'miseq_plate_id' => $miseq_id });
    my $summary;
    while (my $well = $miseq_wells->next) {
        my $exp = $well->search_related('miseq_project_well_exps',{ frameshifted => 't' });
        if ($exp) {
            while (my $current_exp = $exp->next) {
                push (@{$summary->{$current_exp->experiment}}, $well->illumina_index);
            }
        }
    }

    my $json = JSON->new->allow_nonref;
    my $body = $json->encode($summary);


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
}

sub miseq_plate : Path( '/api/miseq_plate' ) : Args(0) : ActionClass( 'REST' ) {
}

sub miseq_plate_POST {
    my ( $self, $c ) = @_;
    $c->assert_user_roles('edit');
    my $protocol = $c->req->headers->header('X-FORWARDED-PROTO') // '';
$DB::single=1;

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

    my $miseq = $c->model('Golgi')->upload_miseq_plate($c, $data);
    
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
            $res->{crispr} = @$exp[2];
            $res->{position} = $index;
        }
    }

    return $res;
}

sub find_file {
    my ($miseq, $index, $exp, $file) = @_;
    my $base = $ENV{LIMS2_RNA_SEQ} . $miseq . '/S' . $index . '_exp' . $exp;

    my $charts = [];
    my $wanted = sub { _wanted($charts, $file) };

    find($wanted, $base);

    return @$charts[0];
}

sub _wanted {
    return if ! -e;
    my ($charts, $file_name) = @_;

    push( @$charts, $File::Find::name ) if $File::Find::name =~ /$file_name/;

    return;
}

sub read_file_lines {
    my ($fh, $plain) = @_;

    my @data;
    my $count = 0;
    while (my $row = <$fh>) {
        chomp $row;
        if ($plain) {
            push(@data, $row);
        } else {
            push(@data, join(',', split(/\t/,$row)));
        }
        $count++;
    }

    return @data;
}
1;
