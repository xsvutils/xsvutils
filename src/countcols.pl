use strict;
use warnings;
use utf8;

my $counts = {};

my $record_count = 0;

# Ctrl-C で中断して結果を表示するためのハンドラ
my $interrupted = '';
sub interrupt {
    $interrupted = 1;
}
$SIG{INT} = \&interrupt;

while (my $line = <STDIN>) {
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line);

    $record_count++;

    my $c = scalar @cols;
    if (defined($counts->{$c})) {
        $counts->{$c}++;
    } else {
        $counts->{$c} = 1;
    }

    if ($record_count % 10000 == 0) {
        print STDERR "Record: $record_count\n";
    }

    if ($interrupted) {
        last;
    }
}

my @counts2 = sort { $a <=> $b } (keys %$counts);

print "cols\trecords\tratio\n";
for my $c (@counts2) {
    my $v = $counts->{$c};
    my $ratio = sprintf("%.2f%%", 100.0 * $v / $record_count);
    print "$c\t$v\t$ratio\n";
}

