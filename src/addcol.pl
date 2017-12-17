use strict;
use warnings;
use utf8;

my $option_name = "-";
my $option_value = "";

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "--name") {
        die "option --name needs an argument" unless (@ARGV);
        $option_name = shift(@ARGV);
    } elsif ($a eq "--value") {
        die "option --value needs an argument" unless (@ARGV);
        $option_value = shift(@ARGV);
    } else {
        die "Unknown argument: $a";
    }
}

my $line = <STDIN>;
print "$option_name\t$line";

while (my $line = <STDIN>) {
    print "$option_value\t$line";
}

