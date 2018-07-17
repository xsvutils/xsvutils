use strict;
use warnings;
use utf8;

my $multiValueFlag = undef;

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "--multi-value-a") {
        $multiValueFlag = "a";
    } else {
        die "Unknown argument: $a";
    }
}

die "`mergecols` subcommand requires option --multi-value-a" unless defined $multiValueFlag;

sub createColumnIndeces {
    my ($headers) = @_;
    my $headerCount = @$headers;
    my $columnIndeces = [];
    for (my $i = 0; $i < $headerCount; $i++) {
        my $name = $headers->[$i];
        my $f = undef;
        for (my $j = 0; $j < @$columnIndeces; $j++) {
            if ($columnIndeces->[$j]->[0] eq $name) {
                push(@{$columnIndeces->[$j]->[1]}, $i);
                $f = 1;
                last;
            }
        }
        if (!$f) {
            push(@$columnIndeces, [$name, [$i]]);
        }
    }
    $columnIndeces;
}

my $headerCount = 0;
my $columnIndeces = [];
# [
#     ["id" , [0]],
#     ["name" , [1]],
#     ["category" , [2, 3]],
# ]

{
    my $line = <STDIN>;
    exit(1) unless defined($line);

    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    my $headers = \@cols;
    $headerCount = @cols;
    $columnIndeces = createColumnIndeces($headers);

    my @cols2 = ();
    foreach my $t (@$columnIndeces) {
        push(@cols2, $t->[0]);
    }
    print join("\t", @cols2) . "\n";
}

while (my $line = <STDIN>) {
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    # 行にタブの数が少ない場合に列を付け足す
    for (my $i = $headerCount - @cols; $i > 0; $i--) {
        push(@cols, "");
    }

    my @cols2 = ();
    foreach my $t (@$columnIndeces) {
        my $indeces = $t->[1];
        if (@$indeces == 1) {
            push(@cols2, $cols[$t->[1]->[0]]);
            next;
        }
        if ($multiValueFlag eq "a") {
            # TODO セミコロンのエスケープ解除
            my @vs = ();
            foreach my $i (@{$t->[1]}) {
                my $v = $cols[$i];
                push(@vs, grep { $_ ne "" } split(/;/, $v, -1));
            }
            push(@cols2, join(";", @vs));
        } else {
            die;
        }
    }

    print join("\t", @cols2) . "\n";
}



