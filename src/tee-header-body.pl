use strict;
use warnings;
use utf8;

my $header_filepath = undef;

while (@ARGV) {
    my $a = shift(@ARGV);
    if (!defined($header_filepath)) {
        $header_filepath = $a;
    } else {
        die "Unknown argument: $a";
    }
}

die "tee-header-body.pl requires argument" unless defined $header_filepath;

my $in = *STDIN;

my $head_unit_size = 4096;
my $head_buf = "";
my $exists_lf = '';

while () {
    my $head_buf2;
    my $l = sysread($in, $head_buf2, $head_unit_size);
    if ($l == 0) {
        last;
    }
    $head_buf .= $head_buf2;
    if ($head_buf2 =~ /\n/) {
        $exists_lf = 1;
        last;
    }
}

my $header;
my $body;
if ($head_buf =~ /\A([^\n]*)\n(.*)\z/s) {
    $header = $1;
    $body = $2;
} else {
    $header = $head_buf;
    $body = '';
}

open(my $header_fp, ">", $header_filepath) or die $!;
syswrite($header_fp, $header);
close($header_fp);

syswrite(STDOUT, $body . "\n");

exec("cat");

