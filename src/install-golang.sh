
# 特定のディレクトリ($install_base)の中にgolangをインストールするスクリプト。
# ホストのグローバル環境やユーザ環境には影響を与えません。特定のディレクトリ($install_base)の中で完結しています。

install_base=$1

golang_ver=1.9.2

uname=$(uname)

if [ "$uname" = "Darwin" ]; then
    golang_os_name='darwin'
elif [ "$uname" = "Linux" ]; then
    golang_os_name='linux'
else
    echo "Unknown OS: $uname" >&2
    exit 1
fi

(
    mkdir -p $install_base

    cd $install_base

    fname=golang-$golang_ver.$golang_os_name-amd64
    url=https://storage.googleapis.com/golang/go$golang_ver.$golang_os_name-amd64.tar.gz

    if [ ! -e $fname ]; then
        if [ ! -e $fname.tar.gz ]; then
            echo curl -L $url \> $fname.tar.gz
            curl -L $url > $fname.tar.gz.tmp || exit $?
            mv $fname.tar.gz.tmp $fname.tar.gz
        fi

        if [ -e go ]; then
            rm -r go
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

export PATH=$install_base/golang_packages/bin:$install_base/golang/bin:$PATH
export GOROOT=$install_base/golang
export GOPATH=$install_base/golang_packages

mkdir -p $GOPATH

if [ ! -e $install_base/golang_packages/bin/dep ]; then
    go get -u github.com/golang/dep/cmd/dep || exit $?
fi

