use strict;
use warnings;
use utf8;

my $queries = [];

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a =~ /\A([_0-9a-zA-Z][-_0-9a-zA-Z]*)(!?=)(.*)\z/) {
        push(@$queries, [$1, $2, $3]);
    } else {
        die "Unknown argument: $a";
    }
}

my $headers = undef;
my $header_count = 0;

{
    my $line = <STDIN>;
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    $headers = \@cols;
    $header_count = scalar @cols;

    for (my $i = 0; $i < @$queries; $i++) {
        my $col_name = $queries->[$i]->[0];
        my $f = 1;
        for (my $j = 0; $j < $header_count; $j++) {
            if ($headers->[$j] eq $col_name) {
                $queries->[$i]->[0] = $j;
                $f = '';
                last;
            }
        }
        if ($f) {
            die "Unknown column name: $col_name\n";
        }
    }

    print $line . "\n";
}

while (my $line = <STDIN>) {
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    # 行にタブの数が少ない場合に列を付け足す
    for (my $i = $header_count - @cols; $i > 0; $i--) {
        push(@cols, "");
    }

    my $f = '';
    for (my $i = 0; $i < @$queries; $i++) {
        my $q = $queries->[$i];
        if ($q->[1] eq '=') {
            if ($cols[$q->[0]] eq $q->[2]) {
                $f = 1;
                last;
            }
        } elsif ($q->[1] eq '!=') {
            if ($cols[$q->[0]] ne $q->[2]) {
                $f = 1;
                last;
            }
        }
    }
    next unless $f;

    print $line . "\n";
}

