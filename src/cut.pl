use strict;
use warnings;
use utf8;

my $option_fields = undef;

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "--fields") {
        die "option --fields needs an argument" unless (@ARGV);
        $option_fields = shift(@ARGV);
    } else {
        die "Unknown argument: $a";
    }
}

my $headers = undef;
my $headerCount = 0;

my $selectColumns = undef;

sub createSelectColumns {
    my ($headers) = @_;
    my @fields2 = split(/,/, $option_fields);
    my @fields3 = ();
    foreach my $f (@fields2) {
        if ($f =~ /\A([.+?])\.\.([.+])\z/) {
            my $f1 = $1;
            my $f2 = $2;
            if ($f1 =~ /\A([.+])(0|[1-9][0-9]*)\z/) {
                my $f1name = $1;
                my $f1num = $2;
                if ($f2 =~ /\A([.+])(0|[1-9][0-9]*)\z/) {
                    my $f2name = $1;
                    my $f2num = $2;
                    if ($f1name eq $f2name) {
                        if ($f1num <= $f2num) {
                            for (my $i = $f1num; $i <= $f2num; $i++) {
                                push(@fields3, "$f1name$i");
                            }
                        } else {
                            for (my $i = $f1num; $i >= $f2num; $i--) {
                                push(@fields3, "$f1name$i");
                            }
                        }
                        next;
                    }
                }
            }
        }
        push(@fields3, $f);
    }

    my $headerCount = @$headers;
    my @fields4 = ();
    foreach my $f (@fields3) {
        my $g = '';
        for (my $i = 0; $i < $headerCount; $i++) {
            if ($headers->[$i] eq $f) {
                push(@fields4, $i);
                $g = 1;
                last;
            }
        }
        unless ($g) {
            print STDERR "Unknown field: $f\n";
        }
    }
    unless (@fields4) {
        die "Fields not specified.";
    }
    return \@fields4;

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

