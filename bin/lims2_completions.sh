#!/bin/bash
function _lims2_completions {
    COMPREPLY=()
    local curr=${COMP_WORDS[COMP_CWORD]}
    if [[ $COMP_CWORD -eq 1 ]]; then
        COMPREPLY=($(compgen -W "help show webapp debug setdb local test replicate devel wge pg9.3 psql audit regenerate_schema" -- "$curr"))
    elif [[ $COMP_CWORD -eq 2 ]]; then
        case ${COMP_WORDS[1]} in
            setdb)
                local dbs=($($LIMS2_MIGRATION_ROOT/bin/list_db_names.pl --list))
                local ILS=" "
                local options="${dbs[@]}"
                COMPREPLY=($(compgen -W "$options" -- "$curr"))
                ;;
            replicate)
                COMPREPLY=($(compgen -W "test local staging" -- "$curr"))
                ;;
            wge)
                COMPREPLY=($(compgen -W "live devel" -- "$curr"))
                ;;
            *)
                ;;
        esac
    fi
}
complete -F _lims2_completions lims2

