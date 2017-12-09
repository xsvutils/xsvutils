
build: xsvutils

xsvutils: src/boot.sh var/VERSION_HASH target/main.pl target/help.txt target/dummy.sh
	cat src/boot.sh | sed "s/XXXX_VERSION_HASH_XXXX/$$(cat var/VERSION_HASH.txt)/g" > var/xsvutils
	(cd target; tar cz *) >> var/xsvutils
	chmod 755 var/xsvutils
	mv var/xsvutils xsvutils

var/VERSION_HASH:
	cat $$(find src -type f | LC_ALL=C sort) | shasum | cut -b1-40 > var/VERSION_HASH.txt.tmp
	mv var/VERSION_HASH.txt.tmp var/VERSION_HASH.txt

target/main.pl: src/main.pl
	cp src/main.pl target/main.pl

target/help.txt: src/help.txt
	cp src/help.txt target/help.txt

target/dummy.sh: src/dummy.sh
	cp src/dummy.sh target/dummy.sh

gobuild: godeps
	cd golang; go run ./generator/generator.go && go build

godeps:
	go vet ./golang/...
	go get -u github.com/spf13/cobra

