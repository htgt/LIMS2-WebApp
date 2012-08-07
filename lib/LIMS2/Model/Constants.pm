package LIMS2::Model::Constants;

use strict;
use warnings FATAL => 'all';

use base 'Exporter';

use Const::Fast;

BEGIN {
    our @EXPORT_OK   = qw( $DEFAULT_ASSEMBLY %PROCESS_PLATE_TYPES );
    our %EXPORT_TAGS = ();
}

const our $DEFAULT_ASSEMBLY => 'NCBIM37';

const our %PROCESS_PLATE_TYPES => (
    create_di              => [ qw( DESIGN ) ],
    int_recom              => [ qw( INT ) ],
    cre_bac_recom          => [ qw( INT ) ],
    '2w_gateway'           => [ qw( POSTINT FINAL ) ],
    '3w_gateway'           => [ qw( POSTINT FINAL ) ],
    dna_prep               => [ qw( DNA ) ],
    recombinase            => [ qw( FINAL XEP POSTINT ) ],
    first_electroporation  => [ qw( EP ) ],
    second_electroporation => [ qw( SEP ) ],
    clone_pick             => [ qw( EP_PICK SEP_PICK XEP_PICK ) ],
    clone_pool             => [ qw( SEP_POOL XEP_POOL ) ],
    freeze                 => [ qw( FP SFP ) ],
);

1;

__END__

