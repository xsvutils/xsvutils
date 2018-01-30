
mkdir -p var/test

./xsvutils ./test/data/sample2.tsv uriparams --col querystring --names q,r          > ./var/test/test-01-1.tsv
./xsvutils ./test/data/sample2.tsv uriparams --col querystring --names q,r --form-b > ./var/test/test-01-2.tsv

