
./xsvutils -v2 ./test/data/sample-3.tsv --header col1,col2 facetcount                 > ./var/test/case-facetcount-1.tsv
./xsvutils -v2 ./test/data/sample-3.tsv --header col1,col2 facetcount --multi-value-a > ./var/test/case-facetcount-2.tsv

./xsvutils -v2 ./test/data/sample-facetcount.tsv facetcount          > ./var/test/case-facetcount-3.tsv
./xsvutils -v2 ./test/data/sample-facetcount.tsv facetcount --weight > ./var/test/case-facetcount-4.tsv

