
if [ -x $XSVUTILS_HOME/lib/xsvutils-rs ]; then
    exec $XSVUTILS_HOME/lib/xsvutils-rs "$@"
else
    echo "Rust not installed." >&2
    echo "Install Rust and run as follows:" >&2
    echo "\$ cd $XSVUTILS_HOME" >&2
    echo "\$ bash build/rust/build.sh" >&2
    exit 1
fi

