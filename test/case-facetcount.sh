
./xsvutils -v13 ./test/data/sample-3.tsv --header col1,col2 facetcount -v4                 > ./var/test/case-facetcount-1.tsv
./xsvutils -v13 ./test/data/sample-3.tsv --header col1,col2 facetcount -v4 --multi-value-a > ./var/test/case-facetcount-2.tsv

./xsvutils -v13 ./test/data/sample-facetcount.tsv facetcount -v4          > ./var/test/case-facetcount-3.tsv
./xsvutils -v13 ./test/data/sample-facetcount.tsv facetcount -v4 --weight > ./var/test/case-facetcount-4.tsv

