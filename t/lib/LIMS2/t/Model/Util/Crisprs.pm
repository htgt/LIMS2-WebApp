package LIMS2::t::Model::Util::Crisprs;
use strict;
use warnings FATAL => 'all';

use base qw( Test::Class );
use Test::Most;
use LIMS2::Model::Util::Crisprs qw( crispr_wells_for_crispr );
use LIMS2::Test model => { classname => __PACKAGE__ };

## no critic

=head1 NAME

LIMS2/t/Model/Util/Crisprs.pm - test class for LIMS2::Model::Util::Crisprs

=cut

sub crispr_hits_design : Test(5) {

    ok my $design = model->c_retrieve_design( { id => 1002582 } ), 'can grab design';
    ok my $matching_crispr = model->retrieve_crispr( { id => 69844 } ), 'can grab a crispr';
    ok my $non_matching_crispr = model->retrieve_crispr( { id => 69907 } ), 'can grab a crispr';
    my $default_assembly = 'GRCm38';

    ok LIMS2::Model::Util::Crisprs::crispr_hits_design( $design, $matching_crispr,
        $default_assembly ), 'crispr hits design';
    ok !LIMS2::Model::Util::Crisprs::crispr_hits_design( $design, $non_matching_crispr,
        $default_assembly ), 'crispr does not hit design';

}

sub crispr_pair_hits_design : Test(5) {

    ok my $design = model->c_retrieve_design( { id => 1002582 } ), 'can grab design';
    ok my $matching_crispr_pair = model->schema->resultset('CrisprPair')->find( { id => 4423 } )
        , 'can grab a crispr_pair';
    ok my $non_matching_crispr_pair = model->schema->resultset('CrisprPair')->find( { id => 4475 } )
        , 'can grab a crispr_pair';
    my $default_assembly = 'GRCm38';

    ok LIMS2::Model::Util::Crisprs::crispr_pair_hits_design( $design, $matching_crispr_pair,
        $default_assembly ), 'crispr_pair hits design';

    ok !LIMS2::Model::Util::Crisprs::crispr_pair_hits_design( $design, $non_matching_crispr_pair,
            $default_assembly ), 'crispr_pair does not hit design';

}

sub create_crispr_design_links : Test(6) {

    my $default_assembly = 'GRCm38';

    throws_ok {
        LIMS2::Model::Util::Crisprs::create_crispr_design_links(
            model,
            [ { crispr_id => 123, design_id => 1002582 } ],
            $default_assembly
        );
    } qr/Can not find crispr: \d+/, 'throws error if non existant crispr sent in';

    ok my ( $create_log, $fail_log ) = LIMS2::Model::Util::Crisprs::create_crispr_design_links(
        model,
        [ { crispr_id => 69907, design_id => 1002582 } ],
        $default_assembly
    );
    like(
        $fail_log->[0],
        qr/Additional validation failed between design & crispr/,
        'link fails if crispr does not hit design'
    );
    is model->schema->resultset('Experiment')
        ->search( { design_id => 1002582, crispr_id => 69907, deleted => 0 } )->count, 0,
        'no link created between crispr and design';

    ok LIMS2::Model::Util::Crisprs::create_crispr_design_links(
        model,
        [ { crispr_id => 69844, design_id => 1002582 } ],
        $default_assembly
    ), 'can create new crispr design link';

    ok my $crispr_design = model->schema->resultset( 'Experiment' )->find(
        {
            design_id => 1002582,
            crispr_id => 69844,
            deleted => 0
        }
    ), 'can grab newly created crispr_design link';

}

sub create_crispr_pair_design_links : Test(6) {

    my $default_assembly = 'GRCm38';

    throws_ok {
        LIMS2::Model::Util::Crisprs::create_crispr_pair_design_links(
            model,
            [ { crispr_pair_id => 123, design_id => 1002582 } ],
            $default_assembly
        );
    } qr/Can not find crispr pair: \d+/, 'throws error if non existant crispr_pair sent in';

    ok my ( $create_log, $fail_log ) = LIMS2::Model::Util::Crisprs::create_crispr_pair_design_links(
        model,
        [ { crispr_pair_id => 4475, design_id => 1002582 } ],
        $default_assembly
    );
    like(
        $fail_log->[0],
        qr/Additional validation failed between design: \d+ & crispr pair: \d+/,
        'link fails if crispr_pair does not hit design'
    );
    is model->schema->resultset('Experiment')
        ->search( { design_id => 1002582, crispr_pair_id => 4475, deleted => 0 } )->count, 0,
        'no link created between crispr pair and design';

    ok LIMS2::Model::Util::Crisprs::create_crispr_pair_design_links(
        model,
        [ { crispr_pair_id => 4423, design_id => 1002582 } ],
        $default_assembly
    ), 'can create new crispr_pair design link';

    ok my $crispr_design = model->schema->resultset( 'Experiment' )->find(
        {
            design_id => 1002582,
            crispr_pair_id => 4423,
            deleted => 0,
        }
    ), 'can grab newly created crispr_design link';

}

sub delete_crispr_design_links : Test(7) {

    my $default_assembly = 'GRCm38';

    ok LIMS2::Model::Util::Crisprs::create_crispr_pair_design_links(
        model,
        [ { crispr_pair_id => 4423, design_id => 1002582 } ],
        $default_assembly
    ), 'can create new crispr_pair design link';
    ok LIMS2::Model::Util::Crisprs::create_crispr_design_links(
        model,
        [ { crispr_id => 69844, design_id => 1002582 } ],
        $default_assembly
    ), 'can create new crispr design link';

    is model->schema->resultset('Experiment')->search( { design_id => 1002582, deleted => 0 } )->count, 2,
        'we have 2 links with design 1002582';

    ok my ( $delete_log, $fail_log ) = LIMS2::Model::Util::Crisprs::delete_crispr_design_links(
        model,
        [   { crispr_pair_id => 4423,  design_id => 1002582 },
            { crispr_id      => 69844, design_id => 1002582 }
        ],
    ), 'can call delete_crispr_design_links';

    like( $delete_log->[0], qr/Deleted link between design & crispr/, 'log message says first link deleted' );
    like( $delete_log->[1], qr/Deleted link between design & crispr/, 'log message says second link deleted' );

    is model->schema->resultset('Experiment')->search( { design_id => 1002582, deleted => 0 } )->count, 0,
        'we no longer have any links with design 1002582';

}

sub compare_design_crispr_links : Test(2) {

    my %orig = (
        123 => { 1 => undef, 2 => undef },
        124 => { 3 => undef, 4 => undef },
        125 => { 5 => undef, 8 => undef },
    );

    my %new = (
        123 => { 1 => undef },
        124 => { 3 => undef, 9 => undef },
        126 => { 6 => undef, 7 => undef },
    );

    ok my $change_links
        = LIMS2::Model::Util::Crisprs::compare_design_crispr_links( \%orig, \%new, 'crispr_pair' ),
        'can call compare_design_crispr_links';

    is_deeply $change_links, [
        {
          crispr_pair => '2',
          design_id => '123'
        },
        {
          crispr_pair => '4',
          design_id => '124'
        },
        {
          crispr_pair => '5',
          design_id => '125'
        },
        {
          crispr_pair => '8',
          design_id => '125'
        }
    ], 'got expected change links data';

}

sub crispr_pick : Test(8) {

    my $species_id = 'Mouse';

    my $crispr_design_rs = model->schema->resultset('Experiment')->search({ deleted => 0 });
    ok $crispr_design_rs->search_rs( {} )->delete, 'delete all existing links';
    ok $crispr_design_rs->create( { design_id => 1002582, crispr_id => 69854 } ), 'create crispr design link';

    throws_ok{
        LIMS2::Model::Util::Crisprs::crispr_pick( model, {  }, $species_id ),
    } qr/No crispr_type set/, 'throws error when no crispr type set';

    throws_ok{
        LIMS2::Model::Util::Crisprs::crispr_pick( model, { crispr_types => 'foo'  }, $species_id ),
    } qr/Unknown crispr type foo/, 'throws error when unknown crispr type set';

    # should delete the one existing link and create one new one
    my $crispr_request_params = {
        crispr_pick        => [ '69844:1002582' ],
        crispr_types       => 'single',
        design_crispr_link => [ '69854:1002582' ]
    };

    ok LIMS2::Model::Util::Crisprs::crispr_pick( model, $crispr_request_params, $species_id ),
        'can call crispr_pick';

    ok my $crispr_design = $crispr_design_rs->find(
        {
            design_id => 1002582,
            crispr_id => 69844
        }
    ), 'can grab newly created crispr_design link';

    ok !$crispr_design_rs->find(
        {
            design_id => 1002582,
            crispr_id => 69854
        }
    ), 'design crispr link has been deleted';

    ok $crispr_design_rs->search_rs( {} )->delete, 'delete all existing links';
}

sub crispr_wells_for_crispr_test : Test(4) {
    my $crispr_id = {crispr_id => 227040};

    can_ok(__PACKAGE__, qw( crispr_wells_for_crispr ));

    my @crisprs_returned = crispr_wells_for_crispr( model->schema, $crispr_id );

    foreach my $crispr_returned (@crisprs_returned) {

        is($crispr_returned->name, 'A01', "name of returned well");
        is($crispr_returned->plate_id, '3002', "id of plate the well is on");
    }

    $crispr_id = {crispr_id => 1234};

    my @no_crisprs_returned = crispr_wells_for_crispr( model->schema, $crispr_id );

    is(@no_crisprs_returned, '0', "can't return non-existant crispr");


}

## use critic

1;

__END__
