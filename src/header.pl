use strict;
use warnings;
use utf8;

my $line = <STDIN>;
$line =~ s/\n\z//g;
my @cols = split(/\t/, $line, -1);

print "column\n";
foreach my $h (@cols) {
    print "$h\n";
}

