use strict;
use warnings;
use utf8;

# chart-bar.pl にも同じ関数が定義されている
sub normalizeNumber {
    my ($str) = @_;
    if ($str =~ /\A *([-+]?[0-9]+(\.[0-9]*)?) *\z/) {
        return $1;
    } else {
        return 0;
    }
}

my $option_sum = '';
my $option_avg = '';

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "--sum") {
        $option_sum = 1;
    } elsif ($a eq "--avg") {
        $option_avg = 1;
    } else {
        die "Unknown argument: $a";
    }
}

my $columns = undef;
my $column_count = 0;
my $sum = [];
my $record_count = 0;

{
    my $line = <STDIN>;
    exit(1) unless defined($line);

    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    $columns = \@cols;
    $column_count = scalar @cols;
    for (my $i = 0; $i < $column_count; $i++) {
        push(@$sum, 0);
    }

    print($line . "\n");
}

while (my $line = <STDIN>) {
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    # 行にタブの数が少ない場合に列を付け足す
    for (my $i = $column_count - @cols; $i > 0; $i--) {
        push(@cols, "");
    }

    for (my $i = 0; $i < $column_count; $i++) {
        $sum->[$i] += normalizeNumber($cols[$i]);
    }
    $record_count++;
}

if ($option_sum) {
    print join("\t", @$sum) . "\n";
}
if ($option_avg) {
    my @avg = ();
    for (my $i = 0; $i < $column_count; $i++) {
        push(@avg, $sum->[$i] / $record_count);
    }
    print join("\t", @avg) . "\n";
}

