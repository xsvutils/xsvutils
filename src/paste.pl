use strict;
use warnings;
use utf8;

my $right_filepath = undef;

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "--right") {
        die "option --right needs an argument" unless (@ARGV);
        $right_filepath = shift(@ARGV);
    } else {
        die "Unknown argument: $a";
    }
}

die "subcommand `paste` requires option --right" unless defined $right_filepath;

my $left_header_count = undef;

open(my $right_in, '<', $right_filepath) or die $!;

while () {
    my $left_line = <STDIN>;
    my $right_line = <$right_in>;

    last if (!defined($left_line) && !defined($right_line));

    my @left_cols;
    if (defined($left_line)) {
        $left_line =~ s/\n\z//g;
        @left_cols = split(/\t/, $left_line, -1);
    } else {
        @left_cols = ();
        $left_line = "";
    }

    my @right_cols;
    if (defined($right_line)) {
        $right_line =~ s/\n\z//g;
        @right_cols = split(/\t/, $right_line, -1);
    } else {
        @right_cols = ();
        $right_line = "";
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

    print "$left_line\t$right_line\n";
}

close($right_in);

