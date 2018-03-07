
src=$1

sed -e '/HELP_CMD_INDEX/,$d' < $src

cat var/help-cmd-list.txt | sed 's/^/        /'

sed -n -e '/HELP_CMD_INDEX/,$p' < $src | tail -n+2

