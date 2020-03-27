use strict;
use warnings;
use utf8;

use Encode qw/decode_utf8 encode_utf8/;

my $headers = undef;
my $headerCount = 0;

{
    my $line = <STDIN>;
    exit(1) unless defined($line);

    $line =~ s/\r?\n\z//g;
    $line = decode_utf8($line);
    my @cols = split(/\t/, $line, -1);

    my @colnames = ();

    $headers = \@cols;
    $headerCount = @cols;
    for (my $i = 0; $i < $headerCount; $i++) {
        my $h = $cols[$i];
        if ($h eq "" || grep {$_ eq $h} @colnames) {
            my $s = 2;
            $s = 1 if ($h eq "");
            for (my $j = $s; ; $j++) {
                my $h2 = $h . "_" . $j;
                if (! grep {$_ eq $h2} @colnames) {
                    $h = $h2;
                    last;
                }
            }
            $cols[$i] = $h;
        }
        push(@colnames, $h);
    }
    print encode_utf8(join("\t", @cols)) . "\n";
}

while (my $line = <STDIN>) {
    print $line;
}


