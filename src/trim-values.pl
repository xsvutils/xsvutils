use strict;
use warnings;
use utf8;

use Encode qw/decode_utf8 encode_utf8/;

while (my $line = <STDIN>) {
    $line =~ s/\r?\n\z//g;
    $line = decode_utf8($line);
    my @cols = split(/\t/, $line, -1);

    for (my $i = 0; $i < @cols; $i++) {
        $cols[$i] =~ s/\A\s*(.*)\s*\z/$1/g;
    }
    print encode_utf8(join("\t", @cols)) . "\n";
}



