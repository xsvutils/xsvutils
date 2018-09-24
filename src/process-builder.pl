use strict;
use warnings;
use utf8;

use POSIX qw/mkfifo/;

my $TOOL_DIR = $ENV{"TOOL_DIR"};
my $WORKING_DIR = $ENV{"WORKING_DIR"};
my $isInputTty = undef;
my $isOutputTty = undef;
if (-t STDIN) {
    $isInputTty = 1;
}
if (-t STDOUT) {
    $isOutputTty = 1;
}

my $verbose = '';

my $fromParser = undef;
my $toParser   = undef;

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "--verbose") {
        $verbose = 1;
    } elsif (!defined($fromParser)) {
        $fromParser = $a;
    } elsif (!defined($toParser)) {
        $toParser = $a;
    } else {
        die "Unknown argument: $a";
    }
}

open(my $toParserFh,   '>', $toParser  ) or die $!;
open(my $fromParserFh, '<', $fromParser) or die $!;
my $tmpFh = select($toParserFh);
$| = 1;
select($toParserFh);

sub execLine {
    my ($line) = @_;

    if ($line eq '') {
        return 0;
    }

    my $background = '';
    if ($line =~ /&\z/) {
        $background = 1;
        $line =~ s/&\z//g;
    }

    if ($line eq "wait") {
        while () {
            my $pid = wait;
            last if ($pid < 0);
        }
        return "";
    }

    if ($line eq "--stdin") {
        mkfifo("$WORKING_DIR/stdin", 0600) or die $!;

        my $pid1 = fork;
        if (!defined $pid1) {
            die $!;
        } elsif ($pid1) {
            # parent process
        } else {
            # child process
            open(my $out_fh, '>', "$WORKING_DIR/stdin") or die $!;
            open(STDOUT, '>&=', fileno($out_fh));
            exec("cat");
        }

        return 0;
    }
    if ($line eq "--stdout") {
        mkfifo("$WORKING_DIR/stdout", 0600) or die $!;

        my $pid1 = fork;
        if (!defined $pid1) {
            die $!;
        } elsif ($pid1) {
            # parent process
        } else {
            # child process
            open(my $in_fh, '<', "$WORKING_DIR/stdout") or die $!;
            open(STDIN, '<&=', fileno($in_fh));
            exec("cat");
        }

        return 0;
    }

    my $pid1 = fork;
    if (!defined $pid1) {
        die $!;
    } elsif ($pid1) {
        # parent process

    } else {
        # child process
        if ($verbose) {
            print STDERR "$line\n";
        }
        open(STDIN, '<', "/dev/null");
        if ($line !~ /\Aless /) {
            open(STDOUT, '>', "/dev/null");
        }
        exec($line);
    }

    my $result;
    if ($background) {
        $result = 0;
    } else {
        while () {
            my $pid2 = wait;
            last if ($pid2 == $pid1);
        }
        $result = $?;
    }

    return $result;
}

my $num = 0;
while () {
    my $line = <$fromParserFh>;
    last if (!defined($line));
    $line =~ s/\n\z//g;

    my $result = execLine($line);
    if ($result eq "") {
        last;
    }
    print $toParserFh "$result\n";

    $num++;
}

