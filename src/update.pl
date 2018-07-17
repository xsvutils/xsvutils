use strict;
use warnings;
use utf8;

my $commands = [];

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a =~ /\A(0|[1-9][0-9]*):([_0-9a-zA-Z][-_0-9a-zA-Z]*)=(.*)\z/) {
        push(@$commands, [$1, $2, $3]);
    } else {
        die "Unknown argument format: $a";
    }
}

$commands = [sort {$a->[0] <=> $b->[1]} @$commands];

my $headers = undef;
my $headerCount = 0;
my $headerIndexMap = undef;

my $record_count = 0;

sub update {
    my ($cols) = @_;
    while (@$commands && $commands->[0]->[0] == $record_count) {
        my $t = pop(@$commands);
        my $colIndex;
        if (defined($headerIndexMap->{$t->[1]})) {
            $colIndex = $headerIndexMap->{$t->[1]};
        } elsif ($t->[1] =~ /\A[1-9][0-9]*\z/) {
            $colIndex = $t->[1] - 1;
        } else {
            die "Unknown column: $t->[1]\n";
        }
        if (defined($colIndex)) {

            # 行にタブの数が少ない場合に列を付け足す
            for (my $i = $colIndex - @$cols; $i > 0; $i--) {
                push(@$cols, "");
            }

            $cols->[$colIndex] = $t->[2];
        }
    }
}

{
    my $line = <STDIN>;
    exit(1) unless defined($line);

    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    $headers = \@cols;
    $headerCount = @cols;
    $headerIndexMap = {};
    for (my $i = 0; $i < $headerCount; $i++) {
        $headerIndexMap->{$headers->[$i]} = $i;
    }

    update(\@cols);

    print join("\t", @cols) . "\n";

    $record_count++;
}

while (my $line = <STDIN>) {
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    update(\@cols);

    print join("\t", @cols) . "\n";

    $record_count++;

    last unless(@$commands);
}

while (my $line = <STDIN>) {
    print $line;
}

