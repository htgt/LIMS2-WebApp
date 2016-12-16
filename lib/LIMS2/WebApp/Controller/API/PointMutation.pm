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
    my $oligo_index = $c->request->param( 'oligo' );
    my $experiment = $c->request->param( 'experiment');
    my $file_name = $c->request->param( 'name' );
    
    #Sanitise inputs since it's a broad search
    unless (exists($whitelist{$file_name})) {
        $c->response->status( 406 );
        $c->response->body( "File name: " . $file_name . " is not acceptable. This query has been terminated.");
        return;
    }

    my $graph_dir = find_file($oligo_index, $experiment, $file_name);
    
    open (IMAGE, $graph_dir) or die "$!";
    my $raw_string = do{ local $/ = undef; <IMAGE>; };
    close IMAGE;
    
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
$DB::single=1;    
    $c->assert_user_roles('read');
    my $oligo_index = $c->request->param( 'oligo' );
    my $experiment = $c->request->param( 'experiment' );
    my $limit = $c->request->param( 'limit' );
    
    my $sum_dir = find_file($oligo_index, $experiment, 'Alleles_frequency_table.txt');
    my $fh;
    open ($fh, $sum_dir) or die "$!";
    my @lines = read_file_lines($fh);
    close $fh;
    
    my $body;
    if ($limit) {
        $body = join("\n", @lines[0..$limit]);
    } else {
        $body = join("\n", @lines);
    }

    $c->response->status( 200 );
    $c->response->content_type( 'text/plain' );
    $c->response->body( $body );

    return;
}

sub point_mutation_target_region : Path( '/api/point_mutation_target_region' ) : Args(0) : ActionClass( 'REST' ) {
}

sub point_mutation_target_region_GET {
    my ( $self, $c ) = @_;
$DB::single=1;    
    $c->assert_user_roles('read');
    my $oligo_index = $c->request->param( 'oligo' );
    my $experiment = $c->request->param( 'experiment' );
    
    my $sum_dir = find_file($oligo_index, $experiment, 'job.out');
    my $fh;
    open ($fh, $sum_dir) or die "$!";
    my @lines = read_file_lines($fh, 1);
    close $fh;
    
    my @targets = ($lines[40] =~ qr/\-g\s(\w+)\Z/);
    my $fwd = $targets[0];
    my $rev = revcom_as_string($fwd);
    my $body = "Forward: " . $fwd . "\nRevcom: " . $rev;
    $c->response->status( 200 );
    $c->response->content_type( 'text/plain' );
    $c->response->body( $body );

    return;
}
sub find_file {
    my ($index, $exp, $file) = @_;
    
    my $base = $ENV{LIMS2_RNA_SEQ} . 'S' . $index . '_exp' . $exp;
    
    my $charts = [];
    my $wanted = sub { _wanted($charts, $file) };

    find($wanted, $base);
    
    return @$charts[0];
}

sub _wanted {
   return if ! -e; 
   my ($charts, $file_name) = @_;

   push( @$charts, $File::Find::name ) if $File::Find::name=~ /$file_name/;
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
