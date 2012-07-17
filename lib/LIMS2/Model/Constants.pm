package LIMS2::Model::Constants;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Constants::VERSION = '0.007';
}
## use critic


use strict;
use warnings FATAL => 'all';

use base 'Exporter';

use Const::Fast;

BEGIN {
    our @EXPORT_OK   = qw( $DEFAULT_ASSEMBLY );
    our %EXPORT_TAGS = ();
}

const our $DEFAULT_ASSEMBLY => 'NCBIM37';

1;

__END__

