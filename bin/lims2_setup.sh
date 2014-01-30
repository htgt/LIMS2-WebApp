function lims2 {
case $1 in
    help)
        lims2_help
        ;;
    show)
        lims2_show
        ;;
    webapp)
        lims2_webapp
        ;;
    debug)
        lims2_webapp_debug
        ;;
    setdb)
        lims2_setdb $2
        ;;
    local)
        lims2_local_db
        ;;
    test)
        lims2_test_db
        ;;
    replicate)
        lims2_replicate $2
        ;;
    *) 
        printf "Usage: lims2 sub-command [option]\n"
        printf "see 'lims2 help' for commands and options\n"
esac
}

function check_and_set {
    if [[ ! -f $2 ]] ; then
        printf "$L2W_STRING: $2 does not exist but you are setting $1 to its location\n"
    fi
    export $1=$2
}

function check_and_set_dir {
    if [[ ! -d $2 ]] ; then
        printf "L2W_STRING: directory $2 does not exist but you are setting $1 to its location\n"
    fi
    export $1=$2
}

function lims2_webapp {
    if [[  "$1"   ]] ; then
        LIMS2_PORT=$1 
    elif [[ "$LIMS2_WEBAPP_SERVER_PORT"  ]] ; then
        LIMS2_PORT=$LIMS2_WEBAPP_SERVER_PORT
    else
        LIMS2_PORT=3000
    fi
    printf "starting LIMS2 webapp on port $LIMS2_PORT";
    if [[ "$LIMS2_WEBAPP_SERVER_OPTIONS" ]] ; then
        printf " with options $LIMS2_WEBAPP_SERVER_OPTIONS";
    fi
    printf "\n\n"
    printf "$L2I_STRING: $LIMS2_DEBUG_COMMAND $LIMS2_DEV_ROOT/script/lims2_webapp_server.pl -p $LIMS2_PORT $LIMS2_WEBAPP_SERVER_OPTIONS\n"
    $LIMS2_DEBUG_COMMAND $LIMS2_DEV_ROOT/script/lims2_webapp_server.pl -p $LIMS2_PORT $LIMS2_WEBAPP_SERVER_OPTIONS
}

function lims2_webapp_debug {
    LIMS2_DEBUG_COMMAND=$LIMS2_DEBUG_DEFINITION
    lims2_webapp $1
    unset LIMS2_DEBUG_COMMAND
}


function lims2_setdb {
    export LIMS2_DB=$1
    printf "$L2I_STRING: database is now $LIMS2_DB\n"
}

function lims2_replicate {
    case $1 in
        test)
            lims2_load_test
            ;;
        local)
            lims2_load_local
            ;;
        *)
            printf "Don't know how to replicate $1\n";
            ;; 
    esac
}

function lims2_load_test {
    printf "lims2_load_test should be implemented in ~/.lims2_local\n"
}

function lims2_load_local {
    printf "lims2_load_local should be implemented in ~/.lims2_local\n"
}

function lims2_local_db {
    printf "lims2_local_db should be implemented in ~/.lims2_local\n"
}

function lims2_test_db {
    printf "lims2_test_db should be implemented in ~/.lims2_local\n"
}

function lims2_show {
cat << END
LIMS2 useful environment variables:

\$LIMS2_DEV_ROOT               : $LIMS2_DEV_ROOT
\$SAVED_LIMS2_DEV_ROOT         : $SAVED_LIMS2_DEV_ROOT 
\$LIMS2_WEBAPP_SERVER_PORT     : $LIMS2_WEBAPP_SERVER_PORT
\$LIMS2_WEBAPP_SERVER_OPTIONS  : $LIMS2_WEBAPP_SERVER_OPTIONS
\$LIMS2_DEBUG_DEFINITION       : $LIMS2_DEBUG_DEFINITION

\$PERL5LIB :
`perl -e 'print( join("\n", split(":", $ENV{PERL5LIB}))."\n")'`

\$PATH :
`perl -e 'print( join("\n", split(":", $ENV{PATH}))."\n")'`

\$LIMS2_ERRBIT_CONFIG          : $LIMS2_ERRBIT_CONFIG
\$LIMS2_FCGI_CONFIG            : $LIMS2_FCGI_CONFIG
\$LIMS2_LOG4PERL_CONFIG        : $LIMS2_LOG4PERL_CONFIG
\$LIMS2_QC_CONFIG              : $LIMS2_QC_CONFIG
\$LIMS2_REPORT_CACHE_CONFIG    : $LIMS2_REPORT_CACHE_CONFIG
\$LIMS2_WEBAPP_CONFIG          : $LIMS2_WEBAPP_CONFIG
\$LIMS2_DBCONNECT_CONFIG       : $LIMS2_DBCONNECT_CONFIG
\$ENG_SEQ_BUILDER_CONF         : $ENG_SEQ_BUILDER_CONF
\$TARMITS_CLIENT_CONF          : $TARMITS_CLIENT_CONF
\$LIMS2_REST_CLIENT            : $LIMS2_REST_CLIENT
\$LIMS2_DB                     : $LIMS2_DB

END

lims2_local_environment
}

function lims2_help {
cat <<END
Summary of commands in the lims2 environment:

lims2 <command> <optional parameter>
(most variables can be set to your default favourites in ~/.lims2_local)
commands avaiable:

    webapp       - starts the webapp server on the default port, or the port specified in
                 \$LIMS2_WEBAPP_SERVER_PORT (*) with the options specified in
                 \$LIMS2_WEBAPP_SERVER_OPTIONS (*) (-d, -r etc as desired)

    webapp <port_num> - starts the catalyst server on the specified port, overriding the value
                 specified by \$LIMS2_WEBAPP_SERVER_PORT (default $LIMS2_WEBAPP_SERVER_PORT)

    debug        - starts the catalyst server using 'perl -d '
    show         - show the value of useful LIMS2 variables

    setdb <db_name> - sets the LIMS2_DB (*) environment variable 

    help         - displays this help message
Files:
~/.lims2_local     - sourced near the end of the setup phase for you own mods
                    (*=set your default values here)
END
}

export L2I_STRING=LIMS2-Information
export L2W_STRING=LIMS2-Warning
export L2E_STRING=LIMS2-Error
export LIMS2_DEBUG_DEFINITION="perl -d"

printf "Environment setup for lims2. Type 'lims2 help' for help on commands.\n"
if [[ -f $HOME/.lims2_local ]] ; then
    printf "Sourcing local mods to lims2 environment\n"
    source $HOME/.lims2_local
fi

