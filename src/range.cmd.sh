
start=
end=

while [ $# -gt 0 ]; do
    a=$1
    shift
    if [ "$a" = "--start" ]; then
        start=$1
        shift
    elif [ "$a" = "--end" ]; then
        end=$1
        shift
    else
        echo "Unknown parameter: $a" >&2
        exit 1
    fi
done

if [ -z "$start" -o -z "$end" ]; then
    echo "Error" >&2
    exit 1
fi

start=$((start + 2))
end=$((end + 1))

if [ $end = 0 ]; then
    end='$'
fi

if [ $start = 2 ]; then
    if [ $end = '$' ]; then
        exec cat
    else
        exec head -n $end
    fi
else
    exec sed -n -e 1p -e "${start},${end}p"
fi

