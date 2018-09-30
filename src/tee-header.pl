use strict;
use warnings;
use utf8;

my $headerOutput = $ARGV[0];
open(my $headerOutputFp, '>', $headerOutput) or die $!;

{
    my $line = <STDIN>;
    exit(1) unless defined($line);
    print $headerOutputFp $line;
    print $line;
}

close($headerOutputFp);

while (my $line = <STDIN>) {
    print $line;
}

