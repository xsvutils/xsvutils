
./xsvutils     ./test/data/sample-datetime.tsv inshour datetime date > ./var/test/case-datetime-inshour.tsv
./xsvutils     ./test/data/sample-datetime.tsv insdate datetime date > ./var/test/case-datetime-insdate.tsv
./xsvutils -v1 ./test/data/sample-datetime.tsv insweek datetime monday date > ./var/test/case-datetime-week-1.tsv
./xsvutils     ./test/data/sample-datetime.tsv insunixtime -v4 --local datetime unixtime > ./var/test/case-datetime-insunixtime-local.tsv
./xsvutils     ./test/data/sample-datetime.tsv inssecinterval datetime delta > ./var/test/case-datetime-inssecinterval.tsv

