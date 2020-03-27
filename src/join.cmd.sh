
other=
action="--inner"
option=

while [ $# -gt 0 ]; do
    a=$1
    shift
    if [ "$a" = "--other" ]; then
        other=$1
        shift
    elif [ "$a" = "--inner" ]; then
        action="--inner"
    elif [ "$a" = "--left-outer" ]; then
        action="--left-outer"
    elif [ "$a" = "--right-outer" ]; then
        action="--right-outer"
    elif [ "$a" = "--full-outer" ]; then
        action="--full-outer"
    elif [ "$a" = "--number" ]; then
        option="$option --number"
    else
        echo "Unknown parameter: $a" >&2
        exit 1
    fi
done

if [ -z "${other:-}" ]; then
    if [ $action = "--left-outer" -o $action = "--full-outer" ]; then
        exec cat
    else
        head -n 1
        exit
    fi
fi

exec perl $XSVUTILS_HOME/src/join.pl $action --other $other $option

