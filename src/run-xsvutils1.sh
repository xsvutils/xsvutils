
if [ -x $XSVUTILS_HOME/var/xsvutils1/xsvutils ]; then
    exec $XSVUTILS_HOME/var/xsvutils1/xsvutils "$@"
else
    echo "xsvutils1 not installed." >&2
    echo "See \`xsvutils help install\`" >&2
    exit 1
fi

