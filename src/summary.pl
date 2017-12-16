use strict;
use warnings;
use utf8;

my $max_value_count = 167;

my $headers = undef;
my $header_count = 0;
my $header_indeces = [];

my $col_counts = [];
my $col_values = [];

my $record_count = 0;

# Ctrl-C で中断して結果を表示するためのハンドラ
my $interrupted = '';
sub interrupt {
    $interrupted = 1;
}
$SIG{INT} = \&interrupt;

while (my $line = <STDIN>) {
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line);

    $record_count++;

    if (!defined($headers)) {
        $headers = \@cols;
        $header_count = scalar @cols;
        for (my $i = 0; $i < $header_count; $i++) {
            push(@$header_indeces, $i);
            push(@$col_counts, 0);
            push(@$col_values, []);
        }
        next;
    }

    for (my $i = 0; $i < $header_count; $i++) {
        my $v = "";
        if (defined($cols[$i])) {
            $v = $cols[$i];
        }
        if ($v ne "") {
            $col_counts->[$i]++;
        }
    }

    for my $i (@$header_indeces) {
        my $v = "";
        if (defined($cols[$i])) {
            $v = $cols[$i];
        }
        if ($v ne "") {
            if (@{$col_values->[$i]} < $max_value_count) {
                unless (grep {$_ eq $v} @{$col_values->[$i]}) {
                    push(@{$col_values->[$i]}, $v);
                }
            } elsif (@{$col_values->[$i]} == $max_value_count) {
                unless (grep {$_ eq $v} @{$col_values->[$i]}) {
                    push(@{$col_values->[$i]}, "...");
                    $header_indeces = [grep {$_ ne $i} @$header_indeces];
                }
            }
        }
    }

    if ($record_count % 10000 == 0) {
        print STDERR "Record: $record_count\n";
    }

    if (!@$header_indeces || $interrupted) {
        for (my $i = 0; $i < $header_count; $i++) {
            if (@{$col_values->[$i]} <= $max_value_count) {
                push(@{$col_values->[$i]}, "...");
            }
        }
        last;
    }
}

print "num\tcolumn\tratio\tvalues\n";
for (my $i = 0; $i < $header_count; $i++) {
    my $num = $i + 1;
    my $col_name = $headers->[$i];
    my $count = $col_counts->[$i];
    my $ratio = sprintf("%.2f%%", 100.0 * $count / $record_count);
    my $values = join(", ", @{$col_values->[$i]});
    print "$num\t$col_name\t$ratio\t$values\n";
}

