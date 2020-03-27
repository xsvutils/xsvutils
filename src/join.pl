use strict;
use warnings;
use utf8;

my $right_filepath = undef;
my $action = "inner";
my $option_number = "";

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "--other") {
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
    } elsif ($a eq "--number") {
        $option_number = 1;
    } else {
        die "Unknown argument: $a";
    }
}

die "subcommand `join` requires option --right" unless defined $right_filepath;

open(my $right_in, '<', $right_filepath) or die $!;

my $header_flag = 1;

my $left_header_count = undef;
my $right_header_count = undef;

my $left_line_dummy = undef;
my $right_line_dummy = undef;

my $left_line = undef;
my $right_line = undef;

my $left_id = undef;
my $right_id = undef;

my $left_eof = '';
my $right_eof = '';

my $pending_id = undef;
my @left_line_list = ();
my @right_line_list = ();

sub compareId {
    my ($left_id, $right_id) = @_;
    if (defined($left_id) && defined($right_id)) {
        if ($option_number) {
            return $left_id <=> $right_id;
        } else {
            return $left_id cmp $right_id;
        }
    } elsif (defined($left_id)) { # rightだけ最後に達している
        return -1;
    } elsif (defined($right_id)) { # leftだけ最後に達している
        return +1;
    } else {
        return 0;
    }
}

while () {
    if (!defined($left_line) && !$left_eof) {
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

        if ($header_flag) {
            $left_header_count = scalar @left_cols;
            $left_line_dummy = join("\t", (("") x $left_header_count));
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

    if (!defined($right_line) && !$right_eof) {
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

        if ($header_flag) {
            $right_header_count = scalar @right_cols;
            $right_line_dummy = join("\t", (("") x $right_header_count));
        }

        # カラム数統一はrightでは不要

        if ($right_eof) {
            $right_id = undef;
        } else {
            $right_id = $right_cols[0];
        }
    }

    if ($header_flag) {
        print "$left_line\t$right_line\n";
        $header_flag = undef;
        $left_line = undef;
        $right_line = undef;
        next;
    }

    if (defined($pending_id)) {
        my $cl = compareId($left_id, $pending_id);
        my $cr = compareId($right_id, $pending_id);
        if ($cl <= 0) {
            push(@left_line_list, $left_line);
            $left_line = undef;
        }
        if ($cr <= 0) {
            push(@right_line_list, $right_line);
            $right_line = undef;
        }
    } else {
        my $r = compareId($left_id, $right_id);
        if ($r < 0) {
            $pending_id = $left_id;
            push(@left_line_list, $left_line);
            $left_line = undef;
        } elsif ($r > 0) {
            $pending_id = $right_id;
            push(@right_line_list, $right_line);
            $right_line = undef;
        } else {
            $pending_id = $left_id;
            push(@left_line_list, $left_line);
            push(@right_line_list, $right_line);
            $left_line = undef;
            $right_line = undef;
        }
    }
    if (defined($left_id) && !defined($left_line) || defined($right_id) && !defined($right_line)) {
        next;
    }

    if (!@left_line_list) {
        if ($action eq "right-outer" || $action eq "full-outer") {
            foreach my $r (@right_line_list) {
                print "$left_line_dummy\t$r\n";
            }
        }
    } elsif (!@right_line_list) {
        if ($action eq "left-outer" || $action eq "full-outer") {
            foreach my $l (@left_line_list) {
                print "$l\t$right_line_dummy\n";
            }
        }
    } else {
        foreach my $l (@left_line_list) {
            foreach my $r (@right_line_list) {
                print "$l\t$r\n";
            }
        }
    }
    $pending_id = undef;
    @left_line_list = ();
    @right_line_list = ();

    last if ($left_eof && $right_eof);
}

close($right_in);

