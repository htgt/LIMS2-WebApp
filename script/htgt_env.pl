#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Config::General;
use Getopt::Long;
use Pod::Usage;
use Readonly;

#this is all of the HTGT::Env package merged into a single file, so it
#can be run from within LIMS2 hassle free.

{
    package HTGT::EnvVar::Scalar;

    use Moose;

    has 'value' => (
        is  => 'rw',
        isa => 'Str',
        default => '',
    );

    sub merge {
        my ( $self, $new_value ) = @_;
        $self->value( $new_value );
    }

    sub as_str {
        my ( $self ) = @_;
        $self->value;
    }
}

{
    package HTGT::EnvVar::List;

    use Moose;
    use Moose::Util::TypeConstraints;

    subtype 'ArrayRefOfStrs'
        => as 'ArrayRef[Str]';

    coerce 'ArrayRefOfStrs'
        => from 'Str'
        => via { [ reverse split /:/ ] };
        
    has 'values' => (
        is => 'rw',
        isa => 'ArrayRefOfStrs',
        coerce => 1,
        default => sub { [] }, 
    );

    sub merge {
        my ( $self, $new_values ) = @_;

        if ( not ref $new_values ) {
            push @{ $self->values }, reverse split /:/, $new_values;
        }    
        elsif ( ref $new_values eq 'ARRAY' ) {
            push @{ $self->values }, @{ $new_values };
        }
        else {
            confess( "cannot set list environment variable to " . ref $new_values );
        }
    }

    sub as_str {
        my ( $self ) = @_;
        join ":", reverse @{ $self->values };
    }
}

{
    package HTGT::Env;

    use Path::Class ();
    use Moose;

    has '_env_vars' => (
        is       => 'rw',
        isa      => 'HashRef',
        init_arg => undef,
        default  => sub { {} }, 
    );

    sub add {
        my ( $self, $args ) = @_;

        my $name = $args->{name};
        confess( "cannot add duplicate variable '$name' to environment" )
            if $self->var($name);

        my $class;        
        if ( uc( $args->{type} ) eq 'SCALAR' ) {
            $class = 'HTGT::EnvVar::Scalar';
        }
        elsif ( uc( $args->{type} ) eq 'LIST' ) {
            $class = 'HTGT::EnvVar::List';
        }
        else {
            confess( "illegal type '$args->{type}' for environment variable" );
        }
        
        my $envvar = $class->new();
        $envvar->merge( $args->{value} )
            if defined $args->{value};
        
        $self->_env_vars->{$name} = $envvar;
        
    }

    sub add_application_paths {
        my ( $self, $base_dir, @app_config ) = @_;
        
        # Merge arguments, each of which should be a hashref, into a single hash, with
        # later arguments overriding earlier ones.
        my %applications = ( map %$_, grep defined, @app_config );
        
        $self->add( { name => 'PATH', type => 'LIST' } )
            unless $self->exists( 'PATH' );
            
        while ( my ( $name, $version ) = each %applications ) {
            my @bin_dirs;
            for my $bin ( qw( bin sbin ) ) {
                my $dir = Path::Class::dir( $base_dir, "$name-$version", $bin );
                push @bin_dirs, $dir
                    if -d $dir;
            }
            confess( "cannot find bin path for $name $version" )
                unless @bin_dirs;
            $self->var( 'PATH' )->merge( \@bin_dirs );
        }        
    }

    sub add_extras {
        my ( $self, $extras ) = @_;
        
        while ( my ( $name, $values ) = each %{ $extras } ) {
            if ( $self->exists( $name ) ) {
                if ( $self->var( $name )->isa( 'HTGT::EnvVar::Scalar' ) ) {
                    confess "cannot add multiple values to a scalar env var" unless @{ $values } == 1;
                    $self->var( $name )->merge( shift @{$values} );
                }
                else {
                    $self->var( $name )->merge( $values );
                }
            }
            elsif ( @{$values} == 1 ) {
                $self->add( { name => $name, type => 'SCALAR', value => shift @{$values} } );
            }
            else {
                $self->add( { name => $name, type => 'LIST', value => $values } );
            }
        }
    }

    sub var {
        my ( $self, $name ) = @_;
        return $self->_env_vars->{$name};
    }

    sub exists {
        my ( $self, $name ) = @_;
        exists $self->_env_vars->{ $name };
    }

    sub as_hash {
        my ( $self ) = @_;
        
        my %hash;
        foreach my $name ( keys %{ $self->_env_vars } ) {
            $hash{ $name } = $self->var( $name )->as_str;
        }
        
        return \%hash;
    }
}

Readonly my $DEFAULT_CONFFILE => '/software/team87/brave_new_world/conf/environment.conf';
Readonly my $DEFAULT_ENV      => 'Devel';

my $envname  = $DEFAULT_ENV;
my $conffile = $DEFAULT_CONFFILE;
my $clearenv;

Getopt::Long::Configure( qw( require_order pass_through ) );

GetOptions(
    'help'          => sub { pod2usage( -verbose => 1 ) },
    'man'           => sub { pod2usage( -verbose => 2 ) },
    'live'          => sub { $envname = 'Live' },
    'staging'       => sub { $envname = 'Staging' },
    'devel'         => sub { $envname = 'Devel' },
    'environment=s' => \$envname,
    'config=s'      => \$conffile,
    'clear-env'     => \$clearenv,
) or pod2usage(2);

my %conf = Config::General->new(
     -ConfigFile           => $conffile,
     -MergeDuplicateBlocks => 'yes',
     -InterPolateVars      => 'yes',
     -InterPolateEnv       => 'yes',
     -StrictVars           => 'yes',
)->getall;

my $env_conf = $conf{Environment}{$envname}
    or die "Environment '$envname' not configured\n";
    
my $env_global = $conf{Environment}{GLOBAL};

my %env_extra;
while ( @ARGV ) { 
    my ( $name, $value ) = $ARGV[0] =~ qr/^(\w+)=(\S+)$/
        or last;
    $env_extra{ $name } = [ split ":", $value ];
    shift @ARGV;
}

my @cmd;
if ( @ARGV ) {
    #run the users command in a new shell if desired
    if ( exists $conf{ always_new_shell } and $conf{ always_new_shell } ) {
        #we must set BASH_ENV as this is run in non-interactive mode, so we cant use --rcfile, 
        #but whatever is in bash_env will get excuted.
        $env_extra{ BASH_ENV } = [ $conf{ bashrc } ];
        #then we dont need --rcfile/-i
        @cmd = ( 
            $conf{ bash },
            #'--rcfile', $conf{ bashrc },
            '-c', join( " ", @ARGV ), #run the users command in a new interactive bash shell 
        );
    }
    else {
        @cmd = @ARGV; #just run their command
    }
}
else {
    #create a new bash shell if there's no command specified
    @cmd = ( $conf{bash}, '--rcfile', $conf{bashrc} );
}

my $env = HTGT::Env->new();

while ( my ( $varname, $type) = each %{ $conf{Export} } ) {
    $env->add(
        {
            name  => $varname,
            type  => $type,
            value => $env_global->{ $varname } 
        }
    );
    $env->var( $varname )->merge( $env_conf->{$varname} )
        if defined $env_conf->{$varname};
}

$env->add_application_paths( $conf{app_home}, $conf{Applications}, $env_conf->{Applications} );

$env->add_extras( \%env_extra );

$env->add( { name => 'HTGT_ENV', type => 'SCALAR', value => $envname } );

if ( $clearenv ) {
    %ENV = %{ $env->as_hash };
}
else {
    %ENV = ( %ENV, %{ $env->as_hash } );
}
exec @cmd;
die "failed to execute @cmd: $!";

__END__