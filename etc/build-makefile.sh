#!/bin/bash
uname=$(uname)

if [ "$uname" = "Darwin" ]; then
    platform_name='mac'
elif [ "$uname" = "Linux" ]; then
    platform_name='linux'
else
    echo "Unknown OS: $uname" >&2
    exit 1
fi

TARGET_SOURCES1=$(echo $((
            echo target/xsvutils-go;
            # echo target/xsvutils-ml;
            echo target/xsvutils-rs;
            echo target/java;
            ls src | grep -v -E -e '(boot\.sh)' | grep -v '\.(java|scala)$' | sed 's/^/target\//g';
            ls help | sed 's/^/target\/help-/g';
            echo target/help-guide-version.txt;
            echo target/help-guide-changelog.txt) | LC_ALL=C sort))
TARGET_SOURCES2=$(echo $((
            echo target/xsvutils-go;
            # echo target/xsvutils-ml;
            echo target/xsvutils-rs;
            echo target/java/bin/xsvutils-java;
            ls src | grep -v -E -e '(boot\.sh)' | grep -v '\.(java|scala)$' | sed 's/^/target\//g';
            ls help | sed 's/^/target\/help-/g';
            echo target/help-guide-version.txt;
            echo target/help-guide-changelog.txt) | LC_ALL=C sort))

RM_TARGET=$(diff -u <(ls -d $TARGET_SOURCES1 2>/dev/null) <(ls -d target/* 2>/dev/null) | grep -E '^\+target' | cut -b2-)
if [ -n "$RM_TARGET" ]; then
    echo rm -r $RM_TARGET >&2
    rm -r $RM_TARGET >&2
fi

bash src/install-openjdk.sh $HOME/.xsvutils/var >&2 || exit $?

gopath_rel=var/golang_packages
GOPATH=$PWD/$gopath_rel
JAVA_HOME=$HOME/.xsvutils/var/openjdk

cat <<EOF
export GOPATH=$GOPATH
export JAVA_HOME=$JAVA_HOME
export PATH=$HOME/.xsvutils/var/openjdk/bin:$PWD/var/golang_packages/bin:$PATH

GO       := $PWD/etc/anybuild --prefix=$PWD/var/anybuild --go=1.9.2 go
SBT      := $PWD/etc/anybuild --prefix=$PWD/var/anybuild --sbt=1.2.3 sbt
RUSTUP   := $PWD/etc/anybuild --prefix=$PWD/var/anybuild --rust=1.35.0 rustup
CARGO    := $PWD/etc/anybuild --prefix=$PWD/var/anybuild --rust=1.35.0 cargo
OCAMLOPT := $PWD/etc/anybuild --prefix=$PWD/var/anybuild --ocaml=4.07.0 ocamlopt

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
	perl etc/preprocess.pl $platform_name < src/$f > target/$f.tmp
	mv target/$f.tmp target/$f

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

go_target=github.com/suzuki-navi/xsvutils
cat <<EOF
gobuild: target/xsvutils-go

$gopath_rel/bin/dep:
	\$(GO) get -u github.com/golang/dep/cmd/dep

target/xsvutils-go: $gopath_rel/bin/dep var/GOLANG_VERSION_HASH $gopath_rel/src/$go_target/Gopkg.toml $gopath_rel/src/$go_target/Gopkg.lock
	cd $gopath_rel/src/$go_target; dep ensure
	cd $gopath_rel/src/$go_target; \$(GO) vet ./...
	cd $gopath_rel/src/$go_target; \$(GO) build
	cp var/GOLANG_VERSION_HASH var/GOLANG_VERSION_HASH-build
	cp $gopath_rel/src/$go_target/xsvutils target/xsvutils-go

$gopath_rel/src/$go_target/Gopkg.toml: etc/Gopkg.toml
	cp etc/Gopkg.toml $gopath_rel/src/$go_target/Gopkg.toml

$gopath_rel/src/$go_target/Gopkg.lock: etc/Gopkg.lock
	cp etc/Gopkg.lock $gopath_rel/src/$go_target/Gopkg.lock

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
var/sbt/target/universal/xsvutils-java-0.1.0-SNAPSHOT.zip: var/sbt/build.sbt var/sbt/project/plugins.sbt $(echo $(ls src/*.scala | sed 's/^src\///g' | sed 's/^/var\/sbt\/src\/main\/java\//g'))
	cd var/sbt; \$(SBT) compile
	cd var/sbt; \$(SBT) universal:packageBin

var/sbt/build.sbt: etc/build.sbt
	mkdir -p var/sbt
	cp etc/build.sbt var/sbt/build.sbt

var/sbt/project/plugins.sbt: etc/plugins.sbt
	mkdir -p var/sbt/project
	cp etc/plugins.sbt var/sbt/project/plugins.sbt

target/java/bin/xsvutils-java: var/sbt/target/universal/xsvutils-java-0.1.0-SNAPSHOT.zip
	rm -rf var/sbt/target/universal/xsvutils-java-0.1.0-SNAPSHOT 2>/dev/null
	cd var/sbt/target/universal; unzip xsvutils-java-0.1.0-SNAPSHOT.zip
	rm -rf target/java
	mv var/sbt/target/universal/xsvutils-java-0.1.0-SNAPSHOT target/java
	touch target/java/bin/xsvutils-java

EOF

if [ "$uname" = "Linux" ]; then

target=x86_64-unknown-linux-musl
cat <<EOF
target/xsvutils-rs: cargo-build
	cp -p var/rust-target/$target/release/xsvutils-rs target/xsvutils-rs

.PHONY: cargo-build
cargo-build:
	\$(RUSTUP) target add $target
	\$(CARGO) build --release --manifest-path=etc/Cargo.toml --target-dir=var/rust-target --target $target

EOF

else

cat <<EOF
target/xsvutils-rs: cargo-build
	cp -p var/rust-target/release/xsvutils-rs target/xsvutils-rs

.PHONY: cargo-build
cargo-build:
	\$(CARGO) build --release --manifest-path=etc/Cargo.toml --target-dir=var/rust-target

EOF

fi

cat <<'EOF'
ML_SRC = $(wildcard src/*.ml)
ML_TGT = $(patsubst src/%,var/ocaml-target/%,$(ML_SRC))

target/xsvutils-ml: $(ML_TGT)
	$(OCAMLOPT) $(ML_TGT) -o $@

var/ocaml-target/%.ml: src/*.ml
	@mkdir -p var/ocaml-target
	cp $< $@
EOF
