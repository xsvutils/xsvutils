use strict;
use warnings;
use utf8;

my $max_record_count = 10000;
my $max_value_count = 167;

my $headers = undef;
my $header_count = 0;
my $header_indeces = [];

my $col_values = [];

my $record_count = 0;

while (my $line = <STDIN>) {
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line);

    if (!defined($headers)) {
        $headers = \@cols;
        $header_count = scalar @cols;
        for (my $i = 0; $i < $header_count; $i++) {
            push(@$header_indeces, $i);
            push(@$col_values, []);
        }
        next;
    }

    $record_count++;

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

    if ($record_count == $max_record_count) {
        for (my $i = 0; $i < $header_count; $i++) {
            if (@{$col_values->[$i]} <= $max_value_count) {
                push(@{$col_values->[$i]}, "...");
            }
        }
        last;
    }
}

print "column\tvalues\n";
for (my $i = 0; $i < $header_count; $i++) {
    my $col_name = $headers->[$i];
    my $values = join(", ", @{$col_values->[$i]});
    print "$col_name\t$values\n";
}

