use strict;
use warnings;
use utf8;

use Time::Local qw/timelocal/;

my $dst_column_name = undef;
my $src_column_name = undef;
my $start_day = undef;

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "--name") {
        die "option --name needs an argument" unless (@ARGV);
        $dst_column_name = shift(@ARGV);
    } elsif ($a eq "--src") {
        die "option --src needs an argument" unless (@ARGV);
        $src_column_name = shift(@ARGV);
    } elsif ($a eq "--start-day") {
        die "option --start-day needs an argument" unless (@ARGV);
        $start_day = shift(@ARGV);
    } else {
        die "Unknown argument: $a";
    }
}

die "subcommand `insweek` requires option --name" unless defined $dst_column_name;
die "subcommand `insweek` requires option --src" unless defined $src_column_name;
die "subcommand `insweek` requires option --start-day" unless defined $start_day;

my $headers = undef;
my $src_column_index = undef;

{
    my $line = <STDIN>;
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    $headers = \@cols;

    for (my $i = 0; $i < @$headers; $i++) {
        if ($headers->[$i] eq $src_column_name) {
            $src_column_index = $i;
            last;
        }
    }
    if (!defined($src_column_index)) {
        die "Column not found: $src_column_name\n";
    }

    print $dst_column_name . "\t" . $line . "\n";
}

while (my $line = <STDIN>) {
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    my $value = "";
    if (defined($cols[$src_column_index])) {
        $value = $cols[$src_column_index];
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
        my $time = timelocal(0, 0, 0, $D, $M - 1, $Y);
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$dmy) = localtime($time);
        my $delta = $wday - $start_day;
        if ($delta < 0) {
            $delta += 7;
        }
        $time -= 86400 * $delta;
        ($sec,$min,$hour,$mday,$mon,$year,$wday,$dmy) = localtime($time);
        $year += 1900;
        $mon++;
        $result = sprintf("%04d-%02d-%02d", $year, $mon, $mday);
    }

    unshift(@cols, $result);
    print $result . "\t" . $line . "\n";
}



