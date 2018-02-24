#!/bin/bash

VERSION_HASH=XXXX_VERSION_HASH_XXXX

export TOOL_DIR=$HOME/.xsvutils/version-$VERSION_HASH

if [ ! -e $TOOL_DIR ]; then
    tool_parent_dir=$(dirname $TOOL_DIR)
    if [ ! -e $tool_parent_dir ]; then
        mkdir -p $tool_parent_dir
    fi

    mkdir $TOOL_DIR.tmp 2>/dev/null
    cat $0 | (
        cd $TOOL_DIR.tmp
        perl -ne 'print $_ if $f; $f=1 if /^#SOURCE_IMAGE$/' | tar xzf - 2>/dev/null
    )
    mkdir $TOOL_DIR 2>/dev/null && mv $TOOL_DIR.tmp/* $TOOL_DIR/ && rm -rf $TOOL_DIR.tmp
fi

if [ ! -e $TOOL_DIR ]; then
    echo error >&2
    exit 1;
fi

if [ -z "$UID" ]; then
    UID=$(id -u)
fi
if [ -d /run/user/$UID ]; then
    export WORKING_DIR=$(mktemp -d /run/user/$UID/xsvutils-XXXXXXXX)
elif [ -d /dev/shm ]; then
    export WORKING_DIR=$(mktemp -d /dev/shm/xsvutils-XXXXXXXX)
else
    export WORKING_DIR=$(mktemp -d /tmp/xsvutils-XXXXXXXX)
fi
[ -n "$WORKING_DIR" ] || { echo "Cannot WORKING_DIR: $WORKING_DIR"; exit $?; }
trap "rm -rf $WORKING_DIR" EXIT

tput lines >/dev/null 2>&1 && export TERMINAL_LINES=$(tput lines);

if [ "$1" = "-v1" ]; then
    shift
    perl $TOOL_DIR/main.pl "$@"
elif [ "$1" = "-v2" ]; then
    shift
    perl $TOOL_DIR/main2.pl "$@"
else
    perl $TOOL_DIR/main.pl "$@"
fi

exit $?

#SOURCE_IMAGE
