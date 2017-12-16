
# 固定長のテーブル出力をするためのスクリプト

use strict;
use warnings;
use utf8;

use Encode qw/encode_utf8 decode_utf8/;

# 端末に表示できる行数
my $terminal_height;
if (defined($ENV{TERMINAL_LINES})) {
    $terminal_height = $ENV{TERMINAL_LINES};
    if ($terminal_height < 3) {
        $terminal_height = 0;
    }
} else {
    $terminal_height = 0;
}

my $max_width = 80;

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "--max-width") {
        die "option --max-width needs an argument" unless (@ARGV);
        my $b = shift(@ARGV);
        $max_width = $b + 0;
        if ($max_width ne $b) {
            die "option --max-width argument must be integer";
        }
    } else {
        die "Unknown argument: $a";
    }
}

# Ctrl-C を無視するハンドラ
sub interrupt {
    # nothing
}
$SIG{INT} = \&interrupt;

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

sub stringViewPadding {
    my ($str, $viewLength) = @_;
    if (!defined($str)) {
        $str = "";
    }
    my $str2 = decode_utf8($str);
    my $len = length($str2);
    my $len1 = $len - 1;
    my $resultLength = 0;
    for (my $i = 0; $i < $len; $i++) {
        my $ch = substr($str2, $i, 1);
        my $resultLength2 = $resultLength + charWidth($ch);
        if ($resultLength2 > $viewLength || $resultLength2 == $viewLength && $i < $len1) {
            return " " . encode_utf8(substr($str2, 0, $i)) . ("." x ($viewLength - $resultLength + 1));
        }
        $resultLength = $resultLength2;
    }
    return " " . $str . (" " x ($viewLength - $resultLength + 1));
}

my $printed_line_count = 0;
my $printing_header_cols = undef;

sub printRecord {
    my ($cols, $col_lengths, $header_flag) = @_;

    if (!$header_flag && $terminal_height > 0 && $printed_line_count > 0 &&
        $printed_line_count % ($terminal_height - 1) == 0) {
        printRecord($printing_header_cols, $col_lengths, 1);
    }
    $printed_line_count++;

    my @colViews = ();
    my $col_count = scalar @$col_lengths;
    for (my $i = 0; $i < $col_count; $i++) {
        my $viewLength = $col_lengths->[$i];
        if ($viewLength > $max_width) {
            $viewLength = $max_width;
        }
        my $col = $cols->[$i];
        push(@colViews, stringViewPadding($col, $viewLength));
    }
    print "|" . join("|", @colViews) . "|\n";
}

my $max_line_count = 1000;

my @records = ();
my $headers = undef;
my $header_count = 0;
my $col_lengths = undef;

while (my $line = <STDIN>) {
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    if (!defined($headers)) {
        $headers = \@cols;
        $header_count = scalar @cols;
        for (my $i = 0; $i < $header_count; $i++) {
            push(@$col_lengths, 1);
        }
    }

    if (@records < $max_line_count) {
        for (my $i = 0; $i < $header_count; $i++) {
            last unless defined($cols[$i]);
            my $l = stringViewLength($cols[$i]);
            if ($col_lengths->[$i] < $l) {
                $col_lengths->[$i] = $l;
            }
        }
        unless (@records) {
            # header line
            my @numheader = ();
            for (my $i = 0; $i < $header_count; $i++) {
                push(@numheader, $i + 1);
            }
            push(@records, \@numheader);
            $printing_header_cols = \@cols;
        }
        push(@records, \@cols);
        next;
    }

    if (@records == $max_line_count) {
        foreach my $record (@records) {
            printRecord($record, $col_lengths);
        }
    }

    printRecord(\@cols, $col_lengths);
}

if (@records < $max_line_count) {
    foreach my $record (@records) {
        printRecord($record, $col_lengths);
    }
}


