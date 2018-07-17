use strict;
use warnings;
use utf8;

my $name = "-";
my $value = "";

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "--name") {
        die "option --name needs an argument" unless (@ARGV);
        $name = shift(@ARGV);
    } elsif ($a eq "--value") {
        die "option --value needs an argument" unless (@ARGV);
        $value = shift(@ARGV);
    } else {
        die "Unknown argument: $a";
    }
}

die "subcommand `addconst` requires option --name" unless defined $name;

{
    my $line = <STDIN>;
    exit(1) unless defined($line);

    print "$name\t$line";
}

while (my $line = <STDIN>) {
    print "$value\t$line";
}

