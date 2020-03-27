
header=
record=

while [ $# -gt 0 ]; do
    a=$1
    shift
    if [ "$a" = "--header" ]; then
        header=$1
        shift
    elif [ "$a" = "--record" ]; then
        record=$1
        shift
    else
        echo "Unknown parameter: $a" >&2
        exit 1
    fi
done

exec perl $XSVUTILS_HOME/src/modify-record.pl "$header" "$record"

