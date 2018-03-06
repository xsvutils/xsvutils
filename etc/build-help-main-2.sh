
src=$1

sed -e '/HELP_GUIDE_INDEX/,$d' < $src

cat var/help-guide-list.txt | sed 's/^/        /'

sed -n -e '/HELP_GUIDE_INDEX/,$p' < $src | tail -n+2

