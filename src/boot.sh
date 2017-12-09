#!/bin/bash

VERSION_HASH=XXXX_VERSION_HASH_XXXX

export TOOL_DIR=$HOME/.xsvutils/version-$VERSION_HASH

if [ ! -e $TOOL_DIR ]; then
    tool_parent_dir=$(dirname $TOOL_DIR)
    if [ ! -e $tool_parent_dir ]; then
        mkdir -p $tool_parent_dir
    fi

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

exec perl $TOOL_DIR/main.pl "$@"

#SOURCE_IMAGE
