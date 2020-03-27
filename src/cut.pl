use strict;
use warnings;
use utf8;

my $option_columns = undef;
my $option_columns2 = [];
my $option_head = undef;
my $option_last = undef;
my $option_remove = undef;
my $option_update = '';

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "--col") {
        die "option --col needs an argument" unless (@ARGV);
        push(@$option_columns2, shift(@ARGV));
    } elsif ($a eq "--cols") {
        die "option --cols needs an argument" unless (@ARGV);
        $option_columns = shift(@ARGV);
    } elsif ($a eq "--head") {
        die "option --head needs an argument" unless (@ARGV);
        $option_head = shift(@ARGV);
    } elsif ($a eq "--last") {
        die "option --last needs an argument" unless (@ARGV);
        $option_last = shift(@ARGV);
    } elsif ($a eq "--remove") {
        die "option --remove needs an argument" unless (@ARGV);
        $option_remove = shift(@ARGV);
    } elsif ($a eq "--left-update") {
        $option_update = "left";
    } elsif ($a eq "--right-update") {
        $option_update = "right";
    } else {
        die "Unknown argument: $a";
    }
}

sub createColumnIndeces {
    my ($headers) = @_;
    my $headerCount = @$headers;

    my @columnLastIndeces = ();
    if (defined($option_last) && $option_last ne "") {
        push(@columnLastIndeces, @{createColumnIndecesSub($headers, $option_last)});
    }

    my @columnRemoveIndeces = ();
    if (defined($option_remove) && $option_remove ne "") {
        push(@columnRemoveIndeces, @{createColumnIndecesSub($headers, $option_remove)});
    }

    my @columnIndeces = ();
    if (defined($option_head) && $option_head ne "") {
        push(@columnIndeces, @{createColumnIndecesSub($headers, $option_head)});
    }
    push(@columnIndeces, @{createColumnIndecesSubSimple($headers, $option_columns2)});
    if (defined($option_columns) && $option_columns ne "") {
        push(@columnIndeces, @{createColumnIndecesSub($headers, $option_columns)});
    }
    if (!@$option_columns2 && (!defined($option_columns) || $option_columns eq "")) {
        for (my $i = 0; $i < $headerCount; $i++) {
            if (!grep {$_ == $i} @columnIndeces) {
                if (!grep {$_ == $i} @columnLastIndeces) {
                    push(@columnIndeces, $i);
                }
            }
        }
    }
    push(@columnIndeces, @columnLastIndeces);

    {
        my @columnIndeces2 = ();
        for (my $i = 0; $i < @columnIndeces; $i++) {
            my $hi = $columnIndeces[$i];
            if (!grep {$_ eq $hi} @columnRemoveIndeces) {
                push(@columnIndeces2, $hi);
            }
        }
        @columnIndeces = @columnIndeces2;
    }

    if ($option_update) {
        my @columnIndeces2 = ();
        my @c = ();
        for (my $i = 0; $i < @columnIndeces; $i++) {
            my $hi = $columnIndeces[$i];
            my $h = $headers->[$hi];
            if ($option_update eq "left") {
                if (!grep {$_ eq $h} @c) {
                    push(@columnIndeces2, $hi);
                    push(@c, $h);
                }
            } elsif ($option_update eq "right") {
                my $f = 1;
                for (my $j = 0; $j < @columnIndeces2; $j++) {
                    my $h2 = $c[$j];
                    if ($h eq $h2) {
                        $columnIndeces2[$j] = $hi;
                        $f = '';
                        last;
                    }
                }
                if ($f) {
                    push(@columnIndeces2, $hi);
                    push(@c, $h);
                }
            }
        }
        @columnIndeces = @columnIndeces2;
    }

    \@columnIndeces;
}

sub createColumnIndecesSub {
    my ($headers, $option_columns) = @_;
    my $headerCount = @$headers;
    my @columns2 = split(/,/, $option_columns);
    my @columns3 = (); # カラム名の配列
    foreach my $f (@columns2) {
        if ($f =~ /\A(.+?)\.\.(.+)\z/) {
            my $f1 = $1;
            my $f2 = $2;
            if ($f1 =~ /\A(.+)(0|[1-9][0-9]*)\z/) {
                my $f1name = $1;
                my $f1num = $2;
                if ($f2 =~ /\A(.+)(0|[1-9][0-9]*)\z/) {
                    my $f2name = $1;
                    my $f2num = $2;
                    if ($f1name eq $f2name) {
                        # col1..col20 の形式
                        if ($f1num <= $f2num) {
                            for (my $i = $f1num; $i <= $f2num; $i++) {
                                push(@columns3, "$f1name$i");
                            }
                        } else {
                            for (my $i = $f1num; $i >= $f2num; $i--) {
                                push(@columns3, "$f1name$i");
                            }
                        }
                        next;
                    }
                }
            }
        }
        push(@columns3, $f);
    }

    my @columns4 = (); # インデックスの配列
    foreach my $f (@columns3) {
        my $g = '';
        for (my $i = 0; $i < $headerCount; $i++) {
            if ($headers->[$i] eq $f) {
                push(@columns4, $i);
                $g = 1;
                last;
            }
        }
        unless ($g) {
            print STDERR "Unknown column: $f\n";
        }
    }
    unless (@columns4) {
        die "Columns not specified.";
    }
    return \@columns4;

}

sub createColumnIndecesSubSimple {
    my ($headers, $option_columns) = @_;
    my $headerCount = @$headers;

    my @columns4 = (); # インデックスの配列
    foreach my $f (@$option_columns) {
        my $g = '';
        for (my $i = 0; $i < $headerCount; $i++) {
            if ($headers->[$i] eq $f) {
                push(@columns4, $i);
                $g = 1;
                last;
            }
        }
        unless ($g) {
            print STDERR "Unknown column: $f\n";
        }
    }
    return \@columns4;

}

my $headers = undef;
my $headerCount = 0;
my $columnIndeces = undef;

{
    my $line = <STDIN>;
    exit(1) unless defined($line);

    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    $headers = \@cols;
    $headerCount = @cols;
    $columnIndeces = createColumnIndeces($headers);
    print join("\t", (map { $cols[$_] } @$columnIndeces)) . "\n";
}

while (my $line = <STDIN>) {
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    # 行にタブの数が少ない場合に列を付け足す
    for (my $i = $headerCount - @cols; $i > 0; $i--) {
        push(@cols, "");
    }

    print join("\t", (map { $cols[$_] } @$columnIndeces)) . "\n";
}

