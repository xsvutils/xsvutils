
./xsvutils -v2 ./test/data/sample-join-1.tsv paste --file ./test/data/sample-join-2.tsv              > ./var/test/case-join-paste.tsv
./xsvutils ./test/data/sample-join-1.tsv join  --right ./test/data/sample-join-2.tsv              > ./var/test/case-join-inner.tsv
./xsvutils ./test/data/sample-join-1.tsv join  --right ./test/data/sample-join-2.tsv --left-outer > ./var/test/case-join-left-outer.tsv
./xsvutils ./test/data/sample-join-1.tsv join  --right ./test/data/sample-join-2.tsv --right-outer > ./var/test/case-join-right-outer.tsv
./xsvutils ./test/data/sample-join-1.tsv join  --right ./test/data/sample-join-2.tsv --full-outer > ./var/test/case-join-full-outer.tsv

./xsvutils ./test/data/zero.tsv join  --right ./test/data/sample-join-2.tsv --right-outer > ./var/test/case-join-zero.tsv

