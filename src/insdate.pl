use strict;
use warnings;
use utf8;

my $action = undef;
my $dst_column_name = undef;
my $src_column_name = undef;

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "hour") {
        $action = "hour";
    } elsif ($a eq "date") {
        $action = "date";
    } elsif ($a eq "--name") {
        die "option --name needs an argument" unless (@ARGV);
        $dst_column_name = shift(@ARGV);
    } elsif ($a eq "--src") {
        die "option --src needs an argument" unless (@ARGV);
        $src_column_name = shift(@ARGV);
    } else {
        die "Unknown argument: $a";
    }
}

die "subcommand `insdate` requires action parameter" unless defined $action;
die "subcommand `insdate` requires option --name" unless defined $dst_column_name;
die "subcommand `insdate` requires option --src" unless defined $src_column_name;

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

sub getResultHour {
    my ($value) = @_;
    if ($value =~ /\A([0-9][0-9][0-9][0-9])(|[-\/])([0-9][0-9])(|[-\/])([0-9][0-9])(.*)\z/) {
        my $Y = $1;
        my $M = $3;
        my $D = $5;
        my $tail1 = $6;
        my $h = "00";
        #my $m = "00";
        #my $s = "00";
        if ($tail1 =~ /\A[T ]([0-9][0-9])(.*)\z/) {
            $h = $1;
        #    my $tail2 = $2;
        #    if ($tail2 =~ /\A(|:)([0-9][0-9])(.*)\z/) {
        #        $m = $2;
        #        my $tail3 = $3;
        #        if ($tail3 =~ /\A(|:)([0-9][0-9])(.*)\z/) {
        #            $s = $2;
        #            #my $tail4 = $3;
        #        }
        #    }
        }
        return "${Y}-${M}-${D}T${h}";
    }
    return "";
}

sub getResultDate {
    my ($value) = @_;
    if ($value =~ /\A([0-9][0-9][0-9][0-9])(|[-\/])([0-9][0-9])(|[-\/])([0-9][0-9])(.*)\z/) {
        my $Y = $1;
        my $M = $3;
        my $D = $5;
        #my $tail1 = $6;
        #my $h = "00";
        #my $m = "00";
        #my $s = "00";
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
        return "${Y}-${M}-${D}";
    }
    return "";
}

my $getResultValue;
if ($action eq "hour") {
    $getResultValue = \&getResultHour;
} elsif ($action eq "date") {
    $getResultValue = \&getResultDate;
}

while (my $line = <STDIN>) {
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    my $value = "";
    if (defined($cols[$src_column_index])) {
        $value = $cols[$src_column_index];
    }

    my $result = $getResultValue->($value);

    unshift(@cols, $result);
    print $result . "\t" . $line . "\n";
}



