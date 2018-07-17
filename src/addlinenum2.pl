use strict;
use warnings;
use utf8;

my $name = "-";

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "--name") {
        die "option --name needs an argument" unless (@ARGV);
        $name = shift(@ARGV);
    } else {
        die "Unknown argument: $a";
    }
}

die "subcommand `addlinenum2` requires option --name" unless defined $name;

my $value = 1;

my $line = <STDIN>;
exit(1) unless defined($line);

print "$name\t$line";

while (my $line = <STDIN>) {
    my $str = sprintf("%012d", $value);
    print "$str\t$line";
    $value++;
}

