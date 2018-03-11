
./xsvutils -v2 ./test/data/prefecture.tsv head          > ./var/test/range-1.tsv
./xsvutils -v2 ./test/data/prefecture.tsv head 5        > ./var/test/range-2.tsv
./xsvutils -v2 ./test/data/prefecture.tsv offset 5      > ./var/test/range-3.tsv
./xsvutils -v2 ./test/data/prefecture.tsv offset 5 head > ./var/test/range-4.tsv


