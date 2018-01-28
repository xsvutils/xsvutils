use strict;
use warnings;
use utf8;

my $name = undef;
my $columns = undef;

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "--name") {
        die "option --name needs an argument" unless (@ARGV);
        $name = shift(@ARGV);
    } elsif ($a eq "--col") {
        die "option --col needs an argument" unless (@ARGV);
        $columns = shift(@ARGV);
    } else {
        die "Unknown argument: $a";
    }
}

die "subcommand `addcross` requires option --name" unless defined $name;
die "subcommand `addcross` requires option --col" unless defined $columns;

sub createColumnIndeces {
    my ($headers) = @_;
    my $headerCount = @$headers;
    my @columns2 = split(/,/, $columns);

    my @columns4 = ();
    foreach my $f (@columns2) {
        my $g = '';
        for (my $i = 0; $i < $headerCount; $i++) {
            if ($headers->[$i] eq $f) {
                push(@columns4, $i);
                $g = 1;
                last;
            }
        }
        unless ($g) {
            print STDERR "Unknown column: $f\n";
        }
    }
    unless (@columns4) {
        die "Columns not specified.";
    }
    return \@columns4;

}

my $headers = undef;
my $headerCount = 0;
my $columnIndeces = undef;

{
    my $line = <STDIN>;
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    $headers = \@cols;
    $headerCount = @cols;
    $columnIndeces = createColumnIndeces($headers);
    print "$name\t$line\n";
}

while (my $line = <STDIN>) {
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    # 行にタブの数が少ない場合に列を付け足す
    for (my $i = $headerCount - @cols; $i > 0; $i--) {
        push(@cols, "");
    }

    my $value = join("&", (map { $cols[$_] } @$columnIndeces)); # TODO & の扱い
    print "$value\t$line\n";
}

