use strict;
use warnings;
use utf8;

my $name = undef;
my $src_column_name = undef;
my $mapping_file = undef;
my $default_value = undef;

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "--name") {
        die "option --name needs an argument" unless (@ARGV);
        $name = shift(@ARGV);
    } elsif ($a eq "--src") {
        die "option --src needs an argument" unless (@ARGV);
        $src_column_name = shift(@ARGV);
    } elsif ($a eq "--file") {
        die "option --file needs an argument" unless (@ARGV);
        $mapping_file = shift(@ARGV);
    } elsif ($a eq "--default") {
        die "option --default needs an argument" unless (@ARGV);
        $default_value = shift(@ARGV);
    } else {
        die "Unknown argument: $a";
    }
}

die "subcommand `addmap` requires option --name" unless defined $name;
die "subcommand `addmap` requires option --src" unless defined $src_column_name;
die "subcommand `addmap` requires option --file" unless defined $mapping_file;

my $mapping = {};

open(my $mapping_fh, '<', $mapping_file) or die $!;

{
    # skip header line
    my $line = <$mapping_fh>;
}
while (my $line = <$mapping_fh>) {
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    for (my $i = 2 - @cols; $i > 0; $i--) {
        push(@cols, "");
    }

    $mapping->{$cols[0]} = $cols[1];
}

close($mapping_fh);


my $headers = undef;
my $src_column_index = undef;

{
    my $line = <STDIN>;
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    $headers = \@cols;


    for (my $i = 0; $i < @$headers; $i++) {
        if ($headers->[$i] eq $src_column_name) {
            $src_column_index = $i;
            last;
        }
    }
    if (!defined($src_column_index)) {
        die "Column not found: $src_column_name\n";
    }

    unshift(@cols, $name);
    print join("\t", @cols) . "\n";
}

while (my $line = <STDIN>) {
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    my $value = "";
    if (defined($cols[$src_column_index])) {
        $value = $cols[$src_column_index];
    }
    if (defined($mapping->{$value})) {
        $value = $mapping->{$value};
    } elsif (defined($default_value)) {
        $value = $default_value;
    }

    unshift(@cols, $value);
    print join("\t", @cols) . "\n";
}


