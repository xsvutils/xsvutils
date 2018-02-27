
sed -e '/HELP_INDEX/,$d' < help/main.txt

cat var/help-list.txt | sed 's/^/        /'

sed -n -e '/HELP_INDEX/,$p' < help/main.txt | tail -n+2

