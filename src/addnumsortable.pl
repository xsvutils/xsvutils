use strict;
use warnings;
use utf8;

my $name = undef;
my $target_name = undef;
my $reverse_flag = '';

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "--name") {
        die "option --name needs an argument" unless (@ARGV);
        $name = shift(@ARGV);
    } elsif ($a eq "--col") {
        die "option --col needs an argument" unless (@ARGV);
        $target_name = shift(@ARGV);
    } elsif ($a eq "--reverse") {
        $reverse_flag = 1;
    } else {
        die "Unknown argument: $a";
    }
}

die "subcommand `addnumsortable` requires option --name" unless defined $name;
die "subcommand `addnumsortable` requires option --col" unless defined $target_name;


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

sub reverseNum {
    my ($str) = @_;
    my $len = length($str);
    my $result = "";
    for (my $i = 0; $i < $len; $i++) {
        my $n = substr($str, $i, 1);
        $result .= chr(0x30 + 0x39 - ord($n));
    }
    $result;
}

while (my $line = <STDIN>) {
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    my $value = "";
    if (defined($cols[$target_column])) {
        $value = $cols[$target_column];
    }

    if ($reverse_flag) {
        if ($value =~ /\A[1-9][0-9]*\z/) {
            $value = "-" . $value;
        } elsif ($value =~ /\A-([1-9][0-9]*)\z/) {
            $value = "-" . $1;
        }
    }

    my $sortable = "";
    if ($value eq "0") {
        $sortable = "5";

    } elsif ($value eq "1") {
        $sortable = "6";
    } elsif ($value eq "-1") {
        $sortable = "4";

    } elsif ($value =~ /\A[1-9]\z/) {
        my $num = $value;
        $sortable = "7" . $num;
    } elsif ($value =~ /\A-([1-9])\z/) {
        my $num = $1;
        $sortable = "3" . reverseNum($num);

    } elsif ($value =~ /\A[1-9][0-9]+\z/) {
        my $num = $value;
        my $len = length($num);
        if ($len < 10) {
            $sortable = "8" . $len . $num;
        } elsif ($len < 100) {
            $sortable = "9" . $len . $num;
        } else {
            $sortable = ""; # TODO
        }
    } elsif ($value =~ /\A-([1-9][0-9]+)\z/) {
        my $num = $1;
        my $len = length($num);
        if ($len < 10) {
            $sortable = "2" . reverseNum($len . $num);
        } elsif ($len < 100) {
            $sortable = "1" . reverseNum($len . $num);
        } else {
            $sortable = ""; # TODO
        }
    }

    unshift(@cols, $sortable);
    print join("\t", @cols) . "\n";
}



