package LIMS2::WebApp::Controller::PublicReports;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::PublicReports::VERSION = '0.517';
}
## use critic


use Moose;
use LIMS2::Report;
use Try::Tiny;
use Data::Printer;
use LIMS2::Model::Util::EngSeqParams qw( generate_well_eng_seq_params );
use LIMS2::Model::Util::CrisprESQCView qw(crispr_damage_type_for_ep_pick);
use LIMS2::Model::Util::Crisprs qw( crisprs_for_design );
use LIMS2::Model::Util::Crisprs qw( get_crispr_group_by_crispr_ids );
use LIMS2::Model::Util::Miseq qw( miseq_genotyping_info );
use LIMS2::Model::Util::SponsorReportII;

use List::MoreUtils qw( uniq );
use namespace::autoclean;
#use experimental qw(switch);
use feature 'switch';
use Text::CSV_XS;
use LIMS2::Model::Util::DataUpload qw/csv_to_spreadsheet/;
use Excel::Writer::XLSX;
use File::Slurp;
use LIMS2::Report qw/get_raw_spreadsheet/;
use JSON qw( decode_json encode_json );
use File::stat;
use POSIX 'strftime';
use Data::Dumper;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::PublicReports - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller for reports that a un-authenticated user can access.

=cut

sub begin : Private {
    my ( $self, $c ) = @_;

    my $protocol = $c->req->headers->header('X-FORWARDED-PROTO') // '';
    if($protocol eq 'HTTPS'){
        my $base = $c->req->base;
        $base =~ s/^http:/https:/;
        $c->req->base(URI->new($base));
        $c->req->secure(1);
    }

    $c->require_ssl;

    return;
}

=head2 index

List of public reports

=cut
sub index : Path( '/public_reports' ) : Args(0) {
    my ( $self, $c ) = @_;

    return;
}

=head2 cre_knockin_project_status

Report listing the status of cre knockin projects.

=cut
sub cre_knockin_project_status : Path( '/public_reports/cre_knockin_project_status' ) : Args(0) {
    my ( $self, $c ) = @_;

    my $report_id = LIMS2::Report::cached_report(
        model  => $c->model( 'Golgi' ),
        report => 'LegacyCreKnockInProjects',
        params => {},
    );

    $c->stash(
        template    => 'publicreports/await_report.tt',
        report_name => 'Cre_KnockIn_Project_Status',
        report_id   => $report_id,
    );

    return;
}

=head2 download_report

Downloads a csv report of a given report_id

=cut


sub download_report_csv :Path( '/public_reports/download' ) :Args(1) {
    my ( $self, $c, $report_id ) = @_;

    $c->assert_user_roles( 'read' );

    my ( $report_name, $report_fh ) = LIMS2::Report::read_report_from_disk( $report_id );
    $report_name =~ s/\s/_/g;

    $c->response->status( 200 );
    $c->response->content_type( 'text/csv' );
    $c->response->header( 'Content-Disposition' => "attachment; filename=$report_name.csv" );
    $c->response->body( $report_fh );
    return;
}

sub download_report_xlsx :Path( '/public_reports/download_xlsx' ) :Args(1) {
    my ( $self, $c, $report_id ) = @_;
    $c->assert_user_roles( 'read' );

    my ( $report_name, $report_fh ) = LIMS2::Report::read_report_from_disk( $report_id );
    $report_name =~ s/\s/_/g;
    my $file = csv_to_spreadsheet($report_name, $report_fh);

    $c->response->status( 200 );
    $c->response->content_type( 'application/xlsx' );
    $c->response->content_encoding( 'binary' );
    $c->response->header( 'content-disposition' => 'attachment; filename=' . $file->{name} );
    $c->response->body( $file->{file} );
    return;

}
=head2 download_compressed

Generates a gzipped file for download, and downloads it

=cut

sub download_compressed :Path( '/public_reports/download_compressed' ) :Args(1) {
    my ( $self, $c, $report_id ) = @_;

    my ( $report_name, $compressed_fh ) = LIMS2::Report::compress_report_on_disk( $report_id );

    $c->response->status( 200 );
    $c->response->content_type( 'text/gzip' );
#    $c->response->content_encoding( 'gzip' );
    $c->response->header( 'Content-Disposition' => "attachment; filename=$report_name.csv.gz" );
    $c->response->body( $compressed_fh );
    return;
}


=head2 cre_knockin_project_status

Report listing the status of cre knockin projects.

=cut
sub allele_dump : Path( '/public_reports/allele_dump' ) : Args(0) {
    my ( $self, $c ) = @_;

    my $report_id = LIMS2::Report::cached_report(
        model  => $c->model( 'Golgi' ),
        report => 'AlleleDump',
        params => {},
    );

    $c->stash(
        template    => 'publicreports/await_report.tt',
        report_name => 'Allele_Dump',
        report_id   => $report_id
    );

    return;
}

sub access_denied : Path( '/public_reports/access_denied' ) {

    my ( $self, $c ) = @_;

    return;
}

=head2 index

=cut
sub sponsor_report :Path( '/public_reports/sponsor_report' ) {
    my ( $self, $c, $targeting_type ) = @_;

    if (! $targeting_type) {
        $targeting_type = 'single_targeted';
    }

    my $species;
    my $cache_params = {
        sub_cache_param_i  => 'with_cache',
        sub_cache_param_ii => 'with_cache',
        top_cache_param_i  => 'with_cache',
        top_cache_param_ii => 'with_cache',
    };

    my $is_internal = 0;
    my $client_host = $c->request->hostname;

    if ($c->user_exists) {
        $c->request->params->{'species'} = $c->session->{'selected_species'};
        $is_internal = 1;

        if ( $c->request->params->{'cache_param_i'} ) {
            $cache_params->{sub_cache_param_i} = $c->request->params->{'cache_param_i'};
            $cache_params->{top_cache_param_i} = $c->request->params->{'cache_param_i'};
        }
        if ( $c->request->params->{'cache_param_ii'} ) {
            $cache_params->{sub_cache_param_ii} = $c->request->params->{'cache_param_ii'};
            $cache_params->{top_cache_param_ii} = $c->request->params->{'cache_param_ii'};
        }
    }

    if ( $client_host =~ /internal/ ) {
        $is_internal = 1;
    }

    if (!$c->request->params->{'species'}) {
        $c->request->params->{'species'} = 'Human';
    }

    $species = $c->request->params->{'species'};
    $c->session->{'selected_species'} = $species;

    if ( $cache_params->{top_cache_param_i} eq  'with_cache' ) {

        try {
            my $file = lc $species . '_pipeline_i';
            my $top_level_data = $self->_view_cached_top_level_report( $c, $file );

            my $report_id   = $top_level_data->{ report_id };
            my $title       = $top_level_data->{ title };
            my $title_ii    = $top_level_data->{ title_ii };
            my $columns     = $top_level_data->{ columns };
            my $rows        = $top_level_data->{ rows };
            my $data        = $top_level_data->{ data };

            $c->stash(
              'report_id'      => $report_id,
              'title'          => 'Pipeline I Summary Report (Human, single_targeted projects) on ' . $top_level_data->{date},
              'species'        => $species,
              'targeting_type' => $targeting_type,
              'cache_param_i'  => 'with_cache',
              'cache_param_ii' => $cache_params->{top_cache_param_ii},
              'columns'        => $columns,
              'rows'           => $rows,
              'data'           => $data,
            );
        } catch {
            $self->_generate_front_page_report_pipeline_i ( $c, 'single_targeted', $species );
        };
    }
    else {
        $self->_generate_front_page_report_pipeline_i ( $c, 'single_targeted', $species );
    }

    if ( $cache_params->{top_cache_param_ii} eq 'with_cache' ) {

        try {
            my $file = lc $species . '_pipeline_ii';
            my $top_level_data = $self->_view_cached_top_level_report( $c, $file );

            my $pipeline_ii_data = $top_level_data->{ pipeline_ii_report };
            my $title_ii = $top_level_data->{ title_ii };
            my $programmes = $top_level_data->{ programmes };
            my $pipeline_ii_total_gene_count = $top_level_data->{ pipeline_ii_total_gene_count };

            $c->stash(
                'title_ii'                     => $title_ii,
                'pipeline_ii_report'           => $pipeline_ii_data,
                'programmes'                   => $programmes,
                'pipeline_ii_total_gene_count' => $pipeline_ii_total_gene_count,
                'targeting_type'               => $targeting_type,
                'species'                      => $species,
                'cache_param_ii'               => 'with_cache',
                'cache_param_i'                => $cache_params->{top_cache_param_i},
            );
        } catch {
            $self->_generate_front_page_report_pipeline_ii ( $c, 'single_targeted', $species, $cache_params->{top_cache_param_i} );
        };
    }
    else {
        $self->_generate_front_page_report_pipeline_ii ( $c, 'single_targeted', $species, $cache_params->{top_cache_param_i} );
    }

    $c->stash(
        template    => 'publicreports/sponsor_report.tt',
        is_internal => $is_internal,
    );

    return;
}

sub _view_cached_top_level_report {
    my ( $self, $c, $name ) = @_;

    my $server_path = $c->uri_for('/');
    my $cache_server;

    given ($server_path) {
        when (/^https:\/\/www.sanger.ac.uk\/htgt\/lims2\/$/) { $cache_server = 'production/'; }
        when (/https:\/\/www.sanger.ac.uk\/htgt\/lims2\/+staging\//) { $cache_server = 'staging/'; }
        when (/http:\/\/t87-dev.internal.sanger.ac.uk:(\d+)\// || /http:\/\/t87-dev-farm3.internal.sanger.ac.uk:(\d+)\//) { $cache_server = "$1/"; }
        when (/http:\/\/\S+/) { $cache_server = 'localhost/'; }
        default  { die 'Error finding path for cached sponsor report'; }
    }

    my $cached_file_name = '/opt/t87/local/report_cache/lims2_cache_fp_report/' . $cache_server . $name . '.json';

    open( my $json_handle, "<:encoding(UTF-8)", $cached_file_name ) or die "unable to open cached file ($cached_file_name): $!";
    my $file_stats = stat $cached_file_name or die "$cached_file_name not found: $!";

    my $json_data = decode_json(<$json_handle>);
    close $json_handle;

    my $date_format = strftime '%d %B %Y', localtime $file_stats->mtime;
    $json_data->{date} = $date_format;

    return $json_data;

}

sub _generate_front_page_report_pipeline_i {
    my ( $self, $c, $targeting_type, $species, $cache_param_ii ) = @_;

    # Call ReportForSponsors plugin to generate report
    my $sponsor_report = LIMS2::Model::Util::ReportForSponsors->new({
            'species' => $species,
            'model' => $c->model( 'Golgi' ),
            'targeting_type' => $targeting_type,
        });
    my $report_params = $sponsor_report->generate_top_level_report_for_sponsors();

    # Fetch details from returned report parameters
    my $report_id   = $report_params->{ report_id };
    my $title       = $report_params->{ title };
    my $columns     = $report_params->{ columns };
    my $rows        = $report_params->{ rows };
    my $data        = $report_params->{ data };

    my %return_params = (
        'report_id'      => $report_id,
        'title'          => $title,
        'columns'        => $columns,
        'rows'           => $rows,
        'data'           => $data,
    );

    my $json_data = encode_json(\%return_params);
    my $file_name = lc $species . '_pipeline_i';
    save_json_report($c->uri_for('/'), $json_data, $file_name);

    # Store report values in stash for display onscreen
    $c->stash(
        'report_id'          => $report_id,
        'title'              => $title,
        'species'            => $species,
        'targeting_type'     => $targeting_type,
        'cache_param_i'      => 'without_cache',
        'cache_param_ii'     => $cache_param_ii,
        'columns'            => $columns,
        'rows'               => $rows,
        'data'               => $data,
    );

    return;
}

sub _generate_front_page_report_pipeline_ii {
    my ( $self, $c, $targeting_type, $species, $cache_param_i ) = @_;

    my $pipeline_ii_report = LIMS2::Model::Util::SponsorReportII->new({
        species => $species,
        model   => $c->model('Golgi'),
        targeting_type => $targeting_type,
    });

    my $pipeline_ii_data = $pipeline_ii_report->sponsor_gene_count;
    my $pipeline_ii_title = $pipeline_ii_report->build_page_title;
    my $programmes = $pipeline_ii_report->programmes;
    my $pipeline_ii_total_gene_count = $pipeline_ii_report->total_gene_count;

    my %return_params = (
        'title_ii'                     => $pipeline_ii_title,
        'pipeline_ii_report'           => $pipeline_ii_data,
        'programmes'                   => $programmes,
        'pipeline_ii_total_gene_count' => $pipeline_ii_total_gene_count,
    );

    my $json_data = encode_json(\%return_params);
    my $file_name = lc $species . '_pipeline_ii';
    save_json_report($c->uri_for('/'), $json_data, $file_name);

    $c->stash(
        'title_ii'                     => $pipeline_ii_title,
        'pipeline_ii_report'           => $pipeline_ii_data,
        'programmes'                   => $programmes,
        'pipeline_ii_total_gene_count' => $pipeline_ii_total_gene_count,
        'cache_param_ii'               => 'without_cache',
        'cache_param_i'                => $cache_param_i,
        'species'                      => $species,
        'targeting_type'               => $targeting_type,
    );

    return;
}

sub save_json_report {
    my $uri = shift;
    my $json_data = shift;
    my $name = shift;

    my $cache_server;

    given ($uri) {
        when (/^https:\/\/www.sanger.ac.uk\/htgt\/lims2\/$/) { $cache_server = 'production/'; }
        when (/https:\/\/www.sanger.ac.uk\/htgt\/lims2\/+staging\//) { $cache_server = 'staging/'; }
        when (/http:\/\/t87-dev.internal.sanger.ac.uk:(\d+)\//) { $cache_server = "$1/"; }
        when (/http:\/\/\S+/) { $cache_server = 'localhost/'; }
        default  { die 'Error finding path for cached sponsor report'; }
    }

    my $cached_file_name = '/opt/t87/local/report_cache/lims2_cache_fp_report/' . $cache_server . $name . '.json';

    open( my $json_fh, ">:encoding(UTF-8)", $cached_file_name ) or die "Can not open file: $!";
    print $json_fh $json_data;
    close ($json_fh);
    chmod 0777, $cached_file_name;

    return;
}

sub view_cached_csv : Path( '/public_reports/cached_sponsor_csv' ) : Args(1) {
    my ( $self, $c, $sponsor_id ) = @_;

    $sponsor_id =~ s/\ /_/g;
    my $body = $self->_view_cached_csv($c, $sponsor_id);
    return $c->response->body($body);
}

sub convert_cached_csv : Path( '/public_reports/cached_sponsor_xlsx' ) : Args(1) {
    my ( $self, $c, $sponsor_id ) = @_;

    $sponsor_id =~ s/\ /_/g;
    my $body = $self->_view_cached_csv($c, $sponsor_id);

    $body = get_raw_spreadsheet($sponsor_id, $body);
    $c->response->status( 200 );
    $c->response->content_type( 'application/xlsx' );
    $c->response->content_encoding( 'binary' );
    $c->response->header( 'content-disposition' => 'attachment; filename=report.xlsx' );
    return $c->response->body($body);
}

sub _view_cached_csv {
    my $self = shift;
    my $c = shift;
    my $csv_name = shift;

    my $server_path = $c->uri_for('/');
    my $cache_server;

    for ($server_path) {
        if    (/^https?:\/\/www.sanger.ac.uk\/htgt\/lims2\/$/) { $cache_server = 'production/'; }
        elsif (/https?:\/\/www.sanger.ac.uk\/htgt\/lims2\/+staging\//) { $cache_server = 'staging/'; }
        elsif (/https?:\/\/t87-dev.internal.sanger.ac.uk:(\d+)\//) { $cache_server = "$1/"; }
        else  { die 'Error finding path for cached sponsor report'; }
    }

    my $cached_file_name = '/opt/t87/local/report_cache/lims2_cache_fp_report/' . $cache_server . $csv_name . '.csv';

    $c->response->status( 200 );
    $c->response->content_type( 'text/csv' );
    $c->response->header( 'Content-Disposition' => "attachment; filename=$csv_name.csv" );
    my @lines_out;
    open( my $csv_handle, "<:encoding(UTF-8)", $cached_file_name )
        or die "unable to open cached file ($cached_file_name): $!";
    while (<$csv_handle>) {
        if ( ! $c->user_exists ) {
            $_ = _filter_public_attributes( $_ );
        }
        push @lines_out, $_;
    }
    close $csv_handle
        or die "unable to close cached file: $!";

    return join( '', @lines_out );
}


# some fields should not be present in the publicly available CSV file

sub _filter_public_attributes {
    my $line = shift;

    my $mod_line;
    # match anything except the last comma separated field (the info field).
    if ( $line =~ /^(.*),.*$/xgms ) {
        $mod_line = $1;
    }

#    /^(.*),.*$/xgms
#        ^ assert position at start of a line
#        1st Capturing group (.*)
#            .* matches any character
#                Quantifier: * Between zero and unlimited times, as many times as possible, giving back as needed [greedy]
#        , matches the character , literally
#        .* matches any character
#            Quantifier: * Between zero and unlimited times, as many times as possible, giving back as needed [greedy]
#        $ assert position at end of a line
#        x modifier: extended. Spaces and text after a # in the pattern are ignored
#        g modifier: global. All matches (don't return on first match)
#        m modifier: multi-line. Causes ^ and $ to match the begin/end of each line (not only begin/end of string)
#        s modifier: single line. Dot matches newline characters

    return $mod_line . "\n";
}


sub view : Path( '/public_reports/sponsor_report' ) : Args(3) {
    my ( $self, $c, $targeting_type, $sponsor_id, $stage ) = @_;

    # expecting :
    # targeting type i.e. 'st' or 'dt' for single- or double-targeted
    # sponsor id is the project sponsor e.g. Syboss, Pathogens
    # stage is the level e.g. genes, DNA

    # depending on combination of targeting type and stage fetch details

    my $species = $c->session->{selected_species};
    my $lab_head = $c->request->params->{'lab_head'};
    my $programme = $c->request->params->{'programme'};

    $c->stash->{no_wrapper} = 1;
    my $cache_param = $c->request->params->{'cache_param'};
    my $pipeline = $c->request->params->{'pipeline'};

    if ($c->request->params->{generate_cache}) {
        $c->session->{display_type} = 'wide';
    } else {
        $c->session->{display_type} = 'default';
    }

    given ($pipeline) {

    when(/^pipeline_i$/) {
        my $sponsor_report = LIMS2::Model::Util::ReportForSponsors->new( {
                'species' => $species,
                'model' => $c->model( 'Golgi' ),
                'targeting_type' => $targeting_type,
            });

        my $report_params = $sponsor_report->generate_sub_report($sponsor_id, $stage);
         # Fetch details from returned report parameters
        my $report_id = $report_params->{ 'report_id' };
        my $disp_target_type = $report_params->{ 'disp_target_type' };
        my $disp_stage = $report_params->{ 'disp_stage' };
        my $columns = $report_params->{ 'columns' };
        my $display_columns = $report_params->{ 'display_columns' };
        my $data = $report_params->{ 'data' };

        my $link = "/public_reports/sponsor_report/$targeting_type/$sponsor_id/$stage";
        my $type;

        # csv download
        if ($c->request->params->{csv} || $c->request->params->{xlsx} ) {
            $c->response->status( 200 );
            my $body = join(',', map { $_ } @{$display_columns}) . "\n";

            my @csv_colums;
            if (@{$columns}[-1] eq 'ep_data') {
                @csv_colums = splice (@{$columns}, 0, -1);
            } else {
                @csv_colums = @{$columns};
            }
            foreach my $column ( @{$data} ) {
                $body .= join(',', map { $column->{$_} } @csv_colums ) . "\n";
            }
            if ($c->request->param('xlsx')) {
                $c->response->content_type( 'application/xlsx' );
                $c->response->content_encoding( 'binary' );
                $c->response->header( 'content-disposition' => 'attachment; filename=report.xlsx' );
                $body = get_raw_spreadsheet('report', $body);
            }
            else {
                $c->response->content_type( 'text/csv' );
                $c->response->header( 'Content-Disposition' => 'attachment; filename=report.csv');
            }
            $c->response->body( $body );
        }
        else {

            my $on_date;

            if ($disp_stage eq 'Genes') {

                $on_date = strftime '%d %B %Y', localtime time;

                if (! $c->request->params->{type}) {
                    $c->request->params->{type} = 'simple';
                }

                $type = $c->request->params->{type};

                if ($type eq 'simple') {
                    $data = $self->_simple_transform( $data );
                }
            }

            my $template = 'publicreports/sponsor_sub_report.tt';

            if ($sponsor_id eq 'Cre Knockin' || $sponsor_id eq 'EUCOMMTools Recovery' || $sponsor_id eq 'MGP Recovery' || $sponsor_id eq 'Pathogens' || $sponsor_id eq 'Syboss' || $sponsor_id eq 'Core' ) {
                $template = 'publicreports/sponsor_sub_report_old.tt';
            }
            # Store report values in stash for display onscreen
            $c->stash(
                'date'                 => $on_date,
                'template'             => $template,
                'report_id'            => $report_id,
                'disp_target_type'     => $disp_target_type,
                'targeting_type'       => $targeting_type,
                'disp_stage'           => $disp_stage,
                'sponsor_id'           => $sponsor_id,
                'columns'              => $columns,
                'display_columns'      => $display_columns,
                'data'                 => $data,
                'link'                 => $link,
                'type'                 => $type,
                'species'              => $species,
                'cache_param'          => $cache_param,
            );

            my $json_data = encode_json({
                'report_id'            => $report_id,
                'disp_target_type'     => $disp_target_type,
                'disp_stage'           => $disp_stage,
                'sponsor_id'           => $sponsor_id,
                'columns'              => $columns,
                'targeting_type'       => $targeting_type,
                'display_columns'      => $display_columns,
                'data'                 => $data,
                'link'                 => $link,
                'type'                 => $type,
                'species'              => $species,
                'cache_param'          => $cache_param,
                });

            $sponsor_id =~ s/\ /_/g;
            my $file = lc $sponsor_id . "_$pipeline";
            save_json_report($c->uri_for('/'), $json_data, $file);
        }

    }
    when(/^pipeline_ii$/) {
        $self->pipeline_ii_workflow($c, $targeting_type, $sponsor_id, $stage);
    }
}
    return;
}

sub pipeline_ii_workflow {
    my ( $self, $c, $targeting_type, $sponsor_id, $stage ) = @_;

    my $species = $c->session->{selected_species};
    my $lab_head = $c->request->params->{'lab_head'};
    my $programme = $c->request->params->{'programme'};
    my $cache_param = $c->request->params->{'cache_param'};
    my $pipeline = $c->request->params->{'pipeline'};

    my $pipeline_ii_report = LIMS2::Model::Util::SponsorReportII->new({
        species => $species,
        model   => $c->model('Golgi'),
        targeting_type => $targeting_type,
    });

    if ( $c->request->params->{'total'} ) {

        if ( $c->request->params->{csv} || $c->request->params->{xlsx} ) {

            my $sub_level_data = $self->_view_cached_top_level_report( $c, 'total_pipeline_ii' );

            $c->response->status( 200 );
            my $body = $pipeline_ii_report->save_file_data_format($sub_level_data->{data});

            if ($c->request->param('xlsx')) {
                $c->response->content_type( 'application/xlsx' );
                $c->response->content_encoding( 'binary' );
                $c->response->header( 'content-disposition' => 'attachment; filename=total_pipeline_ii.xlsx' );
                $body = get_raw_spreadsheet('total_pipeline_ii', $body);
            }
            else {
                $c->response->content_type( 'text/csv' );
                $c->response->header( 'Content-Disposition' => 'attachment; filename=total_pipeline_ii.csv');
            }
            $c->response->body( $body );

        } else {

            my $total_sub_report = $pipeline_ii_report->generate_total_sub_report();

            my $template = 'publicreports/sponsor_sub_report_ii.tt';

            $c->stash(
                template       => $template,
                columns        => $total_sub_report->{columns},
                data           => $total_sub_report->{data},
                date           => $total_sub_report->{date},
                targeting_type => $targeting_type,
                lab_head       => $lab_head,
                programme      => $programme,
                );

            my $json_data = encode_json({
                template       => $template,
                columns        => $total_sub_report->{columns},
                data           => $total_sub_report->{data},
                targeting_type => $targeting_type,
                lab_head       => $lab_head,
                programme      => $programme,
                });

            my $file = "total_$pipeline";
            save_json_report($c->uri_for('/'), $json_data, $file);

        }

        return;

    }


    if ( $c->request->params->{csv} || $c->request->params->{xlsx} ) {

        (my $current_file = $sponsor_id) =~ s/\s+/_/g;

        my $curr_file = lc $current_file . "_$pipeline";
        my $sub_level_data = $self->_view_cached_top_level_report( $c, $curr_file );

        $c->response->status( 200 );
        my $body = $pipeline_ii_report->save_file_data_format($sub_level_data->{data});

        if ($c->request->param('xlsx')) {
            $c->response->content_type( 'application/xlsx' );
            $c->response->content_encoding( 'binary' );
            $c->response->header( 'content-disposition' => 'attachment; filename=' . $current_file . '_pipeline_ii_report.xlsx' );
            $body = get_raw_spreadsheet($current_file, $body);
        }
        else {
            $c->response->content_type( 'text/csv' );
            $c->response->header( 'Content-Disposition' => 'attachment; filename=' . $current_file . '_pipeline_ii_report.csv');
        }
        $c->response->body( $body );

    } else {

        my $sub_report = $pipeline_ii_report->generate_sub_report($sponsor_id, $lab_head, $programme);
        my $template = 'publicreports/sponsor_sub_report_ii.tt';

        $c->stash(
            template       => $template,
            columns        => $sub_report->{columns},
            data           => $sub_report->{data},
            date           => $sub_report->{date},
            targeting_type => $targeting_type,
            sponsor_id     => $sponsor_id,
            programme      => $programme,
            lab_head       => $lab_head,
            cache_param    => $cache_param,
            );

        my $json_data = encode_json({
            template       => $template,
            columns        => $sub_report->{columns},
            data           => $sub_report->{data},
            targeting_type => $targeting_type,
            sponsor_id     => $sponsor_id,
            programme      => $programme,
            lab_head       => $lab_head,
            cache_param    => $cache_param
            });

        $sponsor_id =~ s/\ /_/g;
        my $file = lc $sponsor_id . "_$pipeline";
        save_json_report($c->uri_for('/'), $json_data, $file);
    }

    return;
}


sub add_ep_rows {
    my ($c, $column, $body, @csv_colums) = @_;
    my %keys = (
        'cell_line'           => 'EP_cell_line',
        'dna_template'        => 'DNA_source_cell_line',
        'ep_pick_count'       => 'colonies_picked',
        'ep_pick_pass_count'  => 'targeted_clones',
        'experiment'          => 'experiment_ID',
        'frameshift'          => 'fs_count',
        'in-frame'            => 'if_count',
        'mosaic'              => 'ms_count',
        'no-call'             => 'nc_count',
        'total_colonies'      => 'total_colonies',
        'wild_type'           => 'wt_count',
        'requester'           => 'requester',
    );
    my @expand_cols;
    foreach my $ep_col ( @{$column->{ep_data}} ) {
        push @expand_cols, $ep_col;
    }
    foreach my $ep_col ( @expand_cols ) {
        my $sub_col = {
            gene_id                 => $column->{gene_id},
            gene_symbol             => $column->{gene_symbol},
            chromosome              => $column->{chromosome},
            sponsors                => $column->{sponsors},
            crispr_wells            => ' ',
            accepted_crispr_vector  => ' ',
            vector_wells            => ' ',
            vector_pcr_passes       => ' ',
            passing_vector_wells    => ' ',
            electroporations        => ' ',
            ep_pick_het             => ' ',
            distrib_clones          => ' ',
            priority                => ' ',
            recovery_class          => ' ',
        }; #Reduces warnings
        foreach my $key (keys %{$ep_col}) {
            if ($key eq 'experiment') {
                $ep_col->{experiment} = join(', ', @{$ep_col->{experiment}});
            }
            $sub_col->{$keys{$key}} = $ep_col->{$key};
        }
        $body .= join(',', map { $sub_col->{$_} } @csv_colums ) . "\n";
    }
    return $body;
}

sub _simple_transform {
    my $self = shift;
    my $data = shift;

    foreach my $column ( @{$data} ) {
        while ( my ($key, $value) = each %{$column} ) {
            if (! ${$column}{$key}) {
                ${$column}{$key} = '';
            }
            else {
                ${$column}{$key} = '✔'
                unless ($key eq 'gene_id'
                    || $key eq 'gene_symbol'
                    || $key eq 'sponsors'
                    || $key eq 'ep_data'
                    || $key eq 'recovery_class'
                    || $key eq 'effort_concluded'
                    || $key eq 'priority'
                    || $key eq 'chromosome' );
            }
        }
    }
    return $data;
}

sub view_cached : Path( '/public_reports/cached_sponsor_report' ) : Args(1) {
    my ( $self, $c, $report_name ) = @_;

    $c->log->info( "Generate public detail report for : $report_name" );

    my $pipeline = $c->request->params->{pipeline};
    $report_name =~ s/\ /_/g;
    my $file = lc $report_name . "_$pipeline";

    try {
        my $sub_level_data = $self->_view_cached_top_level_report( $c, $file );

        my $template = 'publicreports/sponsor_sub_report.tt';

        if ($pipeline eq 'pipeline_ii') {
            $template = 'publicreports/sponsor_sub_report_ii.tt';
        }


        $c->stash(
          'template'             => $template,
          'date'                 => $sub_level_data->{date},
          'report_id'            => $sub_level_data->{report_id},
          'disp_target_type'     => $sub_level_data->{disp_target_type},
          'disp_stage'           => $sub_level_data->{disp_stage},
          'sponsor_id'           => $sub_level_data->{sponsor_id},
          'programme'            => $sub_level_data->{programme},
          'targeting_type'       => $sub_level_data->{targeting_type},
          'lab_head'             => $sub_level_data->{lab_head},
          'columns'              => $sub_level_data->{columns},
          'display_columns'      => $sub_level_data->{display_columns},
          'data'                 => $sub_level_data->{data},
          'link'                 => $sub_level_data->{link},
          'type'                 => $sub_level_data->{type},
          'species'              => $sub_level_data->{species},
          'cache_param'          => $sub_level_data->{cache_param},
        );
    } catch {
        $c->flash( info_msg => 'No cached data found. Switch to live and generate new values!');
        return $c->response->redirect( $c->uri_for('/public_reports/sponsor_report') );
    };

    return;
}

sub view_cached_simple : Path( '/public_reports/cached_sponsor_report_simple' ) : Args(1) {
    my ( $self, $c, $report_name ) = @_;
    $c->log->info( "Generate public detail report for : $report_name" );

    return $self->_view_cached_lines($c, $report_name, 1 );
}

sub _view_cached_lines {
    my $self = shift;
    my $c = shift;
    my $report_name = shift;
    my $simple = shift;

    my $server_path = $c->uri_for('/');
    my $cache_server;

    for ($server_path) {
        $c->log->debug($server_path);
        if    (/^https?:\/\/www.sanger.ac.uk\/htgt\/lims2\/$/) { $cache_server = 'production/'; }
        elsif (/https?:\/\/www.sanger.ac.uk\/htgt\/lims2\/+staging\//) { $cache_server = 'staging/'; }
        elsif (/https?:\/\/t87-dev.internal.sanger.ac.uk:(\d+)\// || /https?:\/\/t87-dev-farm3.internal.sanger.ac.uk:(\d+)\//) { $cache_server = "$1/"; }
        else  { die 'Error finding path for cached sponsor report'; }
    }

    my $suffix = '.html';
    if ($simple) {$suffix = '_simple.html'}
    $report_name =~ s/\ /_/g; # convert spaces to underscores in report name
    my $cached_file_name = '/opt/t87/local/report_cache/lims2_cache_fp_report/' . $cache_server . $report_name . $suffix;

    my @lines_out;
    open( my $html_handle, "<:encoding(UTF-8)", $cached_file_name )
        or die "unable to open cached file ($cached_file_name): $!";


    while (<$html_handle>) {
        push @lines_out, $_;
    }
    close $html_handle
        or die "unable to close cached file: $!";
    return $c->response->body( join( '', @lines_out ));
}

=head2 well_genotyping_info_search

Page to choose the desired well, no arguments

=cut
sub well_genotyping_info_search :Path( '/public_reports/well_genotyping_info_search' ) :Args(0) {
    my ( $self, $c ) = @_;

    $ENV{ LIMS2_URL_CONFIG } or die "LIMS2_URL_CONFIG environment variable not set";
    my $conf = Config::Tiny->read( $ENV{ LIMS2_URL_CONFIG } );
    my $email = $conf->{_}->{clone_request_email};

    $c->stash->{email} = $email;
    return;
}

=head2 well_genotyping_info

Page to display chosen well, takes a well id (later a barcode) or a plate/well combo

=cut
sub well_genotyping_info :Path( '/public_reports/well_genotyping_info' ) :Args() {
    my ( $self, $c, @args ) = @_;

    if ( @args == 1 ) {
        my $barcode = shift @args;
        my $well;

        try {
            $well = $c->model('Golgi')->retrieve_well( { barcode => $barcode } );
        } catch {
            $c->stash( error_msg => "Barcode doesn't exist" );
        };

        if ($well) {
            if ($well->design->type->id =~ /^miseq.*/) {
                $c->stash->{pipeline} = 2;
                $self->_stash_pipeline_ii_genotyping_info( $c, $well );
            } else {
                $self->_stash_well_genotyping_info( $c, $well );
            }
        } else {
            $c->go( 'well_genotyping_info_search' );
            return;
        }
    }
    elsif ( @args == 2 ) {
        my ( $plate_name, $well_name ) = @args;
        my $well;

        try {
            $well = $c->model('Golgi')->retrieve_well( { plate_name => $plate_name, well_name => $well_name } );
        };

        unless($well){
            try{ $well = $c->model('Golgi')->retrieve_well_from_old_plate_version( { plate_name => $plate_name, well_name => $well_name } ) };
            if($well){
                $c->stash->{info_msg} = ("Well ".$well->name." was not found on the current version of plate ".
                    $well->plate->name.". Reporting info for this well on version ".$well->plate->version
                    ." of the plate.");
            }
        }

        if ($well) {
            $self->_stash_well_genotyping_info( $c, $well );
        } else {
            try {
                my $plate_id = $c->model('Golgi')->retrieve_plate({ name => $plate_name })->id;
                my $barcode_id = $c->model('Golgi')->schema->resultset('BarcodeEvent')->find({ old_plate_id => $plate_id, old_well_name => $well_name, new_well_name => undef } )->barcode->barcode;
                $well = $c->model('Golgi')->retrieve_well( { barcode => $barcode_id } );
            } catch {
                $c->stash( error_msg => "Well doesn't exist" );
            };
        }

        if ($well) {
            $self->_stash_well_genotyping_info( $c, $well );
        } else {
            $c->go( 'well_genotyping_info_search' );
            return;
        }
    }

    return;
}

sub _stash_well_genotyping_info {
    my ( $self, $c, $well ) = @_;

    try {
        #needs to be given a method for finding genes
        my $gene_finder = sub { $c->model('Golgi')->find_genes( @_ ); };
        my $data = $well->genotyping_info( $gene_finder );
        if ( my $ms_qc_data = $well->ms_qc_data($gene_finder) ){
            $data->{ms_qc_data} = $ms_qc_data;
        }
        $data->{child_barcodes} = $well->distributable_child_barcodes;
        my @crispr_data;
        my @crisprs = $well->parent_crispr_wells;
        foreach my $crispr_well ( @crisprs ) {
            my $process_crispr = $crispr_well->process_output_wells->first->process->process_crispr;
            if ( $process_crispr ) {
                my $crispr_data_hash = $process_crispr->crispr->as_hash;
                $crispr_data_hash->{crispr_well} = $crispr_well->as_string;
                my $seq = $crispr_data_hash->{fwd_seq};
                my $grna = substr $seq, 0, 20;
                my $pam = substr $seq, 20 ,3;
                $crispr_data_hash->{'grna'} = $grna;
                $crispr_data_hash->{'pam'} = $pam;
                push @crispr_data, $crispr_data_hash;
            }
        }
        my $crispr_result;
        my $type;
        try{
            #Depending on type of crispr, retrieve crispr hash ref
            if ($data->{qc_data}->{is_crispr_pair}){
                $type = 'CrisprPair';
                $crispr_result = retrieve_crispr_hash($c, $type, @crispr_data);
            }
            elsif ($data->{qc_data}->{is_crispr_group}){
                $type = 'CrisprGroup';
                $crispr_result = retrieve_crispr_hash($c, $type, @crispr_data);
            }
            else {
                $type = 'Crispr';
                $crispr_result = retrieve_crispr_hash($c, $type, @crispr_data);
            }
        } catch {
            $c->stash( error_msg => "Validation tags not found");
            $c->stash( data => $data, crispr_data => \@crispr_data);
            return;
        };
        #Crispr hash ref contains validation confirmation
        my $crispr_primers = $data->{primers}->{crispr_primers};
        my $match;
        foreach my $set (values %$crispr_primers)
        {
            foreach my $primer(@$set)
            {
                #Compare sequences to find the correct tag for the correct sequence
                $match = search_primers($primer->{seq}, $crispr_result->{crispr_primers});
                $primer->{is_validated} = $match->{is_validated};
                $primer->{is_rejected} = $match->{is_rejected};
            }
        }
        $c->stash( data => $data, crispr_data => \@crispr_data);
    }
    catch {
        #get string representation if its a lims2::exception
        $c->stash( error_msg => ref $_ && $_->can('as_string') ? $_->as_string : $_ );
    };

    return;
}

sub _stash_pipeline_ii_genotyping_info {
    my ( $self, $c, $well ) = @_;

    my $data = miseq_genotyping_info($c, $well);
    my $alleles_data;
    foreach my $exp (@{ $data->{experiments} }) {
        my $table = $exp->{alleles_freq};
        my $key = $exp->{qc_origin_plate} . '_' . $exp->{qc_origin_well};
        $alleles_data->{$key} = $table;
        $alleles_data->{$key}->{read_quant} = $exp->{read_counts};
        $alleles_data->{$key}->{frameshift} = $exp->{frameshift};
        $alleles_data->{$key}->{oligos} = $exp->{oligos};
    }

    my $json = JSON->new->allow_nonref;
    my $alleles_json = $json->encode($alleles_data);

    $c->stash( data => $data, tables => $alleles_json );

    return;
}

#Depending on type of crispr, search for the crispr then retrieves it's data hash
sub retrieve_crispr_hash {
    my ($c, $type, @crisprs) = @_;
    my $crispr_data;
    my @crispr_schema;
    my $id = $crisprs[0]->{id};

    #Searches for the crispr id in either the left or the right location
    if ($type eq 'CrisprPair'){
        @crispr_schema = $c->model('Golgi')->schema->resultset($type)->search(
            [ { left_crispr_id => $id },{ right_crispr_id => $id } ],
            {
                distinct => 1,
            }
            )->all;
        $crispr_data = $c->model('Golgi')->retrieve_crispr_pair( { id => $crispr_schema[0]->{_column_data}->{id} });
    }

    #Joins the crispr group and the crispr group crisprs tables to search which crispr group contains the id
    elsif ($type eq 'CrisprGroup') {
        @crispr_schema = $c->model('Golgi')->schema->resultset('CrisprGroup')->search(
        {
            'crispr_group_crisprs.crispr_id' => $id,
        },
        {
            join     => 'crispr_group_crisprs',
            distinct => 1,
        }
        )->all;
        $crispr_data = $c->model('Golgi')->retrieve_crispr_group( { id => $crispr_schema[0]->{_column_data}->{id} });
    }

    #Single crispr search
    else {
        @crispr_schema = $c->model('Golgi')->schema->resultset($type)->search({ id => $id })->all;
        $crispr_data = $c->model('Golgi')->retrieve_crispr( { id => $crispr_schema[0]->{_column_data}->{id} });
    }

    return $crispr_data->as_hash;
}

#Retrieves the correct sequence validation tag
sub search_primers {
    my ($seq, $validation_primers) = @_;
    foreach my $valid_primer(@$validation_primers)
    {
        if ($seq eq $valid_primer->{primer_seq}){
            return $valid_primer;
        }
    }
    return;
}

=head2 public_gene_report

Public gene report, only show targeted clone details:
- Summary of targeted clones:
    - number of visible clones (accepted)
    - number of each clone with type of crispr damage
- List of targeted clones
    - Crispr qc alignment view
    - First allele genbank file
    - Crispr damage type

=cut
## no critic (Subroutines::ProhibitExcessComplexity)
sub public_gene_report :Path( '/public_reports/gene_report' ) :Args(1) {
    my ( $self, $c, $gene_id ) = @_;

    unless($c->user){
        return $c->response->redirect( $c->uri_for('/public_reports/well_genotyping_info_search') );
    }

    # by default type is Targeted, Distributable as an option
    my $type = 'Targeted';
    if ($c->request->param('type') eq 'distributable') {
        $type = 'Distributable';
    }

    $c->log->info( "Generate public $type clone report page for gene: $gene_id" );
    my $model = $c->model('Golgi');
    my $species = $c->session->{selected_species} || 'Human';

    # get the gene name/symbol
    my $gene = $model->find_gene({
                    species => $species,
                    search_term => $gene_id
                });

    my $gene_symbol = $gene->{'gene_symbol'};
    $gene_id = $gene->{'gene_id'};

    # get the summary rows
    my $design_summaries_rs = $model->schema->resultset('Summary')->search(
       {
            design_gene_id     => $gene_id,
            ep_pick_plate_name => { '!=', undef },
            to_report          => 't',
       },
       { distinct => 1 }
    );

    # start colecting the clones data, starting by the targeted clones
    my %clones;
    while ( my $sr = $design_summaries_rs->next ) {
        next if (!defined $sr->ep_pick_well_id || exists $clones{ $sr->ep_pick_well_id } );
        my %ep_pick_data;
        $ep_pick_data{id}         = $sr->ep_pick_well_id;
        $ep_pick_data{name}       = $sr->ep_pick_plate_name . '_' . $sr->ep_pick_well_name;
        $ep_pick_data{plate_name} = $sr->ep_pick_plate_name;
        $ep_pick_data{well_name}  = $sr->ep_pick_well_name;
        $ep_pick_data{accepted}   = $sr->ep_pick_well_accepted ? 'yes' : 'no';
        $ep_pick_data{created_at} = $sr->ep_pick_well_created_ts->ymd;

        # get crispr es qc data if available
        my $well = $model->schema->resultset('Well')->find( { id => $sr->ep_pick_well_id } );
        my $gene_finder = sub { $model->find_genes( @_ ) };
        # grab data for alignment popup
        try { $ep_pick_data{crispr_qc_data} = $well->genotyping_info( $gene_finder, 1 ) };

        my $damage_type = crispr_damage_type_for_ep_pick($model,$sr->ep_pick_well_id);
        $ep_pick_data{crispr_damage} = ( $damage_type ? $damage_type : '-' );

        # save the clone if targeted clones, keep qc data for distributable clones
        $clones{ $sr->ep_pick_well_id } = \%ep_pick_data unless ( $type eq 'Distributable' );

        # no need to the distributable clones unless we want them
        next unless ( $type eq 'Distributable' );

        # get the PIQ clones
        if ( defined $sr->piq_well_id && !exists $clones{ $sr->piq_well_id } ) {
            my %data;
            $data{id}         = $sr->piq_well_id;
            $data{name}       = $sr->piq_plate_name . '_' . $sr->piq_well_name;
            $data{plate_name} = $sr->piq_plate_name;
            $data{well_name}  = $sr->piq_well_name;
            $data{accepted}   = $sr->piq_well_accepted ? 'yes' : 'no';
            $data{created_at} = $sr->piq_well_created_ts->ymd;
            $data{crispr_damage} = $ep_pick_data{crispr_damage};
            $data{crispr_qc_data} = $ep_pick_data{crispr_qc_data};

            $clones{ $sr->piq_well_id } = \%data;
        }

        # get the ancestor PIQ clones
        if ( defined $sr->ancestor_piq_well_id && !exists $clones{ $sr->ancestor_piq_well_id } ) {
            my %data;
            $data{id}         = $sr->ancestor_piq_well_id;
            $data{name}       = $sr->ancestor_piq_plate_name . '_' . $sr->ancestor_piq_well_name;
            $data{plate_name} = $sr->ancestor_piq_plate_name;
            $data{well_name}  = $sr->ancestor_piq_well_name;
            $data{accepted}   = $sr->ancestor_piq_well_accepted ? 'yes' : 'no';
            $data{created_at} = $sr->ancestor_piq_well_created_ts->ymd;
            $data{crispr_damage} = $ep_pick_data{crispr_damage};
            $data{crispr_qc_data} = $ep_pick_data{crispr_qc_data};

            $clones{ $sr->ancestor_piq_well_id } = \%data;
        }
    }

    my @clones = sort _sort_by_damage_type values %clones;

    my %summaries;
    for my $tc ( @clones ) {
        $summaries{genotyped}++ if ($tc->{crispr_damage} && ($tc->{crispr_damage} eq 'frameshift' ||
            $tc->{crispr_damage} eq 'in-frame' || $tc->{crispr_damage} eq 'wild_type' || $tc->{crispr_damage} eq 'mosaic' ||
            $tc->{crispr_damage} eq 'splice_acceptor' || $tc->{crispr_damage} eq 'splice_donor' || $tc->{crispr_damage} eq 'intron') );
        $summaries{ $tc->{crispr_damage} }++ if ($tc->{crispr_damage} && $tc->{crispr_damage} ne 'unclassified');
    }

    $c->stash(
        'gene_id'         => $gene_id,
        'gene_symbol'     => $gene_symbol,
        'summary'         => \%summaries,
        'clones'          => \@clones,
        'type'            => $type,
    );
    return;
}
## use critic

sub _sort_by_damage_type{
    my %crispr_damage_order = (
        'frameshift'   => 1,
        'in-frame'     => 2,
        'wild_type'    => 3,
        'mosaic'       => 4,
        'no-call'      => 5,
        '-'            => 6,
    );
    if ( !$a->{crispr_damage} ) {
        return 1;
    }
    elsif ( !$b->{crispr_damage} ) {
        return -1;
    }

    return $crispr_damage_order{$a->{crispr_damage}} <=> $crispr_damage_order{$b->{crispr_damage}};
}

=head2 well_eng_seq

Generate Genbank file for a well

=cut
sub well_eng_seq :Path( '/public_reports/well_eng_seq' ) :Args(1) {
    my ( $self, $c, $well_id ) = @_;

    # FIXME: temporarily require logged in user for this page
    # to stop robot access
    $c->assert_user_roles('read');

    my $model = $c->model('Golgi');
    my $well =  $model->retrieve_well( { id => $well_id } );

    my $params = $c->request->params;
    my ( $method, undef , $eng_seq_params ) = generate_well_eng_seq_params( $model, $params, $well );
    my $eng_seq = $model->eng_seq_builder->$method( %{ $eng_seq_params } );

    my $gene;
    if ( my $design  = $well->design ) {
        my $gene_id = $design->genes->first->gene_id;
        my $gene_data = try { $model->retrieve_gene( { species => $design->species_id, search_term => $gene_id } ) };
        $gene = $gene_data ? $gene_data->{gene_symbol} : $gene_id;
    }

    my $stage = $method =~ /vector/ ? 'vector' : 'allele';
    my $file_name = $well->as_string . "_$stage";
    $file_name .= "_$gene" if $gene;
    my $file_format = exists $params->{file_format} ? $params->{file_format} : 'Genbank';

    $self->download_genbank_file( $c, $eng_seq, $file_name, $file_format );

    return;
}

sub download_genbank_file {
    my ( $self, $c, $eng_seq, $file_name, $file_format ) = @_;

    $file_format ||= 'Genbank';
    my $suffix = $file_format eq 'Genbank' ? 'gbk' : 'fa';
    my $formatted_seq;
    Bio::SeqIO->new(
        -fh     => IO::String->new($formatted_seq),
        -format => $file_format,
    )->write_seq($eng_seq);
    $file_name = $file_name . ".$suffix";

    $c->response->content_type( 'chemical/seq-na-genbank' );
    $c->response->header( 'Content-Disposition' => "attachment; filename=$file_name" );
    $c->response->body( $formatted_seq );

    return;
}

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;


