use strict;
use warnings;
use utf8;
use Encode qw/encode_utf8/;

print encode_utf8(<<'EOS');
<script src="https://www.amcharts.com/lib/4/core.js"></script>
<script src="https://www.amcharts.com/lib/4/charts.js"></script>
<script src="https://www.amcharts.com/lib/4/themes/animated.js"></script>

<!-- Chart code -->
<script>
am4core.ready(function() {

// Themes begin
am4core.useTheme(am4themes_animated);
// Themes end

var chart = am4core.create("chartdiv", am4charts.XYChart);

chart.dateFormatter.inputDateFormat = "i";
chart.dateFormatter.dateFormat = "i";

var data = [];

EOS


my $headers = undef;
my $headerCount = 0;

{
    my $line = <STDIN>;
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line);
    $headers = \@cols;
    $headerCount = @cols;
}


while (my $line = <STDIN>) {
    $line =~ s/\n\z//g;
    my @cols = split(/\t/, $line);
    my $dt = $cols[0];
    #$dt =~ s/\A([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])T([0-9][0-9]:[0-9][0-9]:[0-9][0-9])\z/$1 $2/g;
    #$dt = $dt . "Z";
    my $str = "date: \"$dt\"";
    for (my $i = 1; $i < $headerCount; $i++) {
        $str .= ", " . $headers->[$i] . ": \"" . $cols[$i] . "\"";
    }
    print "data.push({$str})\n";
}


print encode_utf8(<<'EOS');

chart.data = data;

// Create axes
var dateAxis = chart.xAxes.push(new am4charts.DateAxis());
dateAxis.renderer.minGridDistance = 60;
dateAxis.tooltipDateFormat = "i";

EOS

for (my $i = 1; $i < $headerCount; $i++) {
    my $colName = $headers->[$i];
print encode_utf8(<<"EOS");

var valueAxis$i = chart.yAxes.push(new am4charts.ValueAxis());

// Create series
var series$i = chart.series.push(new am4charts.LineSeries());
series$i.dataFields.valueY = "$colName";
series$i.dataFields.dateX = "date";
series$i.tooltipText = "{valueY}";
series$i.yAxis = valueAxis$i;

series$i.tooltip.pointerOrientation = "vertical";

EOS
}

print encode_utf8(<<'EOS');

chart.cursor = new am4charts.XYCursor();
chart.cursor.snapToSeries = series1;
chart.cursor.xAxis = dateAxis;

//chart.scrollbarY = new am4core.Scrollbar();
chart.scrollbarX = new am4core.Scrollbar();

}); // end am4core.ready()
</script>

<!-- HTML -->
<div id="chartdiv"></div>
EOS



