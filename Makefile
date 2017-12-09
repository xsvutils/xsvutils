
build: xsvutils

xsvutils: src/boot.sh var/VERSION_HASH target/main.sh target/dummy.sh
	cat src/boot.sh | sed "s/XXXX_VERSION_HASH_XXXX/$$(cat var/VERSION_HASH.txt)/g" > var/xsvutils
	(cd target; tar cz *) >> var/xsvutils
	chmod 755 var/xsvutils
	mv var/xsvutils xsvutils

var/VERSION_HASH:
	cat $$(find src -type f | LC_ALL=C sort) | shasum | cut -b1-40 > var/VERSION_HASH.txt.tmp
	mv var/VERSION_HASH.txt.tmp var/VERSION_HASH.txt

target/main.sh: src/main.sh
	cp src/main.sh target/main.sh

target/dummy.sh: src/dummy.sh
	cp src/dummy.sh target/dummy.sh

gobuild: godeps
	go run ./generator/generator.go && \
	 	go build

godeps:
	go vet ./...
	go get -u github.com/spf13/cobra
	
