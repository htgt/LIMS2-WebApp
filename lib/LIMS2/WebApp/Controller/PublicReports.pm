package LIMS2::WebApp::Controller::PublicReports;
use Moose;
use LIMS2::Report;
use Try::Tiny;
use Data::Printer;
use LIMS2::Model::Util::EngSeqParams qw( generate_well_eng_seq_params );
use List::MoreUtils qw( uniq );
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::PublicReports - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller for reports that a un-authenticated user can access.

=cut

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
        report_id   => $report_id
    );

    return;
}

=head2 download_report

Downloads a csv report of a given report_id

=cut
sub download_report :Path( '/public_reports/download' ) :Args(1) {
    my ( $self, $c, $report_id ) = @_;

    my ( $report_name, $report_fh ) = LIMS2::Report::read_report_from_disk( $report_id );

    $c->response->status( 200 );
    $c->response->content_type( 'text/csv' );
    $c->response->header( 'Content-Disposition' => "attachment; filename=$report_name.csv" );
    $c->response->body( $report_fh );
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




=head2 index

=cut
sub sponsor_report :Path( '/public_reports/sponsor_report' ) {
    my ( $self, $c, $targeting_type ) = @_;

    my $species;
    my $cache_param;
    my $sub_cache_param;
    my $top_cache_param;

# If logged in always use live top level report and cached sub_reports
# The cache_param refers to the sub_reports


    if ( $c->request->params->{'generate_cache'} ){
        $sub_cache_param = 'without_cache';
        $top_cache_param = 'without_cache';
    }
    elsif ($c->user_exists) {
        $c->request->params->{'species'} = $c->session->{'selected_species'};
        if ( !$c->request->params->{'cache_param'} ) {
            $sub_cache_param = 'with_cache';
            $top_cache_param = 'without_cache';
        }
        else {
            $sub_cache_param = $c->request->params->{'cache_param'};
            $top_cache_param = 'without_cache';
        }
    }
    else {
        # not logged in - always use cached reports for top level and sub-reports
        $sub_cache_param = 'with_cache';
        $top_cache_param = 'with_cache';
    }

    if (!$c->request->params->{'species'}) {
        $c->request->params->{'species'} = 'Human';
    }

    $species = $c->request->params->{'species'};
    $c->session->{'selected_species'} = $species;

    if ( defined $targeting_type ) {
        # show report for the requested targeting type
        $self->_generate_front_page_report ( $c, $targeting_type, $species, $sub_cache_param );
    }
    else {
        # by default show the single_targeted report
        if ( $top_cache_param eq  'with_cache' ) {
            $self->_view_cached_lines( $c, lc( $species ) );
        }
        else {
            $self->_generate_front_page_report ( $c, 'single_targeted', $species, $sub_cache_param );
        }

    }

    if ( $top_cache_param eq 'without_cache' ) {
        $c->stash(
            template    => 'publicreports/sponsor_report.tt',
        );
    }

    return;
}

sub _generate_front_page_report {
    my ( $self, $c, $targeting_type, $species, $cache_param ) = @_;

    # Call ReportForSponsors plugin to generate report
    my $sponsor_report = LIMS2::Model::Util::ReportForSponsors->new({
            'species' => $species,
            'model' => $c->model( 'Golgi' ),
            'targeting_type' => $targeting_type,
        });

    my $report_params = $sponsor_report->generate_top_level_report_for_sponsors( );

    # Fetch details from returned report parameters
    my $report_id   = $report_params->{ report_id };
    my $title       = $report_params->{ title };
    my $columns     = $report_params->{ columns };
    my $rows        = $report_params->{ rows };
    my $data        = $report_params->{ data };

    # Store report values in stash for display onscreen
    $c->stash(
        'report_id'      => $report_id,
        'title'          => $title,
        'species'        => $species,
        'targeting_type' => $targeting_type,
        'cache_param'    => $cache_param,
        'columns'        => $columns,
        'rows'           => $rows,
        'data'           => $data,
    );

    return;
}


sub view_cached_csv : Path( '/public_reports/cached_sponsor_csv' ) : Args(1) {
    my ( $self, $c, $sponsor_id ) = @_;

    $sponsor_id =~ s/\ /_/g;
    return $self->_view_cached_csv($c, $sponsor_id);
}

sub _view_cached_csv {
    my $self = shift;
    my $c = shift;
    my $csv_name = shift;

    my $server_path = $c->uri_for('/');
    my $cache_server;

    for ($server_path) {
        if    (/^http:\/\/www.sanger.ac.uk\/htgt\/lims2\/$/) { $cache_server = 'production/'; }
        elsif (/http:\/\/www.sanger.ac.uk\/htgt\/lims2\/+staging\//) { $cache_server = 'staging/'; }
        elsif (/http:\/\/t87-dev.internal.sanger.ac.uk:(\d+)\//) { $cache_server = "$1/"; }
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

    return $c->response->body( join( '', @lines_out ));
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

    my $cache_param = $c->request->params->{'cache_param'};

    # Call ReportForSponsors plugin to generate report
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
    if ($c->request->params->{csv}) {
        $c->response->status( 200 );
        $c->response->content_type( 'text/csv' );
        $c->response->header( 'Content-Disposition' => 'attachment; filename=report.csv');

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

        $c->response->body( $body );
    }
    else {

        if ($disp_stage eq 'Genes') {

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
            'template'             => $template,
            'report_id'            => $report_id,
            'disp_target_type'     => $disp_target_type,
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
    }

    return;
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
                    || $key eq 'chromosome' );
            }
        }
    }
    return $data;
}

sub view_cached : Path( '/public_reports/cached_sponsor_report' ) : Args(1) {
    my ( $self, $c, $report_name ) = @_;

    $c->log->info( "Generate public detail report for : $report_name" );

    return $self->_view_cached_lines($c, $report_name );
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
        if    (/^http:\/\/www.sanger.ac.uk\/htgt\/lims2\/$/) { $cache_server = 'production/'; }
        elsif (/http:\/\/www.sanger.ac.uk\/htgt\/lims2\/+staging\//) { $cache_server = 'staging/'; }
        elsif (/http:\/\/t87-dev.internal.sanger.ac.uk:(\d+)\//) { $cache_server = "$1/"; }
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
    return;
}

=head2 well_genotyping_info

Page to display chosen well, takes a well id (later a barcode) or a plate/well combo

=cut
sub well_genotyping_info :Path( '/public_reports/well_genotyping_info' ) :Args() {
    my ( $self, $c, @args ) = @_;

    if ( @args == 1 ) {
        my $barcode = shift @args;
        try {
            $self->_stash_well_genotyping_info( $c, { barcode => $barcode } );
        } catch {
            $c->stash( error_msg => "$_" );
            $c->go( 'well_genotyping_info_search' );
            return;
        };
    }
    elsif ( @args == 2 ) {
        my ( $plate_name, $well_name ) = @args;

        try {
            $self->_stash_well_genotyping_info(
                $c, { plate_name => $plate_name, well_name => $well_name }
            );
        } catch {
            $c->stash( error_msg => "$_" );
            $c->go( 'well_genotyping_info_search' );
            return;
        };
    }
    else {
        $c->stash( error_msg => "Invalid number of arguments" );
    }

    return;
}

sub _stash_well_genotyping_info {
    my ( $self, $c, $search ) = @_;

    #well_id will become barcode
    my $well;
    try { $well = $c->model('Golgi')->retrieve_well( $search ) };

    unless($well){
        try{ $well = $c->model('Golgi')->retrieve_well_from_old_plate_version( $search ) };
        if($well){
            $c->stash->{info_msg} = ("Well ".$well->name." was not found on the current version of plate ".
                $well->plate->name.". Reporting info for this well on version ".$well->plate->version
                ." of the plate.");
        }
    }

    unless ( $well ) {
        $c->stash( error_msg => "Well doesn't exist" );
        return;
    }

    try {
        #needs to be given a method for finding genes
        my $gene_finder = sub { $c->model('Golgi')->find_genes( @_ ); };
        my $data = $well->genotyping_info( $gene_finder );
        if(my $ms_qc_data = $well->ms_qc_data($gene_finder) ){
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
                push @crispr_data, $crispr_data_hash;
            }
        }

        $c->stash( data => $data, crispr_data => \@crispr_data );
    }
    catch {
        #get string representation if its a lims2::exception
        $c->stash( error_msg => ref $_ && $_->can('as_string') ? $_->as_string : $_ );
    };

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

        # grab data for crispr damage type
        # only on validated runs...
        my @crispr_es_qc_wells = $model->schema->resultset('CrisprEsQcWell')->search(
            {
                well_id  => $sr->ep_pick_well_id,
                'crispr_es_qc_run.validated' => 1,
            },
            {
                join => 'crispr_es_qc_run'

            }
        );

        my @crispr_damage_types = uniq grep { $_ } map{ $_->crispr_damage_type_id } @crispr_es_qc_wells;

        if ( scalar( @crispr_damage_types ) == 1 ) {
            $ep_pick_data{crispr_damage} = $crispr_damage_types[0];
        }
        elsif ( scalar( @crispr_damage_types ) > 1 ) {
            # remove any non accepted results
            @crispr_damage_types = uniq grep {$_}
                map { $_->crispr_damage_type_id } grep { $_->accepted } @crispr_es_qc_wells;

            if ( scalar( @crispr_damage_types ) == 1 ) {
                $ep_pick_data{crispr_damage} = $crispr_damage_types[0];
            }
            else {
                if (scalar( @crispr_damage_types ) > 1 ) {
                    $c->log->warn( $ep_pick_data{name}
                            . ' ep_pick well has multiple crispr damage types associated with it: '
                            . join( ', ', @crispr_damage_types ) );
                    $ep_pick_data{crispr_damage} = $crispr_damage_types[0];
                } else {
                    $c->log->warn( $ep_pick_data{name}
                        . ' ep_pick well has no crispr damage type associated with it' );
                    $ep_pick_data{crispr_damage} = '-';
                }

            }
        }
        else {
            $c->log->warn( $ep_pick_data{name}
                . ' ep_pick well has no crispr damage type associated with it' );
            $ep_pick_data{crispr_damage} = '-';
        }

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
            $tc->{crispr_damage} eq 'in-frame' || $tc->{crispr_damage} eq 'wild_type' || $tc->{crispr_damage} eq 'mosaic') );
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
