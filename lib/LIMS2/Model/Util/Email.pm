package LIMS2::Model::Util::Email;

use Moose::Role;
use File::Which;

has 'can_email' => (
    is         => 'ro',
    isa        => 'Bool',
    lazy_build => 1,
);

sub _build_can_email {
    my $sendmail = which 'sendmail';
    return (defined $sendmail) && !(exists $ENV{LIMS2_NO_MAIL});
}

1;

