use strict;
use warnings;
use utf8;

sub escape_csv {
    my ($str) = @_;
    if ($str =~ /[",]/) {
        $str =~ s/"/""/g;
        "\"$str\"";
    } else {
        $str;
    }
}

while (my $line = <STDIN>) {
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    print join(",", (map { escape_csv($_) } @cols)) . "\n";
}

