use strict;
use warnings;
use utf8;

my $new_column_name = undef;
my $source_column_name = undef;

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "--name") {
        die "option --name needs an argument" unless (@ARGV);
        $new_column_name = shift(@ARGV);
    } elsif ($a eq "--src") {
        die "option --src needs an argument" unless (@ARGV);
        $source_column_name = shift(@ARGV);
    } else {
        die "Unknown argument: $a";
    }
}

die "subcommand `insdate` requires option --name" unless defined $new_column_name;
die "subcommand `insdate` requires option --source" unless defined $source_column_name;

my $headers = undef;
my $source_column_index = undef;

{
    my $line = <STDIN>;
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    $headers = \@cols;

    for (my $i = 0; $i < @$headers; $i++) {
        if ($headers->[$i] eq $source_column_name) {
            $source_column_index = $i;
            last;
        }
    }
    if (!defined($source_column_index)) {
        die "Column not found: $source_column_name\n";
    }

    print $new_column_name . "\t" . $line . "\n";
}

while (my $line = <STDIN>) {
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    my $value = "";
    if (defined($cols[$source_column_index])) {
        $value = $cols[$source_column_index];
    }

    my $result = "";
    if ($value =~ /\A([0-9][0-9][0-9][0-9])(|[-\/])([0-9][0-9])(|[-\/])([0-9][0-9])(.*)\z/) {
        my $Y = $1;
        my $M = $3;
        my $D = $5;
        #my $h = "00";
        #my $m = "00";
        #my $s = "00";
        #my $tail1 = $6;
        #if ($tail1 =~ /\A[T ]([0-9][0-9])(.*)\z/) {
        #    $h = $1;
        #    my $tail2 = $2;
        #    if ($tail2 =~ /\A(|:)([0-9][0-9])(.*)\z/) {
        #        $m = $2;
        #        my $tail3 = $3;
        #        if ($tail3 =~ /\A(|:)([0-9][0-9])(.*)\z/) {
        #            $s = $2;
        #            #my $tail4 = $3;
        #        }
        #    }
        #}
        $result = "$Y-$M-${D}";
    }

    unshift(@cols, $result);
    print $result . "\t" . $line . "\n";
}



