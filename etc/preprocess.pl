use strict;
use warnings;
use utf8;

my $platform = $ARGV[0];

my @stack = ();

sub isMatch {
    my ($cond) = @_;
    if ($cond eq $platform) {
        return 1;
    } else {
        return '';
    }
}

while (my $line = <STDIN>) {
    $line =~ s/\n\z//g;
    my $output = '';
    if ($line =~ /\A\s*#if\s+([\sa-zA-Z0-9]+)\s*\z/) {
        my $cond = $1;
        if (@stack && $stack[0]) {
            unshift(@stack, '');
        } else {
            unshift(@stack, isMatch($cond));
        }
    } elsif ($line =~ /\A\s*#else\s*\z/) {
        if (shift(@stack)) {
            unshift(@stack, '');
        } else {
            unshift(@stack, 1);
        }
    } elsif ($line =~ /\A\s*#endif\s*\z/) {
        shift(@stack);
    } else {
        if (!@stack || $stack[0]) {
            $output = $line;
        }
    }
    print $output . "\n";
}
