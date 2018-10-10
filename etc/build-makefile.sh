

TARGET_SOURCES1=$(echo $((
            echo target/golang.bin;
            echo target/java;
            ls src | grep -v -E -e '(boot\.sh)' | grep -v '\.(java|scala)$' | sed 's/^/target\//g'; ls help | sed 's/^/target\/help-/g';
            echo target/help-guide-version.txt;
            echo target/help-guide-changelog.txt) | LC_ALL=C sort))
TARGET_SOURCES2=$(echo $((
            echo target/golang.bin;
            echo target/java/bin/xsvutils-java;
            ls src | grep -v -E -e '(boot\.sh)' | grep -v '\.(java|scala)$' | sed 's/^/target\//g'; ls help | sed 's/^/target\/help-/g';
            echo target/help-guide-version.txt;
            echo target/help-guide-changelog.txt) | LC_ALL=C sort))

RM_TARGET=$(diff -u <(ls -d $TARGET_SOURCES1 2>/dev/null) <(ls -d target/* 2>/dev/null) | grep -E '^\+target' | cut -b2-)
if [ -n "$RM_TARGET" ]; then
    echo rm -r $RM_TARGET >&2
    rm -r $RM_TARGET >&2
fi

bash etc/install-golang.sh >&2 || exit $?
cat <<EOF
export PATH=$(pwd)/var/golang_packages/bin:$(pwd)/var/golang/bin:$PATH
export GOROOT=$(pwd)/var/golang
export GOPATH=$(pwd)/var/golang_packages

EOF

cat <<\EOF
build: xsvutils

target: var/TARGET_VERSION_HASH

EOF

cat <<\EOF
xsvutils: src/boot.sh var/TARGET_VERSION_HASH
	cat src/boot.sh | sed "s/XXXX_VERSION_HASH_XXXX/$$(cat var/TARGET_VERSION_HASH)/g" > var/xsvutils
	(cd target; tar cz *) >> var/xsvutils
	chmod 755 var/xsvutils
	mv var/xsvutils xsvutils

EOF

cat <<EOF
var/TARGET_VERSION_HASH: $TARGET_SOURCES2
	(find $TARGET_SOURCES1 -type f; cat \$\$(find $TARGET_SOURCES1 -type f)) | shasum | cut -b1-40 > var/TARGET_VERSION_HASH.tmp
	mv var/TARGET_VERSION_HASH.tmp var/TARGET_VERSION_HASH

EOF

for f in $(ls src | grep -v -E -e '(boot\.sh)'); do
cat <<EOF
target/$f: src/$f
	cp src/$f target/$f

EOF
done

cat <<EOF
target/help-guide-version.txt: version.txt
	cp version.txt target/help-guide-version.txt

target/help-guide-changelog.txt: CHANGELOG.md
	cp CHANGELOG.md target/help-guide-changelog.txt

EOF

(
    ls help/cmd-*.txt | sed -E 's/^help\/cmd-([^.]+)\.txt$/\1/g'
) | sort | column -c 80 > var/help-cmd-list.txt.tmp
if [ ! -e var/help-cmd-list.txt ] || ! diff -q var/help-cmd-list.txt var/help-cmd-list.txt.tmp >/dev/null; then
    mv var/help-cmd-list.txt.tmp var/help-cmd-list.txt
fi

(
    ls help/guide-*.txt | sed -E 's/^help\/guide-([^.]+)\.txt$/\1/g'
    echo version
    echo changelog
) | sort | column -c 80 > var/help-guide-list.txt.tmp
if [ ! -e var/help-guide-list.txt ] || ! diff -q var/help-guide-list.txt var/help-guide-list.txt.tmp >/dev/null; then
    mv var/help-guide-list.txt.tmp var/help-guide-list.txt
fi

cat <<EOF
target/help-main.txt: etc/build-help-main-1.sh etc/build-help-main-2.sh help/main.txt var/help-cmd-list.txt var/help-guide-list.txt
	bash etc/build-help-main-1.sh help/main.txt > var/help-main.txt.tmp.1
	bash etc/build-help-main-2.sh var/help-main.txt.tmp.1 > var/help-main.txt.tmp.2
	cp var/help-main.txt.tmp.2 target/help-main.txt

target/help-notfound.txt: etc/build-help-main-1.sh etc/build-help-main-2.sh help/notfound.txt var/help-cmd-list.txt var/help-guide-list.txt
	bash etc/build-help-main-1.sh help/notfound.txt > var/help-notfound.txt.tmp.1
	bash etc/build-help-main-2.sh var/help-notfound.txt.tmp.1 > var/help-notfound.txt.tmp.2
	cp var/help-notfound.txt.tmp.2 target/help-notfound.txt

EOF

for f in $(ls help | grep -v -E -e '(main|notfound)\.txt'); do
cat <<EOF
target/help-$f: help/$f
	cp help/$f target/help-$f

EOF
done

perl etc/build-makefile-golang.pl $(find src -name '*.go')

cat <<EOF
gobuild: target/golang.bin

target/golang.bin: var/GOLANG_VERSION_HASH var/golang_packages/src/github.com/suzuki-navi/xsvutils/Gopkg.toml var/golang_packages/src/github.com/suzuki-navi/xsvutils/Gopkg.lock
	cd var/golang_packages/src/github.com/suzuki-navi/xsvutils; dep ensure
	cd var/golang_packages/src/github.com/suzuki-navi/xsvutils; go vet ./...
	cd var/golang_packages/src/github.com/suzuki-navi/xsvutils; go build
	cp var/GOLANG_VERSION_HASH var/GOLANG_VERSION_HASH-build
	cp var/golang_packages/src/github.com/suzuki-navi/xsvutils/xsvutils var/golang.bin
	chmod 777 var/golang.bin
	mv var/golang.bin target/golang.bin

var/golang_packages/src/github.com/suzuki-navi/xsvutils/Gopkg.toml: etc/Gopkg.toml
	cp etc/Gopkg.toml var/golang_packages/src/github.com/suzuki-navi/xsvutils/Gopkg.toml

var/golang_packages/src/github.com/suzuki-navi/xsvutils/Gopkg.lock: etc/Gopkg.lock
	cp etc/Gopkg.lock var/golang_packages/src/github.com/suzuki-navi/xsvutils/Gopkg.lock

EOF

JAVA_RM_TARGET=$(diff -u <(ls src/*.scala 2>/dev/null | sed 's/^src\///g') <(ls var/sbt/src/main/java 2>/dev/null) | tail -n+4 | grep -E '^\+' | cut -b2- | sed 's/^/var\/sbt\/src\/main\/java\//g')
if [ -n "$JAVA_RM_TARGET" ]; then
    echo rm -r $JAVA_RM_TARGET >&2
    rm -r $JAVA_RM_TARGET >&2
fi

for f in $(ls src/*.scala | sed 's/^src\///g'); do
    cat <<EOF
var/sbt/src/main/java/$f: src/$f
	mkdir -p var/sbt/src/main/java
	cp src/$f var/sbt/src/main/java/$f

EOF
done

cat <<EOF
var/sbt/target/universal/xsvutils-java-0.1-SNAPSHOT.zip: var/sbt/sbt/bin/sbt var/sbt/build.sbt var/sbt/project/plugins.sbt $(echo $(ls src/*.scala | sed 's/^src\///g' | sed 's/^/var\/sbt\/src\/main\/java\//g'))
	cd var/sbt; ./sbt/bin/sbt compile
	cd var/sbt; ./sbt/bin/sbt universal:packageBin

EOF

cat <<EOF
var/sbt/sbt.tgz:
	mkdir -p var/sbt
	#wget "https://github.com/sbt/sbt/releases/download/v1.1.4/sbt-1.1.4.tgz" -O var/sbt/sbt.tgz.tmp
	wget "https://cocl.us/sbt-0.13.16.tgz" -O var/sbt/sbt.tgz.tmp
	mv var/sbt/sbt.tgz.tmp var/sbt/sbt.tgz

var/sbt/sbt/bin/sbt: var/sbt/sbt.tgz
	cd var/sbt; tar xzf sbt.tgz
	touch var/sbt/sbt/bin/sbt

var/sbt/build.sbt: etc/build.sbt
	mkdir -p var/sbt
	cp etc/build.sbt var/sbt/build.sbt

var/sbt/project/plugins.sbt: etc/plugins.sbt
	mkdir -p var/sbt/project
	cp etc/plugins.sbt var/sbt/project/plugins.sbt

target/java/bin/xsvutils-java: var/sbt/target/universal/xsvutils-java-0.1-SNAPSHOT.zip
	rm -rf var/sbt/target/universal/xsvutils-java-0.1-SNAPSHOT 2>/dev/null
	cd var/sbt/target/universal; unzip xsvutils-java-0.1-SNAPSHOT.zip
	rm -rf target/java
	mv var/sbt/target/universal/xsvutils-java-0.1-SNAPSHOT target/java
	touch target/java/bin/xsvutils-java

EOF

