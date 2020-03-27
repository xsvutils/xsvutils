use strict;
use warnings;
use utf8;

sub escape_for_bash {
    my ($str) = @_;
    if ($str =~ /\A[-_.=\/0-9a-zA-Z]+\z/) {
        return $str;
    }
    $str =~ s/'/'"'"'/g;
    return "'" . $str . "'";
}

my $option_comma = "";
my $option_col = "";

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "--comma") {
        $option_comma = 1;
    } elsif ($a eq "--col") {
        $option_col = 1;
    } else {
        die "Unknown argument: $a";
    }
}

my $line = <STDIN>;
exit(1) unless defined($line);

$line =~ s/\n\z//g;
my @cols = split(/\t/, $line, -1);

if ($option_comma) {
    print join(",", @cols) . "\n";
} elsif ($option_col) {
    foreach my $b (@cols) {
        print "col " . escape_for_bash($b) . "\n";
    }
} else {
    foreach my $b (@cols) {
        print $b . "\n";
    }
}

