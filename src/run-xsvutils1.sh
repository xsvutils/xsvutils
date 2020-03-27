
if [ -x $XSVUTILS_HOME/var/xsvutils1/xsvutils ]; then
    exec $XSVUTILS_HOME/var/xsvutils1/xsvutils "$@"
else
    echo "xsvutils1 not installed." >&2
    echo "Run as follows:" >&2
    echo "\$ cd $XSVUTILS_HOME" >&2
    echo "\$ bash build/xsvutils1/build.sh" >&2
    exit 1
fi

