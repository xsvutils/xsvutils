use strict;
use warnings;
use utf8;

my $option_columns = undef;

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "--col") {
        die "option --col needs an argument" unless (@ARGV);
        $option_columns = shift(@ARGV);
    } elsif ($a eq "--cols") {
        die "option --cols needs an argument" unless (@ARGV);
        $option_columns = shift(@ARGV);
    } elsif ($a eq "--columns") {
        die "option --columns needs an argument" unless (@ARGV);
        $option_columns = shift(@ARGV);
    } else {
        die "Unknown argument: $a";
    }
}

my $headers = undef;
my $headerCount = 0;

my $selectColumns = undef;

sub createSelectColumns {
    my ($headers) = @_;
    my @columns2 = split(/,/, $option_columns);
    my @columns3 = ();
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

    my $headerCount = @$headers;
    my @columns4 = ();
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

while (my $line = <STDIN>) {
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line);

    if (!defined($headers)) {
        $headers = \@cols;
        $headerCount = @cols;
        $selectColumns = createSelectColumns($headers);
        print join("\t", (map { $cols[$_] } @$selectColumns)) . "\n";
        next;
    }

    # 行にタブの数が少ない場合に列を付け足す
    for (my $i = $headerCount - @cols; $i > 0; $i--) {
        push(@cols, "");
    }

    print join("\t", (map { $cols[$_] } @$selectColumns)) . "\n";
}

