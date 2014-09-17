export L2I_STRING=LIMS2-Information
export L2W_STRING=LIMS2-Warning
export L2E_STRING=LIMS2-Error
export LIMS2_DEBUG_DEFINITION="perl -d"

#TODO: check that we are in the correct directory
export LIMS2_MIGRATION_ROOT=`pwd`;
export LIMS2_SHARED=~/git-checkout

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
    devel)
        lims2_devel
        ;;
    'pg9.3')
        lims2_pg9.3
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
        printf "$L2W_STRING: directory $2 does not exist but you are setting $1 to its location\n"
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
    if [[ "$1" ]] ; then
        if [[ `$LIMS2_MIGRATION_ROOT/bin/list_db_names.pl $1` == $1 ]] ; then
        export LIMS2_DB=$1
        printf "$L2I_STRING: database is now $LIMS2_DB\n"
        else 
            printf "$L2E_STRING: database '$1' does not exist in $LIMS2_DBCONNECT_CONFIG\n"
        fi
    else
        # List the databases available
        printf "$L2I_STRING: Available database names from LIMS2_DBCONNECT_CONFIG\n\n"
        $LIMS2_MIGRATION_ROOT/bin/list_db_names.pl
    fi
}

function lims2_replicate {
    case $1 in
        test)
            lims2_load_test
            ;;
        local)
            lims2_load_local
            ;;
        staging)
            lims2_load_staging
            ;;
        *)
            lims2_load_generic $1
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

function lims2_load_generic {
    if [[  "$1"   ]] ; then
        if [[ $1 != "LIMS2_LIVE" ]]; then
            lims2_replicate_generic $1 $1
        else
            printf "$L2E_STRING: Cannot replicate LIMS2_LIVE to LIMS2_LIVE\n"
        fi
    else
        printf "$L2W_STRING: No database name supplied for replication\n"
    fi
}

function lims2_replicate_generic {
    if [[ `$LIMS2_MIGRATION_ROOT/bin/list_db_names.pl $1` == $1 ]] ; then
        dbname=`$LIMS2_MIGRATION_ROOT/bin/list_db_names.pl $1 --dbname`
        printf "$L2I_STRING: preparing to replicate LIMS2_LIVE into $1 (db: $dbname)\n"
        read -p "Are you sure you want to continue with replication? (Type y to continue) " -n 1
        if [[ ! $REPLY =~ ^[Yy]$ ]]
        then
           printf "\n$L2W_STRING: replication command aborted\n"
           return
        fi
        printf "\n$L2I_STRING: continuing with database replication\n"
           perl $LIMS2_DEV_ROOT/script/lims2_clone_database.pl \
            --source_defn LIMS2_LIVE \
            --source_role lims2 \
            --destination_defn $1 \
            --destination_role lims2 \
            --destination_db $dbname \
            --overwrite 1 \
            --with_data 1 \
            --create_test_role 0 
    else 
        printf "$L2E_STRING: cannot replicate because database '$1' does not exist in $LIMS2_DBCONNECT_CONFIG\n"
    fi

}

function lims2_load_staging {
    source $LIMS2_DEV_ROOT/bin/lims2_staging_clone 
}

function lims2_devel {
    unset PERL5LIB
    export PERL5LIB=$PERL5LIB:$LIMS2_SHARED/LIMS2-WebApp/lib
    export PERL5LIB="$PERL5LIB:$LIMS2_SHARED/Eng-Seq-Builder/lib:$LIMS2_SHARED/HTGT-QC-Common/lib:$LIMS2_SHARED/LIMS2-REST-Client/lib"
    export PERL5LIB=$PERL5LIB:$LIMS2_SHARED/LIMS2-Exception/lib
    export PERL5LIB=$PERL5LIB:$LIMS2_SHARED/LIMS2-Utils/lib
    export PERL5LIB=$PERL5LIB:$LIMS2_SHARED/WebApp-Common/lib
    export PERL5LIB="$PERL5LIB:/software/pubseq/PerlModules/Ensembl/www_75_1/ensembl/modules:/software/pubseq/PerlModules/Ensembl/www_75_1/ensembl-compara/modules"
    export PERL5LIB=$PERL5LIB:/opt/t87/global/software/perl/lib/perl5
    export PERL5LIB=$PERL5LIB:/opt/t87/global/software/perl/lib/perl5/x86_64-linux-gnu-thread-multi
    export PERL5LIB=$PERL5LIB:/opt/t87/global/software/ensembl/ensembl-core-73/modules
}

function lims2_pg9.3 {
    check_and_set PSQL_EXE /opt/t87/global/software/postgres/9.3.4/bin/psql
    check_and_set PG_DUMP_EXE /opt/t87/global/software/postgres/9.3.4/bin/pg_dump
    check_and_set PG_RESTORE_EXE /opt/t87/global/software/postgres/9.3.4/bin/pg_restore
    use pg9.3
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

\$PG_DUMP_EXE                  : $PG_DUMP_EXE
\$PG_RESTORE_EXE               : $PG_RESTORE_EXE
\$PSQL_EXE                     : $PSQL_EXE

\$LIMS2_ERRBIT_CONFIG          : $LIMS2_ERRBIT_CONFIG
\$LIMS2_FCGI_CONFIG            : $LIMS2_FCGI_CONFIG
\$LIMS2_LOG4PERL_CONFIG        : $LIMS2_LOG4PERL_CONFIG
\$LIMS2_QC_CONFIG              : $LIMS2_QC_CONFIG
\$LIMS2_REPORT_CACHE_CONFIG    : $LIMS2_REPORT_CACHE_CONFIG
\$LIMS2_REPORT_DIR             : $LIMS2_REPORT_DIR
\$LIMS2_WEBAPP_CONFIG          : $LIMS2_WEBAPP_CONFIG
\$LIMS2_DBCONNECT_CONFIG       : $LIMS2_DBCONNECT_CONFIG
\$ENG_SEQ_BUILDER_CONF         : $ENG_SEQ_BUILDER_CONF
\$TARMITS_CLIENT_CONF          : $TARMITS_CLIENT_CONF
\$LIMS2_REST_CLIENT            : $LIMS2_REST_CLIENT
\$LIMS2_ENSEMBL_USER           : $LIMS2_ENSEMBl_USER
\$LIMS2_ENSEMBL_HOST           : $LIMS2_ENSEMBL_HOST
\$LIMS2_DB                     : $LIMS2_DB

END

lims2_local_environment
}

function lims2_help {
cat <<END
Summary of commands in the lims2 environment:

lims2 <command> <optional parameter>
(most variables can be set to your default favourites in ~/.lims2_local)
Commands avaiable:

    webapp       - starts the webapp server on the default port, or the port specified in
                 \$LIMS2_WEBAPP_SERVER_PORT (*) with the options specified in
                 \$LIMS2_WEBAPP_SERVER_OPTIONS (*) (-d, -r etc as desired)

    webapp <port_num> - starts the catalyst server on the specified port, overriding the value
                 specified by \$LIMS2_WEBAPP_SERVER_PORT (default $LIMS2_WEBAPP_SERVER_PORT)

    debug        - starts the catalyst server using 'perl -d '
    replicate < test | local | staging >
                 - replicates test into your own test_db (*), or live into your local db (*)
                 - replicates staging by copying from live - stop staging db first
    replicate < target_profile >
                 - replicates live into target_profile (a check is made to exclude LIMS2_LIVE as target)
    show         - show the value of useful LIMS2 variables

    local        - sets LIMS2 up to use your local database (*)
    test         - sets LIMS2 up to use your own test database (*)

    devel        - sets the environment to use entirely local checkouts (no production code)

    setdb        - lists the available database profiles, highlighting the profile currently in use
    setdb <db_name> - sets the LIMS2_DB (*) environment variable 

    help         - displays this help message
Files:
~/.lims2_local     - sourced near the end of the setup phase for you own mods
                    (*=set your default values here)
END
}

printf "Environment setup for lims2. Type 'lims2 help' for help on commands.\n"
if [[ -f $HOME/.lims2_local ]] ; then
    printf "Sourcing local mods to lims2 environment\n"
    source $HOME/.lims2_local
fi

