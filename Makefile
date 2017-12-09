
build: xsvutils

xsvutils: src/boot.sh var/VERSION_HASH
	cat src/boot.sh | sed "s/XXXX_VERSION_HASH_XXXX/$$(cat var/VERSION_HASH.txt)/g" > var/xsvutils
	(cd target; tar cz *) >> var/xsvutils
	chmod 755 var/xsvutils
	mv var/xsvutils xsvutils

var/VERSION_HASH: target/main.pl target/help.txt target/format-wrapper.sh target/guess-format.pl target/convert-output.pl target/golang.bin target/dummy.sh
	cat $$(find target -type f | LC_ALL=C sort) | shasum | cut -b1-40 > var/VERSION_HASH.txt.tmp
	mv var/VERSION_HASH.txt.tmp var/VERSION_HASH.txt

target/main.pl: src/main.pl
	cp src/main.pl target/main.pl

target/help.txt: src/help.txt
	cp src/help.txt target/help.txt

target/format-wrapper.sh: src/format-wrapper.sh
	cp src/format-wrapper.sh target/format-wrapper.sh

target/guess-format.pl: src/guess-format.pl
	cp src/guess-format.pl target/guess-format.pl

target/convert-output.pl: src/convert-output.pl
	cp src/convert-output.pl target/convert-output.pl

target/dummy.sh: src/dummy.sh
	cp src/dummy.sh target/dummy.sh

target/golang.bin: gobuild
	cp golang/golang target/golang.bin
	chmod 777 target/golang.bin

var/GOLANG_VERSION_HASH:
	cat $$(find golang -type f -name "*.go" | LC_ALL=C sort) | shasum | cut -b1-40 > var/GOLANG_VERSION_HASH.txt.tmp
	mv var/GOLANG_VERSION_HASH.txt.tmp var/GOLANG_VERSION_HASH-source.txt

gobuild: var/GOLANG_VERSION_HASH
	if ! diff var/GOLANG_VERSION_HASH-source.txt var/GOLANG_VERSION_HASH-build.txt >/dev/null; then cd golang; go vet ./...; go get -u github.com/spf13/cobra; go run ./generator/generator.go && go build; fi
	cp var/GOLANG_VERSION_HASH-source.txt var/GOLANG_VERSION_HASH-build.txt


