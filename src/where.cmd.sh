
col=
op=
val=

while [ $# -gt 0 ]; do
    a=$1
    shift
    if [ "$a" = "--col" ]; then
        col=$1
        shift
    elif [ "$a" = "--op" ]; then
        op=$1
        shift
    elif [ "$a" = "--val" ]; then
        val=$1
        shift
    else
        echo "Unknown parameter: $a" >&2
        exit 1
    fi
done

exec perl $XSVUTILS_HOME/src/where.pl "$col" "$op" "$val"

