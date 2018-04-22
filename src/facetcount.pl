use strict;
use warnings;
use utf8;

my $multiValueFlag = '';
my $weightFlag = '';

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "--multi-value-a") {
        $multiValueFlag = "a";
    } elsif ($a eq "--weight") {
        $weightFlag = 1;
    } else {
        die "Unknown argument: $a";
    }
}

my $headers = undef;
my $header_count = 0;

my $facetcount = [];
my $facetcount2 = [];

my $record_count = 0;
my $sum = 0;

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
        push(@$facetcount2, 0);
    }
}

while (my $line = <STDIN>) {
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    $record_count++;

    # 行にタブの数が少ない場合に列を付け足す
    for (my $i = $header_count - @cols; $i > 0; $i--) {
        push(@cols, "");
    }

    my $weight = 1;
    my $i = 0;
    if ($weightFlag) {
        $weight = $cols[0];
        $i++;
    }
    $sum += $weight;
    for (; $i < $header_count; $i++) {
        my $v = $cols[$i];
        if ($v ne "") {
            $facetcount2->[$i] += $weight;
        }
        if ($multiValueFlag eq "a") {
            # TODO セミコロンのエスケープ解除
            my %vs_map = map { $_ => 1 } (grep { $_ ne "" } split(/;/, $v, -1));
            my @vs = keys %vs_map;
            foreach my $v (@vs) {
                if (defined($facetcount->[$i]->{$v})) {
                    $facetcount->[$i]->{$v} += $weight;
                } else {
                    $facetcount->[$i]->{$v} = $weight;
                }
            }
        } else {
            if (defined($facetcount->[$i]->{$v})) {
                $facetcount->[$i]->{$v} += $weight;
            } else {
                $facetcount->[$i]->{$v} = $weight;
            }
        }
    }

    if ($record_count % 10000 == 0) {
        print STDERR "Record: $record_count ...\n";
    }

    if ($interrupted) {
        last;
    }
}
$record_count--;

print "column\tvalue\tcount\tratio\tratio2\n";

my $i = 0;
if ($weightFlag) {
    $i++;
}
for (; $i < $header_count; $i++) {
    my $col_name = $headers->[$i];
    my $fc = $facetcount->[$i];
    my $sum2 = $facetcount2->[$i];
    my $values = [keys(%$fc)];
    $values = [sort { my $r = $fc->{$b} <=> $fc->{$a}; if ($r == 0) { $r = $a cmp $b; } $r; } @$values];
    foreach my $v (@$values) {
        my $c = $fc->{$v};
        my $ratio = sprintf("%6.2f%%", 100 * $c / $sum);
        my $ratio2 = sprintf("%6.2f%%", 100 * $c / $sum2);
        print "$col_name\t$v\t$c\t$ratio\t$ratio2\n";
    }
}


