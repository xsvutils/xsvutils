
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
[ -n "$WORKING_DIR" ] || { echo "Cannot create WORKING_DIR: $WORKING_DIR"; exit $?; }

export HARD_WORKING_DIR=$(mktemp -d /tmp/xsvutils-hard-XXXXXXXX)
[ -n "$HARD_WORKING_DIR" ] || { echo "Cannot create HARD_WORKING_DIR: $HARD_WORKING_DIR"; exit $?; }

#if mac
trap "rm -rf $WORKING_DIR $HARD_WORKING_DIR" EXIT
#else
trap "rm -rf $WORKING_DIR $HARD_WORKING_DIR; perl $TOOL_DIR/killchildren.pl $$" EXIT
#endif

tput lines >/dev/null 2>&1 && export TERMINAL_LINES=$(tput lines);
tput cols  >/dev/null 2>&1 && export TERMINAL_COLS=$(tput cols);

perl $TOOL_DIR/main.pl "$@"

exit $?

