
./xsvutils -v2 ./test/data/sample-datetime.tsv inshour datetime date > ./var/test/case-datetime-inshour.tsv
./xsvutils -v2 ./test/data/sample-datetime.tsv insdate datetime date > ./var/test/case-datetime-insdate.tsv
./xsvutils ./test/data/sample-datetime.tsv insweek datetime monday date > ./var/test/case-datetime-week-1.tsv
./xsvutils -v2 ./test/data/sample-datetime.tsv inssecinterval datetime delta > ./var/test/case-datetime-inssecinterval.tsv

