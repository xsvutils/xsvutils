
if [ -x $XSVUTILS_HOME/lib/xsvutils-rs ]; then
    exec $XSVUTILS_HOME/lib/xsvutils-rs "$@"
else
    echo "Features written by Rust not built." >&2
    echo "See \`xsvutils help install\`" >&2
    exit 1
fi

