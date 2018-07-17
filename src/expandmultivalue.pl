use strict;
use warnings;
use utf8;

my $target_col_name = undef;
my $multiValueFlag = '';

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "--multi-value-a") {
        $multiValueFlag = "a";
    } elsif ($a eq "--col") {
        die "option --col needs an argument" unless (@ARGV);
        $target_col_name = shift(@ARGV);
    } else {
        die "Unknown argument: $a";
    }
}

die "subcommand `expandmultivalue` requires option --col" unless defined $target_col_name;

if ($multiValueFlag ne 'a') {
    die "Unsupported multi-value: $multiValueFlag";
}

my $target_col_index = undef;

{
    my $line = <STDIN>;
    exit(1) unless defined($line);

    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    for (my $i = 0; $i < @cols; $i++) {
        if ($cols[$i] eq $target_col_name) {
            $target_col_index = $i;
            last;
        }
    }
    if (!defined($target_col_index)) {
        die "Column not found: $target_col_name\n";
    }

    print join("\t", @cols) . "\n";
}

while (my $line = <STDIN>) {
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    # 行にタブの数が少ない場合に列を付け足す
    for (my $i = $target_col_index - @cols; $i >= 0; $i--) {
        push(@cols, "");
    }

    my $value = $cols[$target_col_index];

    my @values;
    if ($multiValueFlag eq "a") {
        # TODO セミコロンのエスケープ解除

        if ($value eq "") {
            @values = ("");
        } else {
            @values = split(/;/, $value, -1);
            # $value が空文字列の場合は @values は大きさ0のリストになってしまう
        }
    }

    foreach my $v (@values) {
        $cols[$target_col_index] = $v;
        print join("\t", @cols) . "\n";
    }
}


