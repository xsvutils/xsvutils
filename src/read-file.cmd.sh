
filepath=

while [ $# -gt 0 ]; do
    a=$1
    shift
    if [ "$a" = "-i" ]; then
        filepath=$1
        shift
    else
        echo "Unknown parameter: $a" >&2
        exit 1
    fi
done

if [ -z "$filepath" ]; then
    echo "Error" >&2
    exit 1
else
    exec cat "$filepath"
fi


