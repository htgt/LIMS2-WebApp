package LIMS2::Model::Constants;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Constants::VERSION = '0.045';
}
## use critic


use strict;
use warnings FATAL => 'all';

use base 'Exporter';

use Const::Fast;

BEGIN {
    our @EXPORT_OK = qw(
        $DEFAULT_ASSEMBLY
        %PROCESS_PLATE_TYPES
        %PROCESS_SPECIFIC_FIELDS
        %PROCESS_TEMPLATE
        %PROCESS_INPUT_WELL_CHECK
    );
    our %EXPORT_TAGS = ();
}

const our $DEFAULT_ASSEMBLY => 'NCBIM37';

const our %PROCESS_PLATE_TYPES => (
    create_di              => [qw( DESIGN )],
    int_recom              => [qw( INT )],
    cre_bac_recom          => [qw( INT )],
    '2w_gateway'           => [qw( POSTINT FINAL )],
    '3w_gateway'           => [qw( POSTINT FINAL )],
    dna_prep               => [qw( DNA )],
    recombinase            => [qw( FINAL XEP POSTINT )],
    first_electroporation  => [qw( EP )],
    second_electroporation => [qw( SEP )],
    clone_pick             => [qw( EP_PICK SEP_PICK XEP_PICK )],
    clone_pool             => [qw( SEP_POOL XEP_POOL )],
    freeze                 => [qw( FP SFP )],
);

const our %PROCESS_SPECIFIC_FIELDS => (
    int_recom             => [qw( intermediate_cassette intermediate_backbone )],
    cre_bac_recom         => [qw( intermediate_cassette intermediate_backbone )],
    '2w_gateway'          => [qw( final_cassette final_backbone recombinase )],
    '3w_gateway'          => [qw( final_cassette final_backbone recombinase )],
    recombinase           => [qw( recombinase )],
    first_electroporation => [qw( cell_line )],
);

const our %PROCESS_TEMPLATE => (
    int_recom              => 'recombineering_template.csv',
    cre_bac_recom          => 'recombineering_template.csv',
    '2w_gateway'           => 'gateway_template.csv',
    '3w_gateway'           => 'gateway_template.csv',
    dna_prep               => 'standard_template.csv',
    recombinase            => 'recombinase_template.csv',
    first_electroporation  => 'first_electroporation_template.csv',
    second_electroporation => 'second_electroporation_template.csv',
    clone_pick             => 'standard_template.csv',
    clone_pool             => 'standard_template.csv',
    freeze                 => 'standard_template.csv',
);

const our %PROCESS_INPUT_WELL_CHECK => (
    create_di => { number => 0 },
    int_recom => {
        type   => [qw( DESIGN )],
        number => 1,
    },
    '2w_gateway' => {
        type   => [qw( INT POSTINT )],
        number => 1,
    },
    '3w_gateway' => {
        type   => [qw( INT )],
        number => 1,
    },
    recombinase   => { number => 1 },
    cre_bac_recom => {
        type   => [qw( DESIGN )],
        number => 1,
    },
    rearray  => { number => 1 },
    dna_prep => {
        type   => [qw( FINAL )],
        number => 1,
    },
    clone_pick => {
        type   => [qw( EP XEP SEP )],
        number => 1,
    },
    clone_pool => {
        type   => [qw( XEP SEP )],
        number => 1,
    },
    first_electroporation => {
        type   => [qw( DNA )],
        number => 1,
    },
    second_electroporation => {
        type   => [qw( XEP DNA )],
        number => 2,
    },
    freeze => {
        type   => [qw( EP_PICK SEP_PICK )],
        number => 1,
    },
);

1;

__END__
