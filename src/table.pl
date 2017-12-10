
# 固定長のテーブル出力をするためのスクリプト

use strict;
use warnings;
use utf8;

use Encode qw/encode_utf8 decode_utf8/;

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

my $max_viewLength = 80;

sub printRecord {
    my ($cols, $col_lengths) = @_;
    my @colViews = ();
    my $col_count = scalar @$col_lengths;
    for (my $i = 0; $i < $col_count; $i++) {
        my $viewLength = $col_lengths->[$i];
        if ($viewLength > $max_viewLength) {
            $viewLength = $max_viewLength;
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
    my @cols = split(/\t/, $line);

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


