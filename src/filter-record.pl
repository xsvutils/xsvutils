use strict;
use warnings;
use utf8;

use Encode qw/decode_utf8 encode_utf8/;

my $record_code = $ARGV[0];

my $headers = undef;
my $headerCount = 0;

{
    my $line = <STDIN>;
    exit(1) unless defined($line);

    $line =~ s/\r?\n\z//g;
    $line = decode_utf8($line);
    my @cols = split(/\t/, $line, -1);

    $headers = \@cols;
    $headerCount = @cols;

    print encode_utf8(join("\t", @cols)) . "\n";
}

while (my $line = <STDIN>) {
    $line =~ s/\r?\n\z//g;
    $line = decode_utf8($line);
    my @cols = split(/\t/, $line, -1);

    # 行にタブの数が少ない場合に列を付け足す
    for (my $i = $headerCount - @cols; $i > 0; $i--) {
        push(@cols, "");
    }
    my %rec = ();
    for (my $i = 0; $i < $headerCount; $i++) {
        my $h = $headers->[$i];
        $rec{$h} = $cols[$i];
    }

    if (eval $record_code) {
        print encode_utf8(join("\t", @cols)) . "\n";
    }
}


