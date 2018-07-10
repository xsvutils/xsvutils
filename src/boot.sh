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
        cd $TOOL_DIR.tmp || exit $?
        perl -ne 'print $_ if $f; $f=1 if /^#SOURCE_IMAGE$/' | tar xzf - 2>/dev/null
    )
    mkdir $TOOL_DIR 2>/dev/null && mv $TOOL_DIR.tmp/* $TOOL_DIR/ && rm -rf $TOOL_DIR.tmp
fi

if [ ! -e $TOOL_DIR ]; then
    echo error >&2
    exit 1;
fi

VERSION=

if [ "$1" = -v5 ]; then # latest version
    shift
elif [[ "$1" =~ -v[0-9]+ ]]; then
    if [ "$1" = "-v1" ]; then
        VERSION=-v3
    elif [ "$1" = "-v2" ]; then
        VERSION=-v3
    else
        VERSION=$1
        shift
    fi
fi

if [ -n "$VERSION" ]; then
    # degrade
    INSTALL_FLAG=
    if [ "$1" == "--install" ]; then
        INSTALL_FLAG=1
        shift
    fi

    if [ -n "$INSTALL_FLAG" ]; then
        if [ ! -e $HOME/.xsvutils/repos-build/var/xsvutils$VERSION ]; then
            bash $TOOL_DIR/install.sh $VERSION >&2 || exit $?
        fi
        exit 0
    fi

    #if [ -e $TOOL_DIR/xsvutils$VERSION ]; then
    #    $TOOL_DIR/xsvutils$VERSION "$@"
    #    exit $?
    #fi
    # $TOOL_DIR/xsvutils$VERSION にバイナリを置く仕組みはまだない

    if [ ! -e $HOME/.xsvutils/repos-build/var/xsvutils$VERSION ]; then
        echo "Not found: $HOME/.xsvutils/repos-build/var/xsvutils$VERSION" >&2
        echo "To install it, \`xsvutils $VERSION --install\`" >&2
        exit 1
    fi

    $HOME/.xsvutils/repos-build/var/xsvutils$VERSION "$@"
    exit $?
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
    perl $TOOL_DIR/main-v1.pl "$@"
elif [ "$1" = "-v2" ]; then
    shift
    perl $TOOL_DIR/main.pl "$@"
else
    perl $TOOL_DIR/main.pl "$@"
fi

exit $?

#SOURCE_IMAGE
