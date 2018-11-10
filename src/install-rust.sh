#!/bin/sh

#
# Rustコンパイラのインストールを行います。
#

# 環境変数CARGOに値が設定済されているとき、何もしません。
if [ -n "${CARGO-}" ]; then
    exit
fi

INSATLL_DIR=${1?} # 未定義時エラー
INSATLL_DIR=${INSATLL_DIR%/} # 末尾のスラッシュを取り除く
RUST_VERSION=1.30.1

uname="$(uname)"
triple=""
case "$uname" in
    Darwin )
        triple="x86_64-apple-darwin"
        ;;
    Linux )
        triple="x86_64-unknown-linux-gnu"
        ;;
    * )
        echo "Unknown OS: $uname" >&2
        exit 1
esac

PREFIX="$INSATLL_DIR/rust"
mkdir -p "$PREFIX"
cd "$INSATLL_DIR" || exit 1

if [ ! -x "$PREFIX/bin/cargo" ]; then
    fname="rust-${RUST_VERSION}-${triple}"
    if [ ! -d "$fname" ]; then
        archive="$fname.tar.gz"
        if [ ! -f "$archive" ]; then
            curl -LO "https://static.rust-lang.org/dist/$archive"
        fi
        tar fxz "$archive"
    fi
    bash $fname/install.sh --prefix="$PREFIX"
fi
