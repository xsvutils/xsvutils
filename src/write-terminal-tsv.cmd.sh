
record_number_start=1

while [ $# -gt 0 ]; do
    a=$1
    shift
    if [ "$a" = "--record-number-start" ]; then
        record_number_start=$1
        shift
    else
        echo "Unknown parameter: $a" >&2
        exit 1
    fi
done


exec perl $XSVUTILS_HOME/src/table.pl --col-number --record-number --record-number-start $record_number_start --color | less -iSRX

