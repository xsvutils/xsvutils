use strict;
use warnings;
use utf8;

use Encode qw/encode_utf8 decode_utf8/;

# table.pl にも同じ関数が定義されている
sub charWidth {
    my ($ch) = @_;
    my $o = ord($ch);
    if ($o >= 0x3000 && $o <= 0x30FF ||
        $o >= 0x4E00 && $o <= 0x9FFF ||
        $o >= 0xFF00 && $o <= 0xFF5F) {
        return 2;
    } else {
        return 1;
    }
}

# table.pl にも同じ関数が定義されている
sub stringViewLength {
    my ($str) = @_;
    my $str2 = decode_utf8($str);
    my $len = length($str2);
    my $resultLength = 0;
    for (my $i = 0; $i < $len; $i++) {
        my $ch = substr($str2, $i, 1);
        $resultLength += charWidth($ch);
    }
    $resultLength;
}

# total.pl にも同じ関数が定義されている
sub normalizeNumber {
    my ($str) = @_;
    if ($str =~ /\A *([-+]?[0-9]+(\.[0-9]*)?) *\z/) {
        return $1;
    } else {
        return 0;
    }
}

my $data = [];

{
    my $line = <STDIN>;
    exit(1) unless defined($line);
}

while (my $line = <STDIN>) {
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    # 行にタブの数が少ない場合に列を付け足す
    for (my $i = 2 - @cols; $i > 0; $i--) {
        push(@cols, "");
    }

    my $name = $cols[0];
    my $value = $cols[1];

    push(@$data, [$name, $value]);

}

my $x_len_max = 0;
my $y_len_max = 0;
my $y_min = 0;
my $y_max = 0;
for (my $i = 0; $i < @$data; $i++) {
    my $x_str = $data->[$i]->[0];
    my $x_len = stringViewLength($x_str);
    my $y_str = $data->[$i]->[1];
    my $y_len = stringViewLength($y_str);
    my $y = normalizeNumber($y_str);
    if ($x_len > $x_len_max) {
        $x_len_max = $x_len;
    }
    if ($y_len > $y_len_max) {
        $y_len_max = $y_len;
    }
    if ($y < $y_min || $i == 0) {
        $y_min = $y;
    }
    if ($y > $y_max || $i == 0) {
        $y_max = $y;
    }
}

my $TERMINAL_COLS = $ENV{"TERMINAL_COLS"};
$TERMINAL_COLS = 80 if (defined($TERMINAL_COLS));

my $bar_max = $TERMINAL_COLS - $x_len_max - $y_len_max - 2;

my $y_ratio1 = 1;
my $y_ratio2 = 1;
if ($y_max > 0) {
    while   ($bar_max * $y_ratio2      > $y_max * $y_ratio1) {
        $y_ratio1 *= 10;
    }
    while   ($bar_max * $y_ratio2 * 10 < $y_max * $y_ratio1) {
        $y_ratio2 *= 10;
    }
    if      ($bar_max * $y_ratio2 * 5  < $y_max * $y_ratio1) {
        $y_ratio2 *= 10;
    } elsif ($bar_max * $y_ratio2 * 2  < $y_max * $y_ratio1) {
        $y_ratio2 *= 5;
    }
}

for (my $i = 0; $i < @$data; $i++) {
    my $x_str = $data->[$i]->[0];
    my $x_len = stringViewLength($x_str);
    my $y_str = $data->[$i]->[1];
    my $y_len = stringViewLength($y_str);
    my $y = normalizeNumber($y_str);
    my $pd1 = $x_len_max - $x_len + 1;
    my $pd2 = $y_len_max - $y_len;
    if ($y_max > 0) {
        my $y2 = int($y * $y_ratio1 / $y_ratio2);
        print $x_str . (" " x $pd1) . (" " x $pd2) . $y_str . " " . ("*" x $y2) . "\n";
    } else {
        print $x_str . (" " x $pd1) . (" " x $pd2) . $y_str . " " . "\n";
    }
}

