#!/bin/bash

# gitのtagをバージョン番号として表示する
# gitレポジトリでない場合でも var/version.txt が用意されていればそれを表示する

cd $XSVUTILS_HOME

if [ -d .git ] && type git >/dev/null 2>&1; then
    git log --pretty=format:"%D" | perl -ne '
        BEGIN {
            $f = "";
        }
        if ($_ =~ /(?:^|\s)tag:\s*([^,]+?)(?:[,\s]|$)/) {
            if ($f) {
                print "xsvutils version " . $1 . "+\n";
            } else {
                print "xsvutils version " . $1 . "\n";
            }
            exit(0);
        }
        $f = 1;
    '
elif [ -e var/version.txt ]; then
    cat var/version.txt
else
    echo "version info not found." >&2
    exit 1
fi

