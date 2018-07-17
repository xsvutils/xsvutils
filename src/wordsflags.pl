use strict;
use warnings;
use utf8;

my $flags = [];

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a =~ /\A([_0-9a-zA-Z][-_0-9a-zA-Z]*)=(.*)\z/) {
        push(@$flags, [$1, $2]);
    } else {
        die "Unknown argument: $a";
    }
}

my $words = {};

# Ctrl-C で中断して結果を表示するためのハンドラ
my $interrupted = '';
sub interrupt {
    $interrupted = 1;
}
$SIG{INT} = \&interrupt;

{
    my $line = <STDIN>;
    exit(1) unless defined($line);

    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);
}

while (my $line = <STDIN>) {
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    # 行にタブの数が少ない場合に列を付け足す
    for (my $i = 2 - @cols; $i > 0; $i--) {
        push(@cols, "");
    }

    my $word = $cols[0];
    my $flag = $cols[1];

    if (!defined($words->{$word})) {
        my $r = [];
        for (my $i = 0; $i < @$flags; $i++) {
            push(@$r, 0);
        }
        $words->{$word} = [$word, 0, $r, []];
    }

    $words->{$word}->[1]++;
    my $g = 1;
    for (my $i = 0; $i < @$flags; $i++) {
        if ($flag eq $flags->[$i]->[1]) {
            $words->{$word}->[2]->[$i]++;
            $g = '';
            last;
        }
    }
    if ($g) {
        push(@{$words->{$word}->[3]}, $flag);
    }

    if ($interrupted) {
        last;
    }
}

print "word\tcount";
for (my $i = 0; $i < @$flags; $i++) {
    print "\t$flags->[$i]->[0]";
}
print "\tothers\n";

my @words2 = sort { my $r = $b->[1] <=> $a->[1]; if ($r == 0) { $r = $a->[0] cmp $b->[0]; } $r; } values(%$words);

foreach my $word (@words2) {
    print "$word->[0]\t$word->[1]";
    for (my $i = 0; $i < @$flags; $i++) {
        print "\t$word->[2]->[$i]";
    }
    print "\t";
    print join(",", @{$word->[3]});
    print "\n";
}

