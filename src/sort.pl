use strict;
use warnings;
use utf8;

my @sort_keys = ();

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "--col") {
        my $b = shift(@ARGV);
        if ($b =~ /\A([nr]*):(.+)\z/) {
            push(@sort_keys, [$2, $1]);
        } else {
            die "Illegal parameter: $b";
        }
    } else {
        die "Unknown argument: $a";
    }
}

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

my @sort_options = ();

{
    my $line = $header;
    my @cols = split(/\t/, $line, -1);

    foreach my $k (@sort_keys) {
        for (my $i = 0; $i < @cols; $i++) {
            if ($k->[0] eq $cols[$i]) {
                my $num = $i + 1;
                my $flag = $k->[1];
                push(@sort_options, "-k");
                push(@sort_options, "$num$flag,$num");
                last;
            }
        }
    }

}

syswrite(STDOUT, $header . "\n");

my $CHILD1_READER;
my $PARENT_WRITER;
pipe($CHILD1_READER, $PARENT_WRITER);
my $pid1 = fork;
if (!defined $pid1) {
    die $!;
} elsif ($pid1) {
    # parent process
    close $PARENT_WRITER;
    open(STDIN, '<&=', fileno($CHILD1_READER));
    exec("sort", "-t", "\t", "-s", @sort_options);
} else {
    # child process
    close($CHILD1_READER);
    open(STDOUT, '>&=', fileno($PARENT_WRITER));
    syswrite(STDOUT, $body);
    exec("cat");
}

