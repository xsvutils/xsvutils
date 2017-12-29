use strict;
use warnings;
use utf8;

my $headers = undef;
my $header_count = 0;

my $facetcount = [];

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
    $header_count = scalar @cols;
    for (my $i = 0; $i < $header_count; $i++) {
        push(@$facetcount, {});
    }
}

while (my $line = <STDIN>) {
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    # 行にタブの数が少ない場合に列を付け足す
    for (my $i = $header_count - @cols; $i > 0; $i--) {
        push(@cols, "");
    }

    for (my $i = 0; $i < $header_count; $i++) {
        my $v = $cols[$i];
        if (defined($facetcount->[$i]->{$v})) {
            $facetcount->[$i]->{$v}++;
        } else {
            $facetcount->[$i]->{$v} = 1;
        }
    }

    if ($record_count % 10000 == 0) {
        print STDERR "Record: $record_count\n";
    }

    if ($interrupted) {
        last;
    }
}

print "column\tvalue\tcount\n";
for (my $i = 0; $i < $header_count; $i++) {
    my $col_name = $headers->[$i];
    my $fc = $facetcount->[$i];
    my $values = [keys(%$fc)];
    $values = [sort { my $r = $fc->{$b} <=> $fc->{$a}; if ($r == 0) { $r = $a cmp $b; } $r; } @$values];
    foreach my $v (@$values) {
        my $c = $fc->{$v};
        print "$col_name\t$v\t$c\n";
    }
}


