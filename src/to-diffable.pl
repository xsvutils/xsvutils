use strict;
use warnings;
use utf8;

my @headers = ();
my $headerCount = 0;

{
    my $line = <STDIN>;
    exit(1) unless defined($line);

    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    @headers = @cols;
    $headerCount = @cols;

    foreach my $v (@cols) {
        print "$v\n";
    }
    print "\n";
}

if (@headers == 1) {
    while (my $line = <STDIN>) {
        $line =~ s/\n\z//g;
        my @cols = split(/\t/, $line, -1);

        if (@cols) {
            print "$cols[0]\n";
        } else {
            print "\n";
        }
    }
} else {
    while (my $line = <STDIN>) {
        $line =~ s/\n\z//g;
        my @cols = split(/\t/, $line, -1);

        my $id;
        if (@cols) {
            $id = $cols[0];
        } else {
            $id = "";
        }

        my $i = 1;
        while () {
            last if ($i >= @cols);
            my $h;
            if ($i < @headers) {
                $h = $headers[$i];
            } else {
                $h = "";
            }
            my $v = $cols[$i];
            print "$id:$h:$v\n";
            $i++;
        }
        print "\n";
    }
}

