#!/bin/bash

DBNAME="$1"

if test -z "$DBNAME"; then
    echo "Usage: $0 DBNAME" >&2
    exit 1
fi

exec ttree --plugin_base=LIMS2::Template::Plugin --recurse --lib . --pre_process vars.tt \
  --src templates --dest "$DBNAME" --define dbname="$DBNAME"

