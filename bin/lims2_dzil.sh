#!/bin/bash

declare result

while [ $# -gt 0 ]; do
    case "$1" in
        --opt=*)
            opt="${1#*=}"
            ;;
        --js=*)
            js="${1#*=}"
            ;;
        --perl=*)
            perl="${1#*=}"
            ;;
        *)
            echo "------------------------------------------------------------"
            printf "Invalid argument.\n"
            printf "Usage: --opt=test.\n"
            printf "Options:\n"
            printf "\t--opt=test/release (which dzil operation)\n"
            printf "\t--js=0/1 (Turn JS tests on or off. Default 1.)\n"
            printf "\t--perl=0/1 (Turn Perl tests on or off. Default 1.)\n"
            echo "------------------------------------------------------------"
            exit 1
    esac
    shift
done

if [ "$js" == '0' ] && [ "$perl" == '0' ]; then
    result="__"
    echo "WARNING! No tests will be run!"
else
    if [ "$js" == '0' ]; then
        result="_p"
        echo "JavaScript tests have been switched off"
    elif [ "$perl" == '0' ]; then
        result="j_"
        echo "Perl tests have been switched off"
    else
        result="jp"
    fi
fi 

export TEST_OPTS="$result"

if [ "$opt" == 'release' ]; then
    dzil release
else
    dzil test
fi
