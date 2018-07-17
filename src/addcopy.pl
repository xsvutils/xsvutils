use strict;
use warnings;
use utf8;

my $name = undef;
my $target_name = undef;

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "--name") {
        die "option --name needs an argument" unless (@ARGV);
        $name = shift(@ARGV);
    } elsif ($a eq "--src") {
        die "option --src needs an argument" unless (@ARGV);
        $target_name = shift(@ARGV);
    } else {
        die "Unknown argument: $a";
    }
}

die "subcommand `addcopy` requires option --name" unless defined $name;
die "subcommand `addcopy` requires option --src" unless defined $target_name;


my $headers = undef;
my $target_column = undef;

{
    my $line = <STDIN>;
    exit(1) unless defined($line);

    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    $headers = \@cols;


    for (my $i = 0; $i < @$headers; $i++) {
        if ($headers->[$i] eq $target_name) {
            $target_column = $i;
            last;
        }
    }
    if (!defined($target_column)) {
        die "Column not found: $target_name\n";
    }

    unshift(@cols, $name);
    print join("\t", @cols) . "\n";
}

while (my $line = <STDIN>) {
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    my $value = "";
    if (defined($cols[$target_column])) {
        $value = $cols[$target_column];
    }

    unshift(@cols, $value);
    print join("\t", @cols) . "\n";
}



