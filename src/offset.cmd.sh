
linenum=

while [ $# -gt 0 ]; do
    a=$1
    shift
    if [ "$a" = "-n" ]; then
        linenum=$1
        shift
    else
        echo "Unknown parameter: $a" >&2
        exit 1
    fi
done

linenum=${linenum:-10}
linenum=$((linenum + 2))

exec sed -n -e 1p -e $linenum,\$p

