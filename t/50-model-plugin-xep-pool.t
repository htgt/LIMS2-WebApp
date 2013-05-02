#!/usr/bin/env perl -d

use strict;
use warnings FATAL => 'all';

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
}

use LIMS2::Test;
use Test::Most;
use Try::Tiny;
use DateTime;
use File::Temp ':seekable';

note( "Testing xep_pool process creation" );
my $xep_pool_process_data= test_data( 'xep_pool_process.yaml' );
$DB::single=1;
{
    ok my $process = model->create_process( $xep_pool_process_data->{valid_input} ),
        'create_process for type xep_pool should succeed';
    isa_ok $process, 'LIMS2::Model::Schema::Result::Process';
    is $process->type->id, 'xep_pool',
        'process is of correct type (xep_pool)';

    ok my $input_wells = $process->input_wells, 'process can return input wells resultset';
    is $input_wells->count, 3, '...three input wells';
    my $input_well = $input_wells->next;
    # check the names of the input wells
    is $input_well->name, 'A01', 'first input well has correct name';
    # ...
    is $input_well->plate->name, 'FEPD0006_1', '..and is on correct plate';

    ok my $output_wells = $process->output_wells, 'process can return output wells resultset';
    is $output_wells->count, 1, 'only one output well';
    my $output_well = $output_wells->next;
    is $output_well->name, 'A01', 'output well has correct name';
    is $output_well->plate->name, 'XEP0006', '..and is on correct plate';

    lives_ok { model->delete_process( { id => $process->id } ) } 'can delete process';
}
#
#throws_ok {
#    my $process = model->create_process( $clone_pool_process_data->{invalid_output_well} );
#} qr/clone_pool process output well should be type (SEP_POOL|,|XEP_POOL)+ \(got SEP\)/;

done_testing();
