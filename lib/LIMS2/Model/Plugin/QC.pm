package LIMS2::Model::Plugin::QC;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Hash::MoreUtils qw( slice slice_def );
use Scalar::Util qw( blessed );
use JSON qw( decode_json );
use Data::Compare qw( Compare );
use namespace::autoclean;

requires qw( schema check_params throw );

sub _retrieve_latest_qc_template_by_name {
    my ( $self, $template_name ) = @_;

    return $self->schema->resultset('QcTemplate')->find(
        {
            name       => $template_name,
            created_at => \[ 'select max(created_at) from qc_templates where name = ?', $template_name ]
        }
    );
}

sub _canonicalise_eng_seq_params {
    my ( $self, $eng_seq_params ) = @_;

    my $params = decode_json($eng_seq_params);
    my $json   = JSON->new->utf8->canonical->encode($params);

    return $json;
}

sub pspec__create_or_retrieve_qc_eng_seq {
    return {
        eng_seq_method => { validate => 'non_empty_string' },
        eng_seq_params => { validate => 'json' }
    }
}

sub _create_or_retrieve_eng_seq {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec__create_or_retrieve_qc_eng_seq );    

    return $self->schema->resultset('QcEngSeq')->find_or_create(
        {
            method => $validated_params->{eng_seq_method},
            params => $self->_canonicalise_eng_seq_params( $validated_params->{eng_seq_params} )
        },
        {
            key => 'qc_eng_seqs_method_params_key'
        }
    );
}

sub _qc_template_has_identical_layout {
    my ( $self, $template, $wanted_layout ) = @_;

    my %template_layout = map { $_->name => $_->qc_eng_seq_id } $template->qc_template_wells;
    
    Compare( \%template_layout, $wanted_layout );
}

sub _find_qc_template_with_layout {
    my ( $self, $template_name, $template_layout ) = @_;

    my $template_rs = $self->schema->resultset('QcTemplate')->search(
        {
            name => $template_name
        },
        {
            prefetch => { qc_template_wells => 'qc_eng_seq' }
        }
    );

    while ( my $template = $template_rs->next ) {
        if ( $self->_qc_template_has_identical_layout( $template, $template_layout ) ) {
            $self->log->debug( "Found existing template with identical layout" );
            return $template;
        }
    }

    return;
}

sub pspec_find_or_create_qc_template {
    return {
        name  => { validate => 'plate_name' },
        wells => { validate => 'hashref' }
    };
}

sub find_or_create_qc_template {
    my ( $self, $params ) = @_;

    my $validated_params = $self->check_params( $params, $self->pspec_find_or_create_qc_template );

    # Build a new data structure mapping each well to a qc_eng_seq.id
    my %template_layout;
    while ( my ( $well_name, $eng_seq_params ) = each %{ $validated_params->{wells} } ) {
        next unless defined $eng_seq_params and keys %{$eng_seq_params};
        $template_layout{$well_name} = $self->_create_or_retrieve_eng_seq( $eng_seq_params )->id;
    }

    # If a template already exists with this name and layout, return it
    my $existing_template = $self->_find_qc_template_with_layout( $validated_params->{name}, \%template_layout );    
    if ( $existing_template ) {
        $self->log->debug( 'Returning matching template with id ' . $existing_template->id );
        return $existing_template;
    }

    # Otherwise, create a new template
    my $qc_template = $self->schema->resultset('QcTemplate')->create( { name => $validated_params->{name} } );
    $self->log->debug( 'created qc template plate ' . $qc_template->name . ' with id ' . $qc_template->id );
    while ( my ( $well_name, $eng_seq_id ) = each %template_layout ) {
        $qc_template->create_related(
            wells => {
                name          => $well_name,
                qc_eng_seq_id => $eng_seq_id
            }
        );
    }
    
    return $qc_template;
}

# sub pspec_retrieve_qc_template {
#     return {
#         id           => { validate               => 'integer',                   optional => 1 },
#         name         => { validate               => 'existing_qc_template_name', optional => 1 },
#         REQUIRE_SOME => { qc_template_id_or_name => [ 1,                         qw/id name/ ], }
#     };
# }

# sub retrieve_qc_template {
#     my ( $self, $params ) = @_;

#     my $validated_params = $self->check_params( $params, $self->pspec_retrieve_qc_template );
#     my $qc_template;

#     if ( $validated_params->{id} ) {
#         $qc_template = $self->retrieve( QcTemplate => $validated_params );
#     }
#     else {
#         $qc_template = $self->schema->resultset('QcTemplate')
#             ->search_rs( { name => $validated_params->{name} }, { order_by => { -desc => 'created_at' } } )->first;
#     }

#     return $qc_template;
# }

# sub pspec_retrieve_newest_qc_template_created_before {
#     return {
#         name           => { validate => 'non_empty_string' },
#         created_before => { validate => 'date_time', post_filter => 'parse_date_time' },
#     };
# }

# sub retrieve_newest_qc_template_created_before {
#     my ( $self, $params ) = @_;

#     my $validated_params = $self->check_params( $params, $self->pspec_retrieve_qc_template_created_before );

#     my $qc_template = $self->schema->resultset('QcTemplate')->search(
#         {   name       => $validated_params->{name},
#             created_at => { '<' => $validated_params->{created_before} },
#         },
#         {   order_by => { desc => 'created_at' },
#             columns  => [qw( name created_at )],
#             rows     => 1
#         }
#     )->single;

#     return $qc_template;
# }


# sub pspec_create_qc_run {
#     return {
#         id                         => { validate => 'uuid' },
#         date                       => { validate => 'date_time', post_filter => 'parse_date_time' },
#         profile                    => { validate => 'non_empty_string' },
#         software_version           => { validate => 'software_version' },
#         qc_sequencing_projects     => { validate => 'non_empty_string' },
#         qc_template_name           => { validate => 'plate_name', rename => 'name' },
#         qc_template_created_before => { validate => 'date_time', optional => 1, rename => 'created_before' },
#         qc_test_results            => { optional => 1 },
#     };
# }

# sub create_qc_run {
#     my ( $self, $params ) = @_;
#     my $qc_run;

#     my $validated_params = $self->check_params( $params, $self->pspec_create_qc_run );

#     # TODO: is the rename qc_template_name to name in validate params a good idea, better way?
#     my $qc_template;
#     if ( $validated_params->{created_before} ) {
#         $qc_template = $self->retrieve_newest_qc_template_created_after(
#             { slice( $validated_params, qw( created_before name ) ) } );
#     }
#     else {
#         $qc_template = $self->retrieve_qc_template( { slice( $validated_params, qw( name ) ) } );
#     }

#     $qc_run = $qc_template->create_related(
#         qcs_runs => { slice_def( $validated_params, qw( id date profile software_version) ) } );

#     my @qc_sequencing_projects = grep { !/^\s*$/ } split ',', $validated_params->{qc_sequencing_projects};
#     map { $self->create_qc_run_sequencing_project( { qc_sequencing_project => $_ }, $qc_run ) } @qc_sequencing_projects;

#     $self->log->debug( 'created qc run : ' . $qc_run->id );

#     for my $test_result_params ( @{ $validated_params->{qc_test_results} } ) {
#         $test_result_params->{qc_run_id} = $qc_run->id;
#         $self->create_qc_test_result($test_result_params);
#     }

#     return $qc_run;
# }

# sub pspec_create_qc_run_sequencing_project {
#     return { qc_sequencing_project => { validate => 'plate_name' } };
# }

# sub create_qc_run_sequencing_project {
#     my ( $self, $params, $qc_run ) = @_;

#     my $validated_params = $self->check_params( $params, $self->pspec_create_qc_run_sequencing_project );

#     my $qc_run_sequencing_project = $qc_run->create_related(
#         qc_run_sequencing_projects => { qc_sequencing_project => $validated_params->{qc_sequencing_project}, } );

#     return $qc_run_sequencing_project;
# }

# sub pspec_retrieve_qc_run {
#     return { id => { validate => 'uuid' } };
# }

# sub retrieve_qc_run {
#     my ( $self, $params ) = @_;

#     my $validated_params = $self->check_params( $params, $self->pspec_retrieve_qc_run );

#     my $qc_run = $self->retrieve( QcRun => $validated_params );

#     return $qc_run;
# }

# sub pspec_create_qc_seq_read {
#     return {
#         id                    => { validate => 'qc_seq_read_id' },
#         qc_sequencing_project => { validate => 'plate_name' },
#         description           => { validate => 'non_empty_string' },
#         seq                   => { validate => 'dna_seq' },
#         length                => { validate => 'integer' },
#     };
# }

# sub create_qc_seq_read {
#     my ( $self, $params ) = @_;

#     my $validated_params = $self->check_params( $params, $self->pspec_create_qc_seq_read );

#     $self->find_or_create_qc_sequencing_project( { name => $validated_params->{qc_sequencing_project} } );

#     my $qc_seq_read = $self->schema->resultset('QcSeqRead')->create(
#         { slice_def( $validated_params, qw( id description seq length qc_sequencing_project ) ) }
#     );

#     $self->log->debug( 'created qc_seq_read with id: ' . $qc_seq_read->id );

#     return $qc_seq_read;
# }

# sub pspec_retrieve_qc_seq_read {
#     return { id => { validate => 'qc_seq_read_id' }, };
# }

# sub retrieve_qc_seq_read {
#     my ( $self, $params ) = @_;

#     my $validated_params = $self->check_params( $params, $self->pspec_retrieve_qc_seq_read );

#     return $self->retrieve( QcSeqRead => $validated_params );
# }

# sub pspec_find_or_create_qc_sequencing_project {
#     return { name => { validate => 'plate_name' }, };
# }

# sub find_or_create_qc_sequencing_project {
#     my ( $self, $params ) = @_;

#     my $validated_params = $self->check_params( $params, $self->pspec_find_or_create_qc_sequencing_project );

#     return $self->schema->resultset('QcSequencingProject')->find_or_create($validated_params);
# }

# sub pspec_create_qc_test_result {
#     return {
#         qc_run_id                 => { validate => 'uuid' },
#         qc_eng_seq_id             => { validate => 'integer' },
#         well_name                 => { validate => 'well_name' },          #lower case, how to fix this?
#         plate_name                => { validate => 'plate_name' },
#         score                     => { validate => 'integer' },
#         pass                      => { validate => 'boolean' },
#         qc_test_result_alignments => { validate => 'non_empty_string' },
#     };
# }

# sub create_qc_test_result {
#     my ( $self, $params ) = @_;

#     my $validated_params = $self->check_params( $params, $self->pspec_create_qc_test_result );

#     my $qc_test_result = $self->schema->resultset('QcTestResult')->create(
#         { slice_def( $validated_params, qw( well_name plate_name score pass qc_eng_seq_id qc_run_id ) ) }
#     );

#     for my $test_result_alignment_params ( @{ $validated_params->{qc_test_result_alignments} } ) {
#         $self->create_qc_test_result_alignment( $test_result_alignment_params, $qc_test_result );
#     }

#     $self->log->debug( 'created qc test result: ' . $qc_test_result->id );

#     return $qc_test_result;
# }

# sub pspec_create_qc_test_result_alignment {
#     return {
#         qc_seq_read_id    => { validate => 'qc_seq_read_id' },
#         primer_name       => { validate => 'non_empty_string' },
#         query_start       => { validate => 'integer' },
#         query_end         => { validate => 'integer' },
#         query_strand      => { validate => 'strand' },
#         target_start      => { validate => 'integer' },
#         target_end        => { validate => 'integer' },
#         target_strand     => { validate => 'strand' },
#         score             => { validate => 'integer' },
#         pass              => { validate => 'boolean' },
#         features          => { validate => 'non_empty_string' },
#         cigar             => { validate => 'cigar_string' },
#         op_str            => { validate => 'op_str' },
#         alignment_regions => { validate => 'non_empty_string' },
#     };
# }

# sub create_qc_test_result_alignment {
#     my ( $self, $params, $qc_test_result ) = @_;

#     my $validated_params = $self->check_params( $params, $self->pspec_create_qc_test_result_alignment );

#     my $qc_test_result_alignment = $self->schema->resultset('QcTestResultAlignment')->create(
#         {   slice_def(
#                 $validated_params, qw(
#                     qc_seq_read_id primer_name
#                     query_start    query_end   query_strand
#                     target_start   target_end  target_strand
#                     score          pass        features      cigar op_str )
#             )
#         }
#     );

#     $qc_test_result_alignment->create_related(
#         qc_test_result_alignment_maps => { qc_test_result_id => $qc_test_result->id } );

#     for my $alignment_region_params ( @{ $validated_params->{alignment_regions} } ) {
#         $self->create_qc_test_result_alignment_region( $alignment_region_params, $qc_test_result_alignment );
#     }

#     return $qc_test_result_alignment;
# }

# sub pspec_create_qc_test_result_align_region {
#     return {
#         name        => { validate => 'non_empty_string' },
#         length      => { validate => 'integer' },
#         match_count => { validate => 'integer' },
#         query_str   => { validate => 'qc_alignment_seq' },
#         target_str  => { validate => 'qc_alignment_seq' },
#         match_str   => { validate => 'qc_match_str' },
#         pass        => { validate => 'boolean' },
#     };
# }

# sub create_qc_test_result_alignment_region {
#     my ( $self, $params, $qc_test_result_alignment ) = @_;

#     my $validated_params = $self->check_params( $params, $self->pspec_create_qc_test_result_align_region );

#     my $qc_test_result_align_region = $qc_test_result_alignment->create_related( qc_test_result_align_regions =>
#             { slice_def( $validated_params, qw( name length match_count query_str target_str match_str pass ) ) } );

#     return $qc_test_result_align_region;
# }

1;

__END__
