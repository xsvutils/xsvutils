
option_n=10
while [ "$#" != 0 ]; do
    if [ "$1" = "-n" ]; then
        shift
        option_n=$1
    fi
    shift
done

head_option="-n $(( $option_n + 1 ))"

head $head_option

