#!/bin/bash

####################################################################################################
# Utilities for handling separated value data
# 
# xsvutils <subcommand>
# 
# subcommand:
#   dummy
# 
####################################################################################################

OPTION_HELP=
SUBCOMMAND=
while [ "$#" != 0 ]; do
    if [ "$1" = "-h" ]; then
        OPTION_HELP=1
    elif [ "$1" = "--help" ]; then
        OPTION_HELP=1
    elif [ -z "$SUBCOMMAND" ]; then
        SUBCOMMAND=$1
        shift
        break
    fi
    shift
done

if [ -z "$SUBCOMMAND" -o -n "$OPTION_HELP" ]; then
    cat $0 | perl -nle '($s==1 && /^####/) and $s=2; $s==1 and /^# ?(.*)$/ and print $1; (!$s && /^####/) and $s=1;' >&2
    exit 0
fi

if [ "$SUBCOMMAND" = "dummy" ]; then
    bash $TOOL_DIR/dummy.sh
else
    echo "Unknown subcommand: $SUBCOMMAND" >&2
    exit 1
fi

