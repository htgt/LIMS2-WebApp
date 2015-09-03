package LIMS2::t::Model::Util::CreateProcess;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::Util::CreateProcess qw(process_plate_types);
use LIMS2::Test;

use strict;

## no critic

=head1 NAME

LIMS2/t/Model/Util/CreateProcess.pm - test class for LIMS2::Model::Util::CreateProcess

=head1 DESCRIPTION

Test module structured for running under Test::Class

=head1 METHODS

=cut

=head2 all_tests

Code to execute all tests

=cut

sub all_tests : Test(4) {
    note("Testing creation of process cell line list");

    {
        ok my $fields = model->get_process_fields( { process_type => 'first_electroporation' } ),
            'fep fields generated';
        is_deeply(
            $fields->{'cell_line'}->{'values'},
            [   'oct4:puro iCre/iFlpO #8', 'oct4:puro iCre/iFlpO #11',
                'JM8.F6',                  'JM8.N4',
                'JM8A3.N1', 'BOBSC-T6/8_B1'
            ],
            'cell line list correct'
        );
    }

    note("Testing plate type check for process which can have any plate type output");

    {
        ok my $process_plate_types = process_plate_types( model, 'rearray' );
        my $all_plate_types = [ map { $_->id } @{ model->list_plate_types } ];
        is_deeply $process_plate_types, $all_plate_types,
            'list all plate types for process not in hash';
    }

}

## use critic

1;

__END__

