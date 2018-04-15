use strict;
use warnings;
use utf8;

my $colname = undef;
my $operator = undef;
my $value = undef;

if (@ARGV >= 3) {
    $colname = $ARGV[0];
    $operator = $ARGV[1];
    $value = $ARGV[2];
} else {
    die "subcommand `where` requires condition";
}

my $headers = undef;
my $header_count = 0;

my $colindex = undef;

{
    my $line = <STDIN>;
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    $headers = \@cols;
    $header_count = scalar @cols;

    my $f = 1;
    for (my $j = 0; $j < $header_count; $j++) {
        if ($headers->[$j] eq $colname) {
            $colindex = $j;
            $f = '';
            last;
        }
    }
    if ($f) {
        die "Unknown column name: $colname\n";
    }

    print $line . "\n";
}

if ($operator eq '==') {
    while (my $line = <STDIN>) {
        $line =~ s/\n\z//g;
        my @cols = split(/\t/, $line, -1);

        # 行にタブの数が少ない場合に列を付け足す
        for (my $i = $header_count - @cols; $i > 0; $i--) {
            push(@cols, "");
        }

        if ($cols[$colindex] == $value) {
            print $line . "\n";
        }
    }
} elsif ($operator eq '!=') {
    while (my $line = <STDIN>) {
        $line =~ s/\n\z//g;
        my @cols = split(/\t/, $line, -1);

        # 行にタブの数が少ない場合に列を付け足す
        for (my $i = $header_count - @cols; $i > 0; $i--) {
            push(@cols, "");
        }

        if ($cols[$colindex] != $value) {
            print $line . "\n";
        }
    }
} elsif ($operator eq '>') {
    while (my $line = <STDIN>) {
        $line =~ s/\n\z//g;
        my @cols = split(/\t/, $line, -1);

        # 行にタブの数が少ない場合に列を付け足す
        for (my $i = $header_count - @cols; $i > 0; $i--) {
            push(@cols, "");
        }

        if ($cols[$colindex] > $value) {
            print $line . "\n";
        }
    }
} elsif ($operator eq '>=') {
    while (my $line = <STDIN>) {
        $line =~ s/\n\z//g;
        my @cols = split(/\t/, $line, -1);

        # 行にタブの数が少ない場合に列を付け足す
        for (my $i = $header_count - @cols; $i > 0; $i--) {
            push(@cols, "");
        }

        if ($cols[$colindex] >= $value) {
            print $line . "\n";
        }
    }
} elsif ($operator eq '<') {
    while (my $line = <STDIN>) {
        $line =~ s/\n\z//g;
        my @cols = split(/\t/, $line, -1);

        # 行にタブの数が少ない場合に列を付け足す
        for (my $i = $header_count - @cols; $i > 0; $i--) {
            push(@cols, "");
        }

        if ($cols[$colindex] < $value) {
            print $line . "\n";
        }
    }
} elsif ($operator eq '<=') {
    while (my $line = <STDIN>) {
        $line =~ s/\n\z//g;
        my @cols = split(/\t/, $line, -1);

        # 行にタブの数が少ない場合に列を付け足す
        for (my $i = $header_count - @cols; $i > 0; $i--) {
            push(@cols, "");
        }

        if ($cols[$colindex] <= $value) {
            print $line . "\n";
        }
    }
} elsif ($operator eq 'eq') {
    while (my $line = <STDIN>) {
        $line =~ s/\n\z//g;
        my @cols = split(/\t/, $line, -1);

        # 行にタブの数が少ない場合に列を付け足す
        for (my $i = $header_count - @cols; $i > 0; $i--) {
            push(@cols, "");
        }

        if ($cols[$colindex] eq $value) {
            print $line . "\n";
        }
    }
} elsif ($operator eq 'ne') {
    while (my $line = <STDIN>) {
        $line =~ s/\n\z//g;
        my @cols = split(/\t/, $line, -1);

        # 行にタブの数が少ない場合に列を付け足す
        for (my $i = $header_count - @cols; $i > 0; $i--) {
            push(@cols, "");
        }

        if ($cols[$colindex] ne $value) {
            print $line . "\n";
        }
    }
} elsif ($operator eq 'gt') {
    while (my $line = <STDIN>) {
        $line =~ s/\n\z//g;
        my @cols = split(/\t/, $line, -1);

        # 行にタブの数が少ない場合に列を付け足す
        for (my $i = $header_count - @cols; $i > 0; $i--) {
            push(@cols, "");
        }

        if ($cols[$colindex] gt $value) {
            print $line . "\n";
        }
    }
} elsif ($operator eq 'ge') {
    while (my $line = <STDIN>) {
        $line =~ s/\n\z//g;
        my @cols = split(/\t/, $line, -1);

        # 行にタブの数が少ない場合に列を付け足す
        for (my $i = $header_count - @cols; $i > 0; $i--) {
            push(@cols, "");
        }

        if ($cols[$colindex] ge $value) {
            print $line . "\n";
        }
    }
} elsif ($operator eq 'lt') {
    while (my $line = <STDIN>) {
        $line =~ s/\n\z//g;
        my @cols = split(/\t/, $line, -1);

        # 行にタブの数が少ない場合に列を付け足す
        for (my $i = $header_count - @cols; $i > 0; $i--) {
            push(@cols, "");
        }

        if ($cols[$colindex] lt $value) {
            print $line . "\n";
        }
    }
} elsif ($operator eq 'le') {
    while (my $line = <STDIN>) {
        $line =~ s/\n\z//g;
        my @cols = split(/\t/, $line, -1);

        # 行にタブの数が少ない場合に列を付け足す
        for (my $i = $header_count - @cols; $i > 0; $i--) {
            push(@cols, "");
        }

        if ($cols[$colindex] le $value) {
            print $line . "\n";
        }
    }
}

