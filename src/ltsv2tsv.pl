use strict;
use warnings;
use utf8;

my $header = undef;

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq '--header') {
        die "$a option requires an argument" unless (@ARGV);
        $header = [split(/,/, shift(@ARGV))];
    } else {
        die "Unknown argument: $a";
    }
}

die "`lstsv2tsv` requires option --header" unless defined $header;

#print join("\t", @$header) . "\n";

while (my $line = <STDIN>) {
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    my $data = {};

    foreach my $c (@cols) {
        if ($c =~ /\A([^:]+):(.*)\z/) {
            $data->{$1} = $2;
        }
    }

    print join("\t", (map {
        if (defined($data->{$_})) {
            $data->{$_};
        } else {
            "";
        }
    } @$header)) . "\n";
}

