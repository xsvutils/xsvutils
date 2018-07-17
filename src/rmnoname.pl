use strict;
use warnings;
use utf8;

while (@ARGV) {
    my $a = shift(@ARGV);
    die "Unknown argument: $a";
}

my $headerCount = 0;
my $columnIndeces = undef;

{
    my $line = <STDIN>;
    exit(1) unless defined($line);

    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    $headerCount = @cols;
    $columnIndeces = [];
    for (my $i = 0; $i < $headerCount; $i++) {
        if ($cols[$i] ne "") {
            push(@$columnIndeces, $i);
        }
    }

    print join("\t", (map { $cols[$_] } @$columnIndeces)) . "\n";
}

while (my $line = <STDIN>) {
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    # 行にタブの数が少ない場合に列を付け足す
    for (my $i = $headerCount - @cols; $i > 0; $i--) {
        push(@cols, "");
    }

    print join("\t", (map { $cols[$_] } @$columnIndeces)) . "\n";
}

