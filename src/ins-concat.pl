use strict;
use warnings;
use utf8;

use Encode qw/decode_utf8 encode_utf8/;

my $dst_column_name = "";
my $src_columns = [];
my $src_column_indices = [];

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "--col") {
        die "option --col needs an argument" unless (@ARGV);
        push(@$src_columns, shift(@ARGV));
    } elsif ($a eq "--dst") {
        die "option --dst needs an argument" unless (@ARGV);
        $dst_column_name = shift(@ARGV);
    } else {
        die "Unknown argument: $a";
    }
}

my $header = undef;
my $headerCount = 0;

{
    my $line = <STDIN>;
    exit(1) unless defined($line);

    $line =~ s/\r?\n\z//g;
    my @cols = split(/\t/, $line, -1);

    $header = [@cols];
    $headerCount = scalar @cols;

    unshift(@cols, $dst_column_name);

    print join("\t", @cols) . "\n";
}

for my $h (@$src_columns) {
    for (my $i = 0; $i <  @$header; $i++) {
        if ($header->[$i] eq $h) {
            push(@$src_column_indices, $i);
            last;
        }
    }
}

while (my $line = <STDIN>) {
    $line =~ s/\r?\n\z//g;
    my @cols = split(/\t/, $line, -1);

    my @v = ();
    foreach my $hi (@$src_column_indices) {
        push(@v, $cols[$hi]);
    }
    unshift(@cols, join("/", @v));

    print join("\t", @cols) . "\n";
}

