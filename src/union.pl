use strict;
use warnings;
use utf8;

my $sources = \@ARGV;
my $handles = [];
my $headers = [];

foreach my $s (@$sources) {
    my $fh;
    if ($s eq '-') {
        $fh = *STDIN;
    } else {
        open($fh, '<', $s) or die "Cannot open `$s`, $!";
    }

    my $line = <$fh>;
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    # TODO ヘッダーが重複して存在する場合にエラーにしたい

    push(@$handles, $fh);
    push(@$headers, \@cols);
}

my $header_result = [];

push(@$header_result, @{$headers->[0]});

for (my $i = 1; $i < @$headers; $i++) {
    my $hs = $headers->[$i];
    foreach my $h (@$hs) {
        if (! grep {$_ eq $h} @$header_result) {
            push(@$header_result, $h);
        }
    }
}

print join("\t", @$header_result) . "\n";

my $header_count = (scalar @$header_result);

my $mappings = [];

foreach my $hs (@$headers) {
    my $map = [(-1) x $header_count];
    for (my $i = 0; $i < @$hs; $i++) {
        my $h = $hs->[$i];
        for (my $j = 0; $j < $header_count; $j++) {
            if ($header_result->[$j] eq $h) {
                $map->[$j] = $i;
            }
        }
    }
    push(@$mappings, $map);
}

for (my $file_id = 0; $file_id < @$handles; $file_id++) {
    my $fh = $handles->[$file_id];
    my $mapping = $mappings->[$file_id];

    while (my $line = <$fh>) {
        $line =~ s/\n\z//g;
        my @cols = split(/\t/, $line, -1);

        # 行にタブの数が少ない場合に列を付け足す
        for (my $i = @{$headers->[$file_id]} - @cols; $i > 0; $i--) {
            push(@cols, "");
        }

        my $result_cols = [];
        for (my $i = 0; $i < $header_count; $i++) {
            my $m = $mapping->[$i];
            if ($m < 0) {
                push(@$result_cols, "");
            } else {
                push(@$result_cols, $cols[$m]);
            }
        }

        print join("\t", @$result_cols) . "\n";
    }
    close($fh);
}



