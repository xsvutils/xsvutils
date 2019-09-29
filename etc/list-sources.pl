
# main.pl からScalaによるパーサに置き換えると同時に
# ビルドの仕組みを etc/build-makefile.sh から mulang に置き換える予定だが、
# 置き換えで共存している間は src の中に
# etc/build-makefile.sh の対象となるファイルと mulang の対象となるファイルが
# 混在することになってしまう。
# list-sources.pl は src の中のどのファイルが etc/build-makefile.sh の対象で、
# どのファイルが mulang の対象なのかを区別するために
# ファイル名をリストアップするものである。

use strict;
use warnings;
use utf8;

my $action = $ARGV[0];

# etc/build-makefile.sh と mulang の両方の対象となるソースファイル一覧
my @both_build_targets=qw/
    /;

# etc/build-makefile.sh の対象となるソースファイル一覧 (@both_build_targets を含む)
my @legacy_build_targets=qw/
    addconst.pl
    addcopy.rs
    addcross.pl
    add-header.sh
    addlinenum.pl
    addmap.pl
    addnumsortable.pl
    assemblematrix.pl
    boot-second.sh
    boot.sh
    buffer.go
    command-executor.scala
    command.rs
    convert-output.pl
    countcols.pl
    crosstable.pl
    csv2tsv.go
    cutidx.pl
    cut.pl
    cut.rs
    expandmultivalue.pl
    facetcount.pl
    facetcount.scala
    file-range.scala
    filter.scala
    fldsort.go
    format-wrapper.pl
    from_csv.rs
    go-main.go
    groupsum.pl
    header.pl
    insdate.pl
    inssecinterval.pl
    install-openjdk.sh
    install.sh
    insweek.pl
    join.pl
    killchildren.pl
    ltsv2tsv.pl
    main.ml
    main.pl
    main.rs
    mergecols.pl
    paste.pl
    process-builder.pl
    ratio.pl
    rmnoname.pl
    root.go
    stridx.scala
    subcmd_mcut.pm
    summary.pl
    table.pl
    to-chart.pl
    to-chart2.pl
    to-csv.pl
    to-diffable.pl
    treetable.pl
    union.pl
    update.pl
    uriparams2tsv.go
    uriparams.rs
    util.rs
    wcl.go
    where.pl
    wordsflags.pl
    /;

if ($action eq "legacy") {
    foreach my $f (@legacy_build_targets) {
        print "$f\n";
    }
}
if ($action eq "mulang") {
    my $files = `ls src`;
    my @lines = split(/\n/, $files);
    foreach my $f (@lines) {
        if (grep {$_ eq $f} @legacy_build_targets) {
            # @legacy_build_targets に含まれる
            if (grep {$_ eq $f} @both_build_targets) {
                print "$f\n";
            }
        } else {
            print "$f\n";
        }
    }
}

