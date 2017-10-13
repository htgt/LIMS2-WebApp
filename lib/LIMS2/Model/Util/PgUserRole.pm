package LIMS2::Model::Util::PgUserRole;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::PgUserRole::VERSION = '0.478';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [ qw( db_name create_pg_user set_pg_roles ) ]
};

use LIMS2::Exception::Database;
use Log::Log4perl qw( :easy );

sub db_name {
    my ($dbh) = @_;

    my ($db_name) = $dbh->{Name} =~ m/(?:^|;)dbname=([^;]+)/
        or LIMS2::Exception::Database->throw("Unable to determine database name");

    return $db_name;
}

sub create_pg_user {
    my ( $dbh, $user_name, $user_roles ) = @_;

    my $db_name = db_name($dbh);

    #my $whoami      = $dbh->{Username};
    #DEBUG("Logged in as '$whoami'");
    my $admin_role  = $dbh->quote_identifier( 'lims2' );
    my $webapp_role = $dbh->quote_identifier( 'lims2_webapp' );
    my $new_role    = $dbh->quote_identifier($user_name);

    $dbh->do("SET LOCAL ROLE $admin_role");

    my ($count) = $dbh->selectrow_array( "SELECT COUNT(*) FROM pg_roles WHERE rolname = ?", undef, $user_name );
    if ( $count > 0 ) {
        DEBUG("Role $new_role already exists");
    }
    else {
        DEBUG("Creating role $new_role");
        $dbh->do("CREATE ROLE $new_role INHERIT");
    }

    DEBUG("Granting $admin_role to $new_role");
    $dbh->do("GRANT $admin_role TO $new_role");
    DEBUG("Granting $new_role to $webapp_role");
    $dbh->do("GRANT $new_role TO $webapp_role");

    #set_pg_roles( $dbh, $user_name, $user_roles );

    return;
}

sub set_pg_roles {
    my ( $dbh, $user_name, $user_roles ) = @_;

    $user_name = $dbh->quote_identifier($user_name);

    my $db_name = db_name($dbh);

    my $ro_role    = $dbh->quote_identifier( $db_name . '_ro' );
    my $rw_role    = $dbh->quote_identifier( $db_name . '_rw' );
    my $admin_role = $dbh->quote_identifier( $db_name . '_admin' );
    my $inter_role = $dbh->quote_identifier( $db_name . '_inter_admin' );

#    $dbh->do("SET LOCAL ROLE $admin_role");
#
#    if ( grep { $_ eq 'read' } @{$user_roles} ) {
#        DEBUG("Granting $ro_role to $user_name");
#        $dbh->do("GRANT $ro_role TO $user_name");
#    }
#    else {
#        DEBUG("Revoking $ro_role from $user_name");
#        $dbh->do("REVOKE $ro_role FROM $user_name");
#    }
#
#    if ( grep { $_ eq 'edit' } @{$user_roles} ) {
#        DEBUG("Granting $rw_role to $user_name");
#        $dbh->do("GRANT $rw_role TO $user_name");
#    }
#    else {
#        DEBUG("Revoking $rw_role from $user_name");
#        $dbh->do("REVOKE $rw_role FROM $user_name");
#    }
#
#    if ( grep { $_ eq 'admin' } @{$user_roles} ) {
#        DEBUG("Granting $inter_role to $user_name");
#        $dbh->do("GRANT $inter_role TO $user_name");
#    }
#    else {
#        DEBUG("Revoking $inter_role from $user_name");
#        $dbh->do("REVOKE $inter_role FROM $user_name");
#    }

    return;
}

1;

__END__
