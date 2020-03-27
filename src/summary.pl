use strict;
use warnings;
use utf8;

my $max_value_count = 167;
my $max_values_length = 300;

my $headers = undef;
my $header_count = 0;

my $summary = [];

my $record_count = 0;

{
    my $line = <STDIN>;
    exit(1) unless defined($line);

    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    $headers = \@cols;
    $header_count = scalar @cols;
    for (my $i = 0; $i < $header_count; $i++) {
        push(@$summary, {
            "count" => 0,
            "values" => {},
            "values_str" => "",
            "cardinality" => 0,
            "is_number" => 1,
         });
    }
}

while (my $line = <STDIN>) {
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    $record_count++;

    # 行にタブの数が少ない場合に列を付け足す
    for (my $i = $header_count - @cols; $i > 0; $i--) {
        push(@cols, "");
    }

    for (my $i = 0; $i < $header_count; $i++) {
        my $sum = $summary->[$i];
        my $v = $cols[$i];
        if ($v ne "") {
            $sum->{"count"}++;
        }
        if ($sum->{"cardinality"} < $max_value_count) {
            if (exists($sum->{"values"}->{$v})) {
                $sum->{"values"}->{$v}++;
            } else {
                $sum->{"values"}->{$v} = 1;
                if (length($sum->{"values_str"}) < $max_values_length) {
                    $sum->{"values_str"} .= ", $v";
                }
                $sum->{"cardinality"}++;
            }
        }
        if ($sum->{"is_number"}) {
            if ($v ne "" && $v !~ /\A([-+])?(0|[1-9][0-9]*)(\.[0-9]*)?\z/) {
                $sum->{"is_number"} = "";
            }
        }
    }
}

for (my $i = 0; $i < $header_count; $i++) {
    my $col_name = $headers->[$i];
    my $sum = $summary->[$i];
    print("name:        $col_name\n");

    my $count = $sum->{"count"};
    print("count:       $count\n");

    my $ratio;
    if ($count == $record_count) {
        $ratio = "100%";
    } else {
        $ratio = sprintf("%.2f%%", $count * 100 / $record_count);
    }
    print("ratio:       $ratio\n");

    my $cardinality = $sum->{"cardinality"};
    if ($cardinality >= $max_value_count) {
        $cardinality = ">= $cardinality";
    }
    print("cardinality: $cardinality\n");

    my $values;
    if ($sum->{"cardinality"} < $max_value_count) {
        my $value_list = $sum->{"values"};
        my @values = sort {
            my $r = - ($value_list->{$a} <=> $value_list->{$b});
            if ($r != 0) {
                $r;
            } else {
                $a cmp $b;
            }
        } (keys %$value_list);
        foreach my $v (@values) {
            my $c = $value_list->{$v};
            $values .= ", $v ($c)";
        }
    } else {
        $values = $sum->{"values_str"};
    }
    if (length($values) >= $max_values_length) {
        $values = substr($values, 0, $max_values_length) . "...";
    }
    $values = substr($values, 2);
    print("value:       $values\n");

    my $is_number = "false";
    if ($sum->{"count"} > 0 && $sum->{"is_number"}) {
        $is_number = "true";
    }
    print("is_number:   $is_number\n");

    print("\n");
}

