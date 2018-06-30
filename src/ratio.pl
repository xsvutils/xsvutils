use strict;
use warnings;
use utf8;

while (@ARGV) {
    my $a = shift(@ARGV);
    die "Unknown argument: $a";
}

my $headers = undef;
my $headerCount = 0;

my @total = [];
my @records = ();

{
    my $line = <STDIN>;
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    $headers = \@cols;
    $headerCount = @cols;

    for (my $i = 0; $i < $headerCount; $i++) {
        push(@total, 0);
    }

    print $line . "\n";
}

while (my $line = <STDIN>) {
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    # 行にタブの数が少ない場合に列を付け足す
    for (my $i = $headerCount - @cols; $i > 0; $i--) {
        push(@cols, "");
    }

    for (my $i = 1; $i < $headerCount; $i++) {
        if ($cols[$i] ne "") {
            $total[$i] += $cols[$i];
        }
    }

    push(@records, \@cols);
}

foreach my $cols (@records) {
    my @cols = @$cols;
    my @cols2 = ();
    push(@cols2, $cols[0]);
    for (my $i = 1; $i < $headerCount; $i++) {
        my $ratio;
        if ($cols[$i] eq "") {
            $ratio = "";
        } else {
            $ratio = sprintf("%6.2f%%", 100 * $cols[$i] / $total[$i]);
        }
        push(@cols2, $ratio);
    }
    print join("\t", @cols2) . "\n";
}

