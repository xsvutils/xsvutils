
version=$1
recursive_flag=$2
if [ "$version" = -v3 ]; then
    # version 0.2.7
    GIT_HASH=f1dfb7755c26eca2a99ad5786eac9c2e5e62caf2
    make_arg=build
#elif [ "$version" = -v4 ]; then
elif [ -n "$recursive_flag" ]; then
    echo "Unknown version: $version" >&2
    exit 1
fi

echo "Install: $version"

if [ -z "$BUILD_DIR" ]; then
    export BUILD_DIR=$HOME/.xsvutils/repos-build
fi

if [ ! -e $BUILD_DIR ]; then
    mkdir -p $BUILD_DIR.tmp 2>/dev/null
    (
        cd $BUILD_DIR.tmp || exit $?
        git clone https://github.com/suzuki-navi/xsvutils.git . || exit $?
    ) || exit $?
    ( mkdir -p $BUILD_DIR && mv $BUILD_DIR.tmp/* $BUILD_DIR.tmp/.git* $BUILD_DIR ) || exit $?
    rm -rvf $BUILD_DIR.tmp
fi

if [ -z "$GIT_HASH" -a -z "$recursive_flag" ]; then
    (
        cd $BUILD_DIR
        git fetch --prune
        git checkout origin/master
        bash src/install.sh $version recursive
    )
    exit $?
fi

if [ ! -e $BUILD_DIR/var/xsvutils$version ]; then
    (
        cd $BUILD_DIR
        git fetch --prune
        git checkout -q $GIT_HASH || exit $?
        make $make_arg || exit $?
        cp xsvutils var/xsvutils$version
    ) || exit $?
fi

