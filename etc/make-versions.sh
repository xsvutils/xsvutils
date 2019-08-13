
export BUILD_DIR=$(pwd)/var/repos-build

install() {
    version=$1
    bash src/install.sh $version || exit $?
    cp -v $BUILD_DIR/var/xsvutils$version $(pwd)/target/xsvutils$version || exit $?
}

install -v3
install -v4
install -v5
install -v6
install -v7
install -v8
install -v9
install -v10
install -v11
install -v12
install -v13

touch var/repos-build.touch

