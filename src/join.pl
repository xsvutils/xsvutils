use strict;
use warnings;
use utf8;

my $right_filepath = undef;
my $action = "inner";

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "--right") {
        die "option --right needs an argument" unless (@ARGV);
        $right_filepath = shift(@ARGV);
    } elsif ($a eq "--inner") {
        $action = "inner";
    } elsif ($a eq "--left-outer") {
        $action = "left-outer";
    } elsif ($a eq "--right-outer") {
        $action = "right-outer";
    } elsif ($a eq "--full-outer") {
        $action = "full-outer";
    } else {
        die "Unknown argument: $a";
    }
}

die "subcommand `join` requires option --right" unless defined $right_filepath;

open(my $right_in, '<', $right_filepath) or die $!;

my $left_header_count = undef;

my $left_line = undef;
my $right_line = undef;

my $left_id = undef;
my $right_id = undef;

while () {
    my $header_flag = '';
    if (!defined($left_header_count)) {
        $header_flag = 1;
    }

    my $left_eof = '';
    my $right_eof = '';

    if (!defined($left_line)) {
        $left_line = <STDIN>;

        my @left_cols;
        if (defined($left_line)) {
            $left_line =~ s/\n\z//g;
            @left_cols = split(/\t/, $left_line, -1);
        } else {
            @left_cols = ();
            $left_line = "";
            $left_eof = 1;
        }

        if (!defined($left_header_count)) {
            $left_header_count = scalar @left_cols;
        }

        # カラム数を統一する
        if (@left_cols < $left_header_count) {
            push(@left_cols, "");
            while (@left_cols < $left_header_count) {
                push(@left_cols, "");
            }
            $left_line = join("\t", @left_cols);
        } elsif (@left_cols > $left_header_count) {
            pop(@left_cols);
            while (@left_cols > $left_header_count) {
                pop(@left_cols);
            }
            $left_line = join("\t", @left_cols);
        }

        if ($left_eof) {
            $left_id = undef;
        } else {
            $left_id = $left_cols[0];
        }
    }

    if (!defined($right_line)) {
        $right_line = <$right_in>;

        my @right_cols;
        if (defined($right_line)) {
            $right_line =~ s/\n\z//g;
            @right_cols = split(/\t/, $right_line, -1);
        } else {
            @right_cols = ();
            $right_line = "";
            $right_eof = 1;
        }

        if ($right_eof) {
            $right_id = undef;
        } else {
            $right_id = $right_cols[0];
        }
    }

    last if ($left_eof && $right_eof);

    if ($header_flag) {
        print "$left_line\t$right_line\n";
        $left_line = undef;
        $right_line = undef;
        next;
    }

    my $r;
    if (defined($left_id) && defined($right_id)) {
        $r = $left_id cmp $right_id;
    } elsif (defined($left_id)) {
        $r = -1;
    } elsif (defined($right_id)) {
        $r = +1;
    } else {
        $r = 0;
    }

    if ($action eq "inner") {
        if ($r == 0) {
            print "$left_line\t$right_line\n";
            $left_line = undef;
            $right_line = undef;
        } elsif ($r > 0) {
            $right_line = undef;
        } else {
            $left_line = undef;
        }
    } elsif ($action eq "left-outer") {
        if ($r == 0) {
            print "$left_line\t$right_line\n";
            $left_line = undef;
            $right_line = undef;
        } elsif ($r > 0) {
            $right_line = undef;
        } else {
            my $right_line = "";
            print "$left_line\t$right_line\n";
            $left_line = undef;
        }
    } elsif ($action eq "right-outer") {
        if ($r == 0) {
            print "$left_line\t$right_line\n";
            $left_line = undef;
            $right_line = undef;
        } elsif ($r > 0) {
            my @left_cols = ("") x $left_header_count;
            $left_cols[0] = $right_id;
            my $left_line = join("\t", @left_cols);
            print "$left_line\t$right_line\n";
            $right_line = undef;
        } else {
            $left_line = undef;
        }
    } elsif ($action eq "full-outer") {
        if ($r == 0) {
            print "$left_line\t$right_line\n";
            $left_line = undef;
            $right_line = undef;
        } elsif ($r > 0) {
            my @left_cols = ("") x $left_header_count;
            $left_cols[0] = $right_id;
            my $left_line = join("\t", @left_cols);
            print "$left_line\t$right_line\n";
            $right_line = undef;
        } else {
            my $right_line = "";
            print "$left_line\t$right_line\n";
            $left_line = undef;
        }
    }
}

close($right_in);

