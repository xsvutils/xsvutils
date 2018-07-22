
./xsvutils ./test/data/sample-querystring.tsv uriparams --col querystring --names q,r                 > ./var/test/case-uriparams-1.tsv
./xsvutils ./test/data/sample-querystring.tsv uriparams --col querystring --names q,r --multi-value-b > ./var/test/case-uriparams-2.tsv
./xsvutils ./test/data/sample-querystring.tsv uriparams --col querystring --name-list                 > ./var/test/case-uriparams-3.tsv
./xsvutils ./test/data/sample-querystring.tsv uriparams --col querystring --name-list --multi-value-b > ./var/test/case-uriparams-4.tsv

