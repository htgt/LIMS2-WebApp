#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $DEBUG );
}

use Test::Most;
use LIMS2::Model::Test;
use Try::Tiny;
use FindBin;
use YAML::Any;
use Path::Class;
use DateTime;

my $data_dir = dir( $FindBin::Bin )->subdir( 'data' );

note( "Testing QC template storage and retrieval" );

my $template_data = YAML::Any::LoadFile( $data_dir->file( 'qc_template.yaml' ) );
#my $all_template_data = YAML::Any::LoadFile( $data_dir->file( 'qc_template_TPG00267_Y.yaml' ) );
#my $template_data = $all_template_data->[0];
my $template_name = $template_data->{name};

my %created_template_ids;

{        
    ok my $res = model->retrieve_qc_templates( { name => $template_name } ),
        'retrieve_qc_templates should succeed';
    isa_ok $res, ref [],
        'retrieve_qc_templates return';
    is @{$res}, 0,
        'retrieve_qc_templates should return an empty array';
}

my $created_template;

lives_ok {        
    $created_template = model->find_or_create_qc_template( $template_data );
    $created_template_ids{ $created_template->id }++;
} 'find_or_create_qc_template should live';

isa_ok $created_template, 'LIMS2::Model::Schema::Result::QcTemplate',
    'find_or_create_qc_template return';

{
    ok my $res = model->retrieve_qc_templates( { id => $created_template->id } ),
        'retrieve_qc_templates by id should succeed';
    is @{$res}, 1,
        'retrieve_qc_templates by id should return a 1-element array';
    is $res->[0]->id, $created_template->id,
        'the returned template has the expected id';        
}

lives_ok {
    ok my $template = model->find_or_create_qc_template( $template_data ),
        'find_or_create_qc_template should succeed';
    $created_template_ids{ $template->id }++;
    isa_ok $template, 'LIMS2::Model::Schema::Result::QcTemplate',
        'the object it returns';
    is $template->id, $created_template->id,
        'attempting to create a template with the same parameters should return the original template';
} 'find_or_create_template a second time should live';

delete $template_data->{created_at};
$template_data->{wells}{A02}{eng_seq_params}{five_arm_end}++;

my $modified_created_template;
    
lives_ok {
    ok $modified_created_template = model->find_or_create_qc_template( $template_data ),
        'find_or_create_qc_tempalte with modified parameters should succeed';
    $created_template_ids{ $modified_created_template->id }++;
    isa_ok $modified_created_template, 'LIMS2::Model::Schema::Result::QcTemplate',
        'the object it returns';
    isnt $modified_created_template->id, $created_template->id,
        'the modified template has a different id from the original';
};

{
    ok my $res = model->retrieve_qc_templates( { name => $template_name, latest => 0 } ),
        'retrieve_qc_templates, latest=0, should succeed';
    is @{$res}, 2,
        'it should return 2 templates';
    is $res->[0]->name, $res->[1]->name,
        'the returned templates have the same name';
}

{
    ok my $res = model->retrieve_qc_templates( { name => $template_name } ),
        'retrieve_qc_templates, implicit latest=1, should succeed';
    is @{$res}, 1,
        'it should return 1 template';
    is $res->[0]->id, $modified_created_template->id,
        'the returned template is the most recent';
}

{
    ok my $templates = model->retrieve_qc_templates( { id => $created_template->id } ),
        'retrieve_qc_templates by id should succeed';
    is @{$templates}, 1,
        'retrieve_qc_templates by id should return 1 template';
    is $templates->[0]->id, $created_template->id,
        'the returned template has the expected id';    
    ok my $res = model->retrieve_qc_templates( { name => $template_name, created_before => $templates->[0]->created_at->iso8601 } ),
        'retrieve_qc_templates, created_before, should succeed';
    is @{$res}, 1,
        'it should return 1 template';
    is $res->[0]->id, $created_template->id,
        'the returned template is the original';
}

lives_ok {
    for my $id ( keys %created_template_ids ) {
        ok model->delete_qc_template( { id => $id } ), 'delete template ' . $id . ' should succeed';
    }
};

note( "Tesing QC seq read storage and retrieval" );

my @seq_reads_data = YAML::Any::LoadFile( $data_dir->file( 'qc_seq_reads.yaml' ) );

for my $datum ( @seq_reads_data ) {
    ok my $qc_seq_read = model->find_or_create_qc_seq_read( $datum ), "find_or_create_seq_read $datum->{id}";
    is $qc_seq_read->id, $datum->{id}, '...the read has the expected id';
    ok my $ret = model->retrieve_qc_seq_read( { id => $datum->{id} } ), 'retrieve_qc_seq_read should succeed';
    is $ret->id, $datum->{id}, '...the retrieved read has the expected id';
}




done_testing();
