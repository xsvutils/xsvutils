use strict;
use warnings;
use utf8;

while (my $line = <STDIN>) {
    $line =~ s/\+/ /g;
    $line =~ s/;/%3B/gi;
    print $line;
}
