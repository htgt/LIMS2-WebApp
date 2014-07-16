package LIMS2::Model::Constants;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Constants::VERSION = '0.218';
}
## use critic


use strict;
use warnings FATAL => 'all';

use base 'Exporter';

use Const::Fast;

BEGIN {
    our @EXPORT_OK = qw(
        %PROCESS_PLATE_TYPES
        %PROCESS_SPECIFIC_FIELDS
        %PROCESS_TEMPLATE
        %PROCESS_INPUT_WELL_CHECK
        %ARTIFICIAL_INTRON_OLIGO_APPENDS
        %STANDARD_KO_OLIGO_APPENDS
        %STANDARD_INS_DEL_OLIGO_APPENDS
        %GIBSON_OLIGO_APPENDS
        %ADDITIONAL_PLATE_REPORTS
        %UCSC_BLAT_DB
        %DEFAULT_SPECIES_BUILD
        %VECTOR_DNA_CONCENTRATION
        %GLOBAL_SHORTENED_OLIGO_APPEND
    );
    our %EXPORT_TAGS = ();
}

# Possible output plate types for process types (all if not listed)
const our %PROCESS_PLATE_TYPES => (
    'create_di'              => [qw( DESIGN )],
    'create_crispr'          => [qw( CRISPR )],
    'int_recom'              => [qw( INT )],
    'cre_bac_recom'          => [qw( INT )],
    'global_arm_shortening'  => [qw( INT )],
    '2w_gateway'             => [qw( POSTINT FINAL )],
    '3w_gateway'             => [qw( POSTINT FINAL )],
    'legacy_gateway'         => [qw( FINAL_PICK )],
    'final_pick'             => [qw( FINAL_PICK )],
    'dna_prep'               => [qw( DNA )],
    'recombinase'            => [qw( FINAL XEP POSTINT )],
    'first_electroporation'  => [qw( EP )],
    'second_electroporation' => [qw( SEP )],
    'clone_pick'             => [qw( EP_PICK SEP_PICK XEP_PICK )],
    'clone_pool'             => [qw( SEP_POOL XEP_POOL )],
    'freeze'                 => [qw( FP SFP )],
    'xep_pool'               => [qw( XEP )],
    'dist_qc'                => [qw( PIQ )],
    'crispr_vector'          => [qw( CRISPR_V )],
    'single_crispr_assembly' => [qw( ASSEMBLY )],
    'paired_crispr_assembly' => [qw( ASSEMBLY )],
    'crispr_ep'              => [qw( CRISPR_EP )],
);

# Additional information required at upload for process types (none if not listed)
const our %PROCESS_SPECIFIC_FIELDS => (
    'int_recom'              => [qw( intermediate_cassette backbone )],
    'cre_bac_recom'          => [qw( intermediate_cassette intermediate_backbone )],
    'global_arm_shortening'  => [qw( intermediate_backbone )],
    '2w_gateway'             => [qw( final_cassette final_backbone recombinase )],
    '3w_gateway'             => [qw( final_cassette final_backbone recombinase )],
    'recombinase'            => [qw( recombinase )],
    'clone_pick'             => [qw( recombinase )],
    'first_electroporation'  => [qw( cell_line recombinase )],
    'second_electroporation' => [qw( recombinase )],
    'crispr_ep'              => [qw( cell_line nuclease )],
    'crispr_vector'          => [qw( backbone )],
#    'xep_pool'              => [qw( recombinase )],
);

# Upload template to use for each process type, downloadable from bottom of upload screen
const our %PROCESS_TEMPLATE => (
    'int_recom'              => 'recombineering_template',
    'cre_bac_recom'          => 'recombineering_template',
    'global_arm_shortening'  => 'global_arm_shortening_template',
    '2w_gateway'             => 'gateway_template',
    '3w_gateway'             => 'gateway_template',
    'final_pick'             => 'standard_template',
    'dna_prep'               => 'standard_template',
    'recombinase'            => 'recombinase_template',
    'first_electroporation'  => 'first_electroporation_template',
    'second_electroporation' => 'second_electroporation_template',
    'clone_pick'             => 'standard_template',
    'clone_pool'             => 'standard_template',
    'freeze'                 => 'standard_template',
    'xep_pool'               => 'standard_template',
    'dist_qc'                => 'piq_template',
    'single_crispr_assembly' => 'single_crispr_assembly_template',
    'paired_crispr_assembly' => 'paired_crispr_assembly_template',
    'crispr_ep'              => 'crispr_ep_template',
);

# number relates to number of input wells (e.g. an SEP has two inputs)
# and type to their plate type(s). N.B. if you don't specify a type then any is fine
const our %PROCESS_INPUT_WELL_CHECK => (
    'create_di' => { number => 0 },
    'create_crispr' => { number => 0 },
    'int_recom' => {
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
    'legacy_gateway' => {
        type   => [qw( INT )],
        number => 1,
    },
    'global_arm_shortening' => {
        type   => [qw( INT )],
        number => 1,
    },
    'final_pick' => {
        type   => [qw( FINAL FINAL_PICK )],
        number => 1,
    },
    'recombinase' => {
        number => 1,
    },
    'cre_bac_recom' => {
        type   => [qw( DESIGN )],
        number => 1,
    },
    'rearray'  => {
        number => 1
    },
    'dna_prep' => {
        type   => [qw( FINAL FINAL_PICK CRISPR_V )],
        number => 1,
    },
    'clone_pick' => {
        type   => [qw( EP XEP SEP CRISPR_EP )],
        number => 1,
    },
    'clone_pool' => {
        type   => [qw( XEP SEP )],
        number => 1,
    },
    'first_electroporation' => {
        type   => [qw( DNA )],
        number => 1,
    },
    'second_electroporation' => {
        type   => [qw( XEP DNA )],
        number => 2,
    },
    'freeze' => {
        type   => [qw( EP_PICK SEP_PICK )],
        number => 1,
    },
    'xep_pool' => {
        type   => [qw( EP EP_PICK )],
        number => 'MULTIPLE',
    },
    'dist_qc' => {
        type   => [qw( FP SFP )],
        number => 1,
    },
    'crispr_vector' => {
        type   => [qw( CRISPR )],
        number => 1,
    },
    'single_crispr_assembly' => {
        type   => [qw( DNA )],
        number => 2,
    },
    'paired_crispr_assembly' => {
        type   => [qw( DNA )],
        number => 3,
    },
    'crispr_ep' => {
        type   => [qw( ASSEMBLY )],
        number => 1,
    },
);

const our %ARTIFICIAL_INTRON_OLIGO_APPENDS => (
    "G3" => "CCACTGGCCGTCGTTTTACA",
    "G5" => "TCCTGTGTGAAATTGTTATCCGC",
    "D3" => "TGAACTGATGGCGAGCTCAGACC",
    "D5" => "GAGATGGCGCAACGCAATTAATG",
    "U3" => "CTGAAGGAAATTAGATGTAAGGAGC",
    "U5" => "GTGAGTGTGCTAGAGGGGGTG",
);

const our %STANDARD_KO_OLIGO_APPENDS => (
    "G5" => "TCCTGTGTGAAATTGTTATCCGC",
    "G3" => "CCACTGGCCGTCGTTTTACA",
    "U5" => "AAGGCGCATAACGATACCAC",
    "U3" => "CCGCCTACTGCGACTATAGA",
    "D5" => "GAGATGGCGCAACGCAATTAATG",
    "D3" => "TGAACTGATGGCGAGCTCAGACC",
);

const our %STANDARD_INS_DEL_OLIGO_APPENDS => (
    "G5" => "TCCTGTGTGAAATTGTTATCCGC",
    "G3" => "CCACTGGCCGTCGTTTTACA",
    "U5" => "AAGGCGCATAACGATACCAC",
    "D3" => "CCGCCTACTGCGACTATAGA",
);

const our %GIBSON_OLIGO_APPENDS => (
    "5F" => "AACGACGGCCAGTGAATTCGAT",
    "5R" => "TATCGTTATGCGCCTTGAT",
    "EF" => "TAGTCGCAGTAGGCGGAAGA",
    "ER" => "AGCCAATTGGCGGCCGAAGA",
    "3F" => "CTGAGCTAGCCATCAGTGAT",
    "3R" => "CCATGATTACGCCAAGCTTGAT",
);

const our %GLOBAL_SHORTENED_OLIGO_APPEND => (
    "G5" => "ACAACTTATATCGTATGGGGC",
    "G3" => "TTACGCCCCGCCCTGCCACTC",
);

# When creating additional report classes override the additional_report sub to return 1
const our %ADDITIONAL_PLATE_REPORTS => (
    DESIGN => [
        {
            class  => 'DesignPlateOrderSheet',
            method => 'async',
            name   => 'Design Plate Order Sheet',
        },
        {
            class  => 'SummaryOligoPlate',
            method => 'sync',
            name   => 'Summary by Oligo Plate',
        },
    ],
    CRISPR => [
        {
            class  => 'CrisprPlateOrderSheet',
            method => 'async',
            name   => 'Crispr Plate Order Sheet',
        }
    ],
    EP => [
        {
            class  => 'EPPrint',
            method => 'sync',
            name   => 'EP Print',
        }
    ],
);

const our %UCSC_BLAT_DB => (
    mouse => 'mm10',
    human => 'hg19',
);

const our %DEFAULT_SPECIES_BUILD => (
    mouse => 73,
    human => 73,
);

# Minimun required DNA concentrations for different species and vector types
# Unit is ng per ul
const our %VECTOR_DNA_CONCENTRATION => (
    'Human' => {
        'FINAL_PICK' => 20,
        'CRISPR_V'   => 30,
    },
    'Mouse' => {
        'CRISPR_V'   => 40,
    },
);
1;

__END__
