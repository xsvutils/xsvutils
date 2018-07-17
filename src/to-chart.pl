use strict;
use warnings;
use utf8;

my $headers = ();
my $headerCount = 0;
my @records = ();

my $x_number_flag = 1;
my $x_integer_flag = 1;
my $x_prev = undef;
my $x_min = undef;
my $x_max = undef;

{
    my $line = <STDIN>;
    exit(1) unless defined($line);

    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    $headers = \@cols;
    $headerCount = @cols;
}

while (my $line = <STDIN>) {
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line, -1);

    # 行にタブの数が少ない場合に列を付け足す
    for (my $i = $headerCount - @cols; $i > 0; $i--) {
        push(@cols, "");
    }

    if ($x_number_flag) {
        my $v = $cols[0];
        if (defined($x_prev)) {
            if ($x_min >= $v) {
                $x_number_flag = '';
                $x_integer_flag = '';
            }
            $x_prev = $v;
            $x_max = $v;
        } else {
            $x_prev = $v;
            $x_min = $v;
            $x_max = $v;
        }
        if ($v =~ /\A *([0-9]+) *\z/) {
            # OK
        } elsif ($v =~ /\A *([0-9]+\.[0-9]*) *\z/) {
            $x_integer_flag = '';
        } elsif ($v =~ /\A *(\.[0-9]+) *\z/) {
            # OK
            $x_integer_flag = '';
        } else {
            $x_number_flag = '';
            $x_integer_flag = '';
        }
    }

    for (my $i = 1; $i < $headerCount; $i++) {
        my $v = $cols[$i];
        if ($v eq "") {
            $cols[$i] = 0;
        } elsif ($v =~ /\A *([0-9]+(\.[0-9]*)?)% *\z/) {
            $cols[$i] = $1 / 100;
        } elsif ($v =~ /\A *(\.[0-9]+)% *\z/) {
            $cols[$i] = $1 / 100;
        } elsif ($v =~ /\A *([0-9]+(\.[0-9]*)?) *\z/) {
            $cols[$i] = $1;
        } elsif ($v =~ /\A *(\.[0-9]+) *\z/) {
            $cols[$i] = "0.$1";
        } else {
            $cols[$i] = "0 /*$v*/";
        }
    }

    push(@records, \@cols);
}

foreach my $cols (@records) {
    if ($x_number_flag) {
        my $v = $cols->[0];
        if ($v =~ /\A *([0-9]+(\.[0-9]*)?) *\z/) {
            $cols->[0] = $1;
        } elsif ($v =~ /\A *(\.[0-9]+) *\z/) {
            $cols->[0] = "0.$1";
        }
    }
}

if (!defined($x_min)) {
    $x_number_flag = '';
    $x_integer_flag = '';
}

if ($x_integer_flag) {
    if ($x_max - $x_min > 300) {
        $x_integer_flag = '';
    }
}

if ($x_integer_flag) {
    my @records2 = ();
    my $prev = undef;
    foreach my $cols (@records) {
        my $x = $cols->[0];
        $prev++;
        while ($x > $prev) {
            my @cols2 = ($prev);
            for (my $i = 1; $i < $headerCount; $i++) {
                push(@cols2, 0);
            }
            push(@records2, \@cols2);
            $prev++;
        }
        push(@records2, $cols);
    }
    @records = @records2;
}

print <<'EOS';
<html>
<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/2.7.2/Chart.js"></script>
<body>

<div class="chart-container" style="position: relative;">
	<canvas id="chart" style="width: 100%; height:500px;"></canvas>
</div>

<script>
var ctx = document.getElementById("chart").getContext('2d');
var chart = new Chart(ctx, {
	type: 'line',
	data: {
EOS

print "\t\tlabels: [";
foreach my $r (@records) {
    print $r->[0];
    print ",";
}
print "],\n";
print "\t\tdatasets: [";

my @colors = (
    "rgba(244,67,54,0.8)",
    "rgba(33,150,243,0.8)",
    "rgba(139,195,74,0.8)",
    "rgba(255,193,7,0.8)",
    "rgba(96,125,139,0.8)",
    );

for (my $ci = 1; $ci < $headerCount; $ci++) {
    my $columnName = $headers->[$ci];
    my $color = $colors[($ci - 1) % @colors];
    print "{\n";
    print "\t\t\tlabel: \"$columnName\",\n"; # TODO escape
    print "\t\t\tdata: [";
    foreach my $r (@records) {
        my $value = $r->[$ci];
        print "$value, ";
    }
    print "],\n";
    print "\t\t\tbackgroundColor: \"$color\",\n";
    print "\t\t\tborderColor: \"$color\",\n";
    print "\t\t\tfill: false,\n";
    print "\t\t\tlineTension: 0,\n";
    print "\t\t}, ";
}
print "],\n";

print <<'EOS';
	},
	options: {
		responsive: true,
		maintainAspectRatio: false,
	},
});
</script>

</body>
</html>
EOS

