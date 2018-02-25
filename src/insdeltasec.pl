use strict;
use warnings;
use utf8;

use Time::Local qw/timelocal/;

my $src_column_name = undef;
my $dst_column_name = undef;

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "--src") {
        die "option --src needs an argument" unless (@ARGV);
        $src_column_name = shift(@ARGV);
    } elsif ($a eq "--dst") {
        die "option --dst needs an argument" unless (@ARGV);
        $dst_column_name = shift(@ARGV);
    } else {
        die "Unknown argument: $a";
    }
}

die "subcommand `insdeltasec` requires option --name" unless defined $dst_column_name;
die "subcommand `insdeltasec` requires option --src" unless defined $src_column_name;

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

my $prev_time = '';

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
        my $h = "00";
        my $m = "00";
        my $s = "00";
        my $tail1 = $6;
        if ($tail1 =~ /\A[T ]([0-9][0-9])(.*)\z/) {
            $h = $1;
            my $tail2 = $2;
            if ($tail2 =~ /\A(|:)([0-9][0-9])(.*)\z/) {
                $m = $2;
                my $tail3 = $3;
                if ($tail3 =~ /\A(|:)([0-9][0-9])(.*)\z/) {
                    $s = $2;
                    #my $tail4 = $3;
                }
            }
        }
        my $time = timelocal($s, $m, $h, $D, $M - 1, $Y);
        if ($prev_time ne '') {
            $result = $time - $prev_time;
        }
        $prev_time = $time;
    } else {
        $prev_time = '';
    }

    unshift(@cols, $result);
    print $result . "\t" . $line . "\n";
}



