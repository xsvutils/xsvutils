
filepath=

while [ $# -gt 0 ]; do
    a=$1
    shift
    if [ "$a" = "-o" ]; then
        filepath=$1
        shift
    elif [ "$a" = "--stdout" ]; then
        filepath=
    else
        echo "Unknown parameter: $a" >&2
        exit 1
    fi
done

if [ -z "$filepath" ]; then
    exec cat
else
    exec cat > "$filepath"
fi


