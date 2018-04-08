use strict;
use warnings;
use utf8;

while (my $line = <STDIN>) {
    $line =~ s/(%5B|\[)(0|[1-9][0-9]*)?(%5D|\])=/=/gi;
    print $line;
}
