use strict;
use warnings;
use utf8;

my $option_column = undef;

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "--col") {
        die "option --col needs an argument" unless (@ARGV);
        $option_column = shift(@ARGV);
    } else {
        die "Unknown argument: $a";
    }
}

die "subcommand `cutidx` requires option --col" unless defined $option_column;

sub createColumnIndex {
    my ($headers) = @_;
    my $headerCount = @$headers;

    for (my $i = 0; $i < $headerCount; $i++) {
        if ($headers->[$i] eq $option_column) {
            return $i;
        }
    }
    print STDERR "Unknown column: $option_column\n";

}

my $columnIndex = undef;

my $offset = 0;
{
    my $line = <STDIN>;
    exit(1) unless defined($line);

    my $length = length($line);
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    $columnIndex = createColumnIndex(\@cols);

    print "value\toffset\tlength\n";

    $offset += $length;
}

while (my $line = <STDIN>) {
    my $length = length($line);
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    # 行にタブの数が少ない場合に列を付け足す
    for (my $i = $columnIndex - @cols; $i > 0; $i--) {
        push(@cols, "");
    }

    print join("\t", $cols[$columnIndex], $offset, $length) . "\n";

    $offset += $length;
}

