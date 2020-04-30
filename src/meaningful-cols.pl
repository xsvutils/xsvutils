use strict;
use warnings;
use utf8;

use Encode qw/decode_utf8 encode_utf8/;

sub escape_for_bash {
    my ($str) = @_;
    if ($str =~ /\A[-_.=\/0-9a-zA-Z]+\z/) {
        return $str;
    }
    $str =~ s/'/'"'"'/g;
    return "'" . $str . "'";
}

my $option_comma = "";
my $option_col = "";

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "--comma") {
        $option_comma = 1;
    } elsif ($a eq "--col") {
        $option_col = 1;
    } else {
        die "Unknown argument: $a";
    }
}

my $headers = undef;
my $headerCount = 0;
my $values = undef;

{
    my $line = <STDIN>;
    exit(1) unless defined($line);

    $line =~ s/\r?\n\z//g;
    $line = decode_utf8($line);
    my @cols = split(/\t/, $line, -1);

    $headers = \@cols;
    $headerCount = @cols;
}

{
    my $line = <STDIN>;
    exit(1) unless defined($line);

    $line =~ s/\r?\n\z//g;
    $line = decode_utf8($line);
    my @cols = split(/\t/, $line, -1);

    # 行にタブの数が少ない場合に列を付け足す
    for (my $i = $headerCount - @cols; $i > 0; $i--) {
        push(@cols, "");
    }

    $values = \@cols;
}

while (my $line = <STDIN>) {
    $line =~ s/\r?\n\z//g;
    $line = decode_utf8($line);
    my @cols = split(/\t/, $line, -1);

    # 行にタブの数が少ない場合に列を付け足す
    for (my $i = $headerCount - @cols; $i > 0; $i--) {
        push(@cols, "");
    }
    for (my $i = 0; $i < $headerCount; $i++) {
        if (defined($values->[$i]) && $values->[$i] ne $cols[$i]) {
            $values->[$i] = undef;
        }
    }
}

my @buf = ();
for (my $i = 0; $i < $headerCount; $i++) {
    if (!defined($values->[$i])) {
        push(@buf, $headers->[$i]);
    }
}

if ($option_comma) {
    print encode_utf8(join(",", @buf)) . "\n";
} elsif ($option_col) {
    foreach my $b (@buf) {
        print "col " . escape_for_bash(encode_utf8($b)) . "\n";
    }
} else {
    foreach my $b (@buf) {
        print encode_utf8($b) . "\n";
    }
}

