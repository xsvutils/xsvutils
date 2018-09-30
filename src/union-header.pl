use strict;
use warnings;
use utf8;

my $headerInput = $ARGV[0];
open(my $headerInputFp, '<', $headerInput) or die $!;

{
    my $line = <$headerInputFp>;
    exit(1) unless defined($line);
    print $line;
}

close($headerInputFp);

while (my $line = <STDIN>) {
    print $line;
}

