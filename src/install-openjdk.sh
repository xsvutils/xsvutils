
# 特定のディレクトリ($install_base)の中にopenjdkをインストールするスクリプト。
# ホストのグローバル環境やユーザ環境には影響を与えません。特定のディレクトリ($install_base)の中で完結しています。

install_base=$1

openjdk_ver=11

uname=$(uname)

if [ "$uname" = "Darwin" ]; then
    openjdk_os_name='osx'
elif [ "$uname" = "Linux" ]; then
    openjdk_os_name='linux'
else
    echo "Unknown OS: $uname" >&2
    exit 1
fi

(
    mkdir -p $install_base

    cd $install_base

    fname=openjdk-$openjdk_ver
    url=https://download.java.net/java/ga/jdk${openjdk_ver}/openjdk-${openjdk_ver}_${openjdk_os_name}-x64_bin.tar.gz

    if [ ! -e $fname ]; then
        if [ ! -e $fname.tar.gz ]; then
            echo curl -L $url \> $fname.tar.gz
            curl -L $url > $fname.tar.gz.tmp || exit $?
            mv $fname.tar.gz.tmp $fname.tar.gz
        fi

        if [ -e jdk-$openjdk_ver ]; then
            rm -r jdk-$openjdk_ver
        fi
        echo tar xzf $fname.tar.gz
        tar xzf $fname.tar.gz || exit $?
        mv jdk-$openjdk_ver $fname || exit $?
    fi

    if [ -e openjdk ]; then
        rm openjdk
    fi
    ln -s $fname openjdk || exit $?
) || exit $?

