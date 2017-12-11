
# varの中にgolangをインストールするスクリプト。
# ホストのグローバル環境やユーザ環境には影響を与えません。 var の中で完結しています。

VERSION=1.9.2

if [ -e var/golang -a  -e var/golang_packages ]; then
    exit 0
fi

cd var

if [ ! -e go$VERSION.linux-amd64.tar.gz ]; then
    url=https://storage.googleapis.com/golang/go$VERSION.linux-amd64.tar.gz
    echo curl $url \> go$VERSION.linux-amd64.tar.gz
    curl $url > go$VERSION.linux-amd64.tar.gz.tmp || exit $?
    mv go$VERSION.linux-amd64.tar.gz.tmp go$VERSION.linux-amd64.tar.gz
fi
if [ -e go ]; then
    echo "directory `var/go` exists" >&2
    exit 1
fi
if [ ! -e go$VERSION.linux-amd64 ]; then
    echo tar xzf go$VERSION.linux-amd64.tar.gz
    tar xzf go$VERSION.linux-amd64.tar.gz || exit $?
    mv go go$VERSION.linux-amd64 || exit $?
fi
ln -s go$VERSION.linux-amd64 golang || exit $?

mkdir -pv golang_packages

