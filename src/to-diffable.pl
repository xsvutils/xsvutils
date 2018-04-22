use strict;
use warnings;
use utf8;

my @headers = ();
my $headerCount = 0;

{
    my $line = <STDIN>;
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

        print "$cols[0]\n";
    }
} else {
    while (my $line = <STDIN>) {
        $line =~ s/\n\z//g;
        my @cols = split(/\t/, $line, -1);

        my $id = $cols[0];

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

