
version=$1
recursive_flag=$2
if [ "$version" = -v3 ]; then
    # version 0.2.7
    GIT_HASH=f1dfb7755c26eca2a99ad5786eac9c2e5e62caf2
elif [ "$version" = -v4 ]; then
    # version 0.4
    GIT_HASH=c1607ae08017aeec7983faaa3be8ec71ce3eea77
elif [ "$version" = -v5 ]; then
    # version 0.5
    GIT_HASH=610ca476f94ccfea76f2f0879c63781535c05285
elif [ "$version" = -v6 ]; then
    # version 0.6
    GIT_HASH=5ee4226daac842c4d9d5a364b06128238503c164
elif [ "$version" = -v7 ]; then
    # version 0.7
    GIT_HASH=8456d18517212e7f1e2f19c4bff75b94b18bb134
elif [ "$version" = -v8 ]; then
    # version 0.8
    GIT_HASH=0.8
elif [ "$version" = -v9 ]; then
    # version 0.9
    GIT_HASH=0.9
elif [ "$version" = -v10 ]; then
    # version 0.10
    GIT_HASH=0.10
elif [ "$version" = -v11 ]; then
    # version 0.11
    GIT_HASH=0.11
elif [ "$version" = -v12 ]; then
    # version 0.12
    GIT_HASH=0.12
elif [ -n "$recursive_flag" ]; then
    echo "Unknown version: $version" >&2
    exit 1
fi

echo "Install: $version"

if [ -z "$BUILD_DIR" ]; then
    export BUILD_DIR=$HOME/.xsvutils/repos-build
fi

if [ -e $BUILD_DIR ]; then
    (
        # change url for the git remote repository
        cd $BUILD_DIR || exit $?
        git remote set-url origin https://github.com/xsvutils/xsvutils.git
    ) || exit $?
else
    mkdir -p $BUILD_DIR.tmp 2>/dev/null
    (
        cd $BUILD_DIR.tmp || exit $?
        git clone https://github.com/xsvutils/xsvutils.git . || exit $?
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
        git checkout -f -q $GIT_HASH || exit $?

        make var/makefile || exit $?

        # ダウンロードURLが変わってしまったためにパッチ
        cat var/makefile | sed 's#https://cocl.us/sbt-0.13.16.tgz#https://piccolo.link/sbt-0.13.16.tgz#g' > var/makefile.2
        make -f var/makefile.2 build || exit $?

        cp xsvutils var/xsvutils$version
    ) || exit $?
fi

