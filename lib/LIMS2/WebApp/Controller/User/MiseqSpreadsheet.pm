package LIMS2::WebApp::Controller::User::MiseqSpreadsheet;
use Moose;
use namespace::autoclean;
use Carp;
use LIMS2::Model::Util::Miseq qw/wells_generator/;
use List::Util qw/min max/;
use Text::CSV;
use LIMS2::Model::Util::CrispressoSubmission qw( get_eps_for_plate );

BEGIN { extends 'Catalyst::Controller' }

sub download : Path('/user/miseqspreadsheet/download' ) : Args(0) {
    my ( $self, $c ) = @_;
    my $plate_id = $c->request->param('plate');
    $c->log->debug("Getting eps for plate $plate_id");
    my $eps = get_eps_for_plate( $c->model('Golgi'), $plate_id );
    $c->response->status(200);
    $c->response->content_type('text/csv');
    $c->response->header(
        'Content-Disposition' => "attachment; filename=plate_$plate_id.csv" );
    my @columns = qw/name gene crispr strand amplicon min_index max_index hdr/;
    my $csv = Text::CSV->new( { binary => 1, sep_char => q/,/, eol => "\n" } );
    my $output;
    open my $fh, '>', \$output or croak 'Could not create file for download';
    $csv->print( $fh,
        [qw/Experiment Gene Crispr Strand Amplicon min_index max_index HDR/] );

    foreach my $ep ( sort keys %{$eps} ) {
        $csv->print( $fh, [ map { $eps->{$ep}->{$_} } @columns ] );
    }
    close $fh or croak 'Could not close file for download';
    $c->response->body($output);
    return;
}

__PACKAGE__->meta->make_immutable;

1;

