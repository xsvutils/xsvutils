use strict;
use warnings;
use utf8;

while (@ARGV) {
    my $a = shift(@ARGV);
    die "Unknown argument: $a";
}

my $headers = undef;
my $header_count = 0;

my $grouptotal = {};
# {
#   "value a" => {
#     "count" => 1,
#     "sum" => 1.0,
#   },
#   "value b" => {
#     "count" => 3,
#     "sum" => 2.0,
#   },
#   }
# }
my $values = [];

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

    if ($valueB !~ /\A(0|[1-9][0-9]*)(\.[0-9]*)?\z/) {
        $valueB = 0;
    }

    if (!defined($grouptotal->{$valueA})) {
        $grouptotal->{$valueA} = {count => 0, sum => 0.0};
        push(@$values, $valueA);
    }
    $grouptotal->{$valueA}->{count}++;
    $grouptotal->{$valueA}->{sum} += $valueB;

    if ($record_count % 10000 == 0) {
        print STDERR "Record: $record_count ...\n";
    }

    if ($interrupted) {
        last;
    }
}
$record_count--;

print "$headers->[0]\tcount\tsum\tavg\n";

foreach my $valueA (@$values) {
    my $count = $grouptotal->{$valueA}->{count};
    my $sum = $grouptotal->{$valueA}->{sum};
    my $avg = $sum / $count;
    print "$valueA\t$count\t$sum\t$avg\n";
}
