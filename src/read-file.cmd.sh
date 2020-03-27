
filepath=

while [ $# -gt 0 ]; do
    a=$1
    shift
    if [ "$a" = "-i" ]; then
        filepath=$1
        shift
    elif [ "$a" = "--stdin" ]; then
        filepath=
    else
        echo "Unknown parameter: $a" >&2
        exit 1
    fi
done

if [ -z "$filepath" ]; then
    exec perl $XSVUTILS_HOME/src/format-wrapper.pl --pipe
else
    exec perl $XSVUTILS_HOME/src/format-wrapper.pl -i "$filepath" --pipe
fi


