
mkdir -p var/test

bash ./test/case-01.sh
bash ./test/case-02.sh

diff -ru ./test/expected ./var/test && echo OK

