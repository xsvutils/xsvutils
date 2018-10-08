
# varの中にgolangをインストールするスクリプト。
# ホストのグローバル環境やユーザ環境には影響を与えません。 var の中で完結しています。

VERSION=1.9.2

(
    cd var

    fname=golang-$VERSION.linux-amd64

    if [ ! -e $fname ]; then
        if [ ! -e $fname.tar.gz ]; then
            url=https://storage.googleapis.com/golang/go$VERSION.linux-amd64.tar.gz
            echo curl -L $url \> $fname.tar.gz
            curl -L $url > $fname.tar.gz.tmp || exit $?
            mv $fname.tar.gz.tmp $fname.tar.gz
        fi

        if [ -e go ]; then
            echo "directory `var/go` exists" >&2
            exit 1
        fi
        echo tar xzf $fname.tar.gz
        tar xzf $fname.tar.gz || exit $?
        mv go $fname || exit $?
    fi

    if [ -e golang ]; then
        rm golang
    fi
    ln -s $fname golang || exit $?
) || exit $?

export PATH=$(pwd)/var/golang_packages/bin:$(pwd)/var/golang/bin:$PATH
export GOROOT=$(pwd)/var/golang
export GOPATH=$(pwd)/var/golang_packages

mkdir -pv $GOPATH

if [ ! -e var/golang_packages/bin/dep ]; then
    go get -u github.com/golang/dep/cmd/dep || exit $?
fi

