use strict;
use warnings;
use utf8;

use Encode qw/decode_utf8 encode_utf8/;

my $header_code = $ARGV[0];
my $record_code = $ARGV[1];

my $header1 = undef;
my $header2 = undef;
my $headerCount1 = 0;
my $headerCount2 = 0;

{
    my $line = <STDIN>;
    exit(1) unless defined($line);

    $line =~ s/\r?\n\z//g;
    $line = decode_utf8($line);
    my @cols = split(/\t/, $line, -1);

    $header1 = \@cols;
    $headerCount1 = scalar @cols;

    my @header = (@cols);
    eval $header_code;

    $header2 = \@header;
    $headerCount2 = scalar @header;

    print encode_utf8(join("\t", @header)) . "\n";
}

while (my $line = <STDIN>) {
    $line =~ s/\r?\n\z//g;
    $line = decode_utf8($line);
    my @cols = split(/\t/, $line, -1);

    # 行にタブの数が少ない場合に列を付け足す
    for (my $i = $headerCount1 - @cols; $i > 0; $i--) {
        push(@cols, "");
    }

    my %rec = ();
    for (my $i = 0; $i < $headerCount1; $i++) {
        my $h = $header1->[$i];
        $rec{$h} = $cols[$i];
    }

    eval $record_code;

    @cols = ();
    for (my $i = 0; $i < $headerCount2; $i++) {
        my $h = $header2->[$i];
        my $v = $rec{$h};
        $v = "" if (!defined($v));
        push(@cols, $v);
    }
    print encode_utf8(join("\t", @cols)) . "\n";
}

