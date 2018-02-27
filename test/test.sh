
if [ -e var/test ]; then
    rm -r var/test
fi
mkdir -p var/test

bash ./test/case-uriparams.sh
bash ./test/case-bom.sh
bash ./test/case-facetcount.sh
bash ./test/case-treetable.sh
bash ./test/case-crosstable.sh
bash ./test/case-wordsflags.sh
bash ./test/case-addmap.sh
bash ./test/case-join.sh
bash ./test/case-datetime.sh
bash ./test/case-number.sh

diff -ru ./test/expected ./var/test && echo OK

