package LIMS2::WebApp::Controller::API::Report;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::API::Report::VERSION = '0.466';
}
## use critic

use Moose;
use MooseX::Types::Path::Class;
use LIMS2::Report;
use namespace::autoclean;
use List::MoreUtils qw(firstidx);
use Text::CSV;
use TryCatch;
use LIMS2::Model::Util::GenesForSponsor;

BEGIN {extends 'LIMS2::Catalyst::Controller::REST'; }

=head1 NAME

LIMS2::WebApp::Controller::API::Report - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub report_ready :Path( '/api/report/ready' ) :Args(1) :ActionClass('REST') {
}

sub report_ready_GET {
    my ( $self, $c, $report_id ) = @_;

    $c->assert_user_roles( 'read' );

    my $status = LIMS2::Report::get_report_status( $report_id );
    return $self->status_ok( $c, entity => { status => $status } );
}

sub confluence_report :Path( '/api/confluence/report' ) :Args(0) :ActionClass('REST') {
}

sub confluence_report_GET {
    my ( $self, $c ) = @_;

    ## compile cached reports for Pipeline II genes
    my $server_path = $c->uri_for('/');
    my $cache_server;

    for ($server_path) {
        if    (/^http:\/\/www.sanger.ac.uk\/htgt\/lims2\/$/) { $cache_server = 'production/'; }
        elsif (/http:\/\/www.sanger.ac.uk\/htgt\/lims2\/+staging\//) { $cache_server = 'staging/'; }
        elsif (/http:\/\/t87-dev.internal.sanger.ac.uk:(\d+)\//) { $cache_server = "$1/"; }
        else  { die 'Error finding path for cached sponsor report'; }
    }

    my $sponsor_genes_instance = LIMS2::Model::Util::GenesForSponsor->new({
            model => $c->model('Golgi'),
            targeting_type => 'single_targeted',
            species_id => 'Human'
        });

    my @pipeline_ii_sponsors;
    my @unedited_pipeline_ii_sponsors = @{$sponsor_genes_instance->pipeline_ii_sponsors};
    #map { $_ =~ s/ /_/g } @pipeline_ii_sponsors;# perlcritic complains if map is used
    foreach my $sponsor (@unedited_pipeline_ii_sponsors) {
        $sponsor =~ s/ /_/g;
        push @pipeline_ii_sponsors, $sponsor;
    }

    ## prepare gene data
    my @lines_out;
    my $data_header;
    foreach my $csv_name (@pipeline_ii_sponsors) {

        try {
            my $cached_file_name = '/opt/t87/local/report_cache/lims2_cache_fp_report/' . $cache_server . $csv_name . '.csv';
            my $fh;

            my $csv = Text::CSV->new ({
            });

            open ($fh, '<:encoding(UTF-8)', $cached_file_name) or die "$!";
            $data_header = $csv->getline ($fh);
            while (my $row = $csv->getline($fh)) {
                push (@lines_out, $row);
            }
            close $fh;
        }
    }

    my @data_col_names = @{$data_header};

    my @idx_to_rm;
    my @idx_to_edit;

    my $tick_symbol = "&#10004;";
    my $cross_symbol = "&#10005;";

    ## start compiling the HTML response
    my $html = <<"END_QUOTE";
<!DOCTYPE html>
<html lang="en">

<head>
</head>

<body>
<div style="width:700px;border:1px solid black;margin:0 auto;"><input class="input-lg" style="padding:5px;margin:5px;" type="text" id="myInput" onkeyup="get_genes()" placeholder="Search ..." autofocus><i style="font-size:20px;"" class="glyphicon glyphicon-search"></i></div>
<div style="overflow:auto;width:700px;height:500px;border:1px solid black;margin:0 auto;"><table id="myTable" class="table table-bordered table-condensed">
END_QUOTE

    $html .= '<thead>';

    my @colnames_to_rm = ("crispr plasmids constructed", "ordered vector primers", "PCR-passing design oligos", "donor vectors constructed", "DNA source vector", "priority");
    my @colnames_to_edit = ("gene id", "gene symbol", "chr", "sponsor(s)", "info");

    ## table header
    foreach my $elem (@data_col_names) {
        if ( grep {$_ eq $elem} @colnames_to_rm ) {
            my $idx = firstidx { $_ eq $elem } @data_col_names;
            push @idx_to_rm, $idx;
        } elsif ( grep {$_ eq $elem} @colnames_to_edit ) {
            my $idx = firstidx { $_ eq $elem } @data_col_names;
            push @idx_to_edit, $idx;
            $html .= '<th class="bg-primary" style="text-align:center;">'.$elem.'</th>';
        } else {
            $html .= '<th class="bg-primary" style="text-align:center;">'.$elem.'</th>';
        }
    }

    $html .= '</thead>';

    ## table content
    foreach my $line_ref (@lines_out) {
        $html .= '<tr>';
        my $counter = 0;
        my @line_elems = @{$line_ref};
        foreach my $cell (@line_elems) {
            if ( grep {$_ == $counter} @idx_to_rm ) {
                $counter++;
                next;
            } elsif ( grep {$_ == $counter} @idx_to_edit ) {
                $html .= '<td class="bg-info"><span style="padding:5px;">'.$cell.'</span></td>';
                $counter++;
            } elsif ($cell) {
                $html .= '<td class="bg-info"><span style="color:green;">'.$tick_symbol.'</span></td>';
                $counter++;
            } else {
                $html .= '<td class="bg-info"><span style="color:red;">'.$cross_symbol.'</span></td>';
                $counter++;
            }
        }
        $html .= '<tr>';
    }

    $html .= '</table></div><br/><br />';

    ## Javascript code for searching the table by gene name
    $html .= <<"END_QUOTE";
<script>
function get_genes() {
    var input, filter, table, tr, td, i;
    input = document.getElementById("myInput");
    filter = input.value.toUpperCase();
    table = document.getElementById("myTable");
    tr = table.getElementsByTagName("tr");

    for (i=0; i<tr.length; i++) {
        td = tr[i].getElementsByTagName("td")[1];
        if (td) {
            if (td.innerHTML.toUpperCase().indexOf(filter) > -1){
                tr[i].style.display ="";
            } else {
                tr[i].style.display = "none";
            }
        }
    }
}
</script>

<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.2.0/jquery.min.js"></script>
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css">
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap-theme.min.css">
<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"></script>

</body>
</html>
END_QUOTE

    $c->response->status( 200 );
    $c->response->content_type( 'text/html' );
    $c->response->body( $html );

    return 1;
}

=head1 AUTHOR

Ray Miller et al.

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
