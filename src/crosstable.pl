use strict;
use warnings;
use utf8;

my $topCount = [];
my $multiValueFlag = '';

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "--top") { # example: --top 50,5,3
        die "option --top needs an argument" unless (@ARGV);
        $topCount = [split(/,/, shift(@ARGV), -1)];
    } elsif ($a eq "--multi-value") {
        $multiValueFlag = 1;
    } else {
        die "Unknown argument: $a";
    }
}

my $headers = undef;

my $facetcountA = {};
# {
#     "value a" => 3,
#     ...
# }
my $facetcountB = {};
# {
#     "value 1" => 3,
#     ...
# }
my $facetcountC = {};
# {
#     "value a" => {
#         "value 1" => 2,
#         ...
#     }
# }

my $record_count = 0;

# Ctrl-C で中断して結果を表示するためのハンドラ
my $interrupted = '';
sub interrupt {
    $interrupted = 1;
}
$SIG{INT} = \&interrupt;

{
    my $line = <STDIN>;
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    $record_count++;

    $headers = \@cols;
    if (@$headers < 1) {
        push(@$headers, "value");
    }

    for (my $i = 2 - @$topCount; $i > 0; $i--) {
        push(@$topCount, 10);
    }
    for (my $i = 0; $i < 2; $i++) {
        if ($topCount->[$i] !~ /\A(0|[1-9][0-9]*)\z/) {
            $topCount->[$i] = 10;
        }
    }
}

while (my $line = <STDIN>) {
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    $record_count++;

    # 行にタブの数が少ない場合に列を付け足す
    for (my $i = 2 - @cols; $i > 0; $i--) {
        push(@cols, "");
    }

    my $valueA = $cols[0];
    my $valueB = $cols[1];

    if ($multiValueFlag) {
        # TODO 空文字列の扱い
        # TODO セミコロンのエスケープ解除
        my @valuesA = grep { $_ ne "" } split(/;/, $valueA, -1);
        my @valuesB = grep { $_ ne "" } split(/;/, $valueB, -1);
        #my @valuesA = split(/;/, $valueA, -1);
        #my @valuesB = split(/;/, $valueB, -1);

        foreach my $valueA (@valuesA) {
            if (defined($facetcountA->{$valueA})) {
                $facetcountA->{$valueA}++;
            } else {
                $facetcountA->{$valueA} = 1;
            }
        }
        foreach my $valueB (@valuesB) {
            if (defined($facetcountB->{$valueB})) {
                $facetcountB->{$valueB}++;
            } else {
                $facetcountB->{$valueB} = 1;
            }
        }

        foreach my $valueA (@valuesA) {
            if (!defined($facetcountC->{$valueA})) {
                $facetcountC->{$valueA} = {};
            }
            foreach my $valueB (@valuesB) {
                if (defined($facetcountC->{$valueA}->{$valueB})) {
                    $facetcountC->{$valueA}->{$valueB}++;
                } else {
                    $facetcountC->{$valueA}->{$valueB} = 1;
                }
            }
        }
    } else {
        if (defined($facetcountA->{$valueA})) {
            $facetcountA->{$valueA}++;
        } else {
            $facetcountA->{$valueA} = 1;
        }
        if (defined($facetcountB->{$valueB})) {
            $facetcountB->{$valueB}++;
        } else {
            $facetcountB->{$valueB} = 1;
        }

        if (!defined($facetcountC->{$valueA})) {
            $facetcountC->{$valueA} = {};
        }
        if (defined($facetcountC->{$valueA}->{$valueB})) {
            $facetcountC->{$valueA}->{$valueB}++;
        } else {
            $facetcountC->{$valueA}->{$valueB} = 1;
        }
    }

    if ($record_count % 10000 == 0) {
        print STDERR "Record: $record_count ...\n";
    }

    if ($interrupted) {
        last;
    }
}

my $valuesA = [sort {
    my $r = $facetcountA->{$b} <=> $facetcountA->{$a};
    if ($r == 0) {
        $r = $a cmp $b;
    }
    $r; } (keys %$facetcountA)];
my $valuesB = [sort {
    my $r = $facetcountB->{$b} <=> $facetcountB->{$a};
    if ($r == 0) {
        $r = $a cmp $b;
    }
    $r; } (keys %$facetcountB)];

if ($topCount->[0] > 0 && @$valuesA > $topCount->[0]) {
    $valuesA = [@$valuesA[0 .. ($topCount->[0] - 1)]];
}
if ($topCount->[1] > 0 && @$valuesB > $topCount->[1]) {
    $valuesB = [@$valuesB[0 .. ($topCount->[1] - 1)]];
}

print "$headers->[0]\tcount";
foreach my $valueB (@$valuesB) {
    print "\t$valueB";
}
print "\n";

print "\t" . ($record_count - 1);
foreach my $valueB (@$valuesB) {
    print "\t" . $facetcountB->{$valueB};
}
print "\n";

foreach my $valueA (@$valuesA) {
    print "$valueA\t" . $facetcountA->{$valueA};
    foreach my $valueB (@$valuesB) {
        if (defined($facetcountC->{$valueA}->{$valueB})) {
            print "\t" . $facetcountC->{$valueA}->{$valueB};
        } else {
            print "\t0";
        }
    }
    print "\n";
}
