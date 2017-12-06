#!/bin/bash

VERSION_HASH=XXXX_VERSION_HASH_XXXX

if [ -z "$UID" ]; then
    UID=$(id -u)
fi
if [ -d /run/user/$UID ]; then
    export TOOL_DIR=/run/user/$UID/xsvutils-$VERSION_HASH
elif [ -d /dev/shm ]; then
    export TOOL_DIR=/dev/shm/xsvutils-$VERSION_HASH
else
    export TOOL_DIR=/tmp/xsvutils-$VERSION_HASH
fi

if [ ! -e $TOOL_DIR ]; then
    mkdir $TOOL_DIR.tmp
    cat $0 | (
        cd $TOOL_DIR.tmp
        perl -ne 'print $_ if $f; $f=1 if /^#SOURCE_IMAGE$/' | tar xzf -
    )
    mkdir $TOOL_DIR 2>/dev/null && mv $TOOL_DIR.tmp/* $TOOL_DIR/
    rm -rf $TOOL_DIR.tmp
fi

if [ ! -e $TOOL_DIR ]; then
    echo error >&2
    exit 1;
fi

exec bash $TOOL_DIR/main.sh "$@"

#SOURCE_IMAGE
