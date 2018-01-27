use strict;
use warnings;
use utf8;

my $record_count = 0;

while (my $line = <STDIN>) {
    $record_count++;

    my $h;
    if (length($line) > 10) {
        $h = substr($line, 0, 10);
    } else {
        $h = $line;
    }
    #print STDERR "1-o2.pl $record_count $h\n";
    if ($record_count == 5) {
        sleep(1);
    }
    if ($record_count == 30) {
        last;
    }
}

