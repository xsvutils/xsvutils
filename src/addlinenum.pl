use strict;
use warnings;
use utf8;

my $name = "-";
my $value = 1;
my $sortable_flag = '';

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "--name") {
        die "option --name needs an argument" unless (@ARGV);
        $name = shift(@ARGV);
    } elsif ($a eq "--value") {
        die "option --value needs an argument" unless (@ARGV);
        $value = shift(@ARGV);
    } elsif ($a eq "--sortable") {
        $sortable_flag = 1;
    } else {
        die "Unknown argument: $a";
    }
}

die "subcommand `addlinenum` requires option --name" unless defined $name;

my $line = <STDIN>;
exit(1) unless defined($line);

print "$name\t$line";

while (my $line = <STDIN>) {
    if ($sortable_flag) {
        my $value2 = sprintf("%012d", $value);
        print "$value2\t$line";
    } else {
        print "$value\t$line";
    }
    $value++;
}

