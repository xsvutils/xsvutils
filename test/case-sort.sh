
./xsvutils ./test/data/sort.tsv cut name,num sort > ./var/test/sort-1.tsv
./xsvutils ./test/data/sort.tsv sort name         > ./var/test/sort-2.tsv
./xsvutils ./test/data/sort.tsv sort num          > ./var/test/sort-3.tsv
./xsvutils ./test/data/sort.tsv sort num:n        > ./var/test/sort-4.tsv
./xsvutils ./test/data/sort.tsv sort num:nr       > ./var/test/sort-5.tsv

