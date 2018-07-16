use strict;
use warnings;
use utf8;

while (@ARGV) {
    my $a = shift(@ARGV);
    die "Unknown argument: $a";
}

my $col1_name = undef;
my $col2_name_list = [];
my $col1_name_mapping = {};
my $col1_records = [];

# Ctrl-C で中断して結果を表示するためのハンドラ
my $interrupted = '';
sub interrupt {
    $interrupted = 1;
}
$SIG{INT} = \&interrupt;

{
    my $line = <STDIN>;
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    if (@cols < 3) {
        die "`assemblematrix` subcommand require 3 columns input";
    }

    $col1_name = $cols[0];
}

while (my $line = <STDIN>) {
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    # 行にタブの数が少ない場合に列を付け足す
    for (my $i = 3 - @cols; $i > 0; $i--) {
        push(@cols, "");
    }

    my $col1 = $cols[0];
    my $col2 = $cols[1];
    my $col3 = $cols[2];
    if (!grep {$_ eq $col2} @$col2_name_list) {
        push(@$col2_name_list, $col2);
    }

    my $index = $col1_name_mapping->{$col1};
    if (!defined($index)) {
        $index = @$col1_records;
        $col1_name_mapping->{$col1} = $index;
        push(@$col1_records, [$col1, {}]);
    }
    $col1_records->[$index]->[1]->{$col2} = $col3;

    if ($interrupted) {
        last;
    }
}

print $col1_name;
foreach my $col2_name (@$col2_name_list) {
    print "\t$col2_name";
}
print "\n";

foreach my $record (@$col1_records) {
    print $record->[0];
    foreach my $col2_name (@$col2_name_list) {
        my $value = $record->[1]->{$col2_name};
        if (!defined($value)) {
            $value = "";
        }
        print "\t$value";
    }
    print "\n";
}

