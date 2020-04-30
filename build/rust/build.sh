
set -Ceu

export XSVUTILS_HOME=$(cd $(dirname $0)/../..; pwd)

cd $XSVUTILS_HOME

mkdir -p var/rust

for f in $(ls src/*.rs | LC_ALL=C sort); do
    echo $f
    cat $f
done | shasum | cut -b1-40 >| var/rust/hash.txt.tmp

cargo_target=x86_64-unknown-linux-musl

if [ -e var/rust/hash.txt ] && cmp -s var/rust/hash.txt var/rust/hash.txt.tmp && [ -e var/rust/target/$cargo_target/release/xsvutils-rs ]; then
    rm var/rust/hash.txt.tmp
    exit
fi

rustup target add $cargo_target
cargo build --release --manifest-path=build/rust/Cargo.toml --target-dir=var/rust/target --target $cargo_target

cp -p var/rust/target/$cargo_target/release/xsvutils-rs lib/xsvutils-rs

mv var/rust/hash.txt.tmp var/rust/hash.txt

