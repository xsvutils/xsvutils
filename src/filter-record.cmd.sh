
record=

while [ $# -gt 0 ]; do
    a=$1
    shift
    if [ "$a" = "--record" ]; then
        record=$1
        shift
    else
        echo "Unknown parameter: $a" >&2
        exit 1
    fi
done

exec perl $XSVUTILS_HOME/src/filter-record.pl "$record"

