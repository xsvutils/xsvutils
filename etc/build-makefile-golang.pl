use strict;
use warnings;
use utf8;

my $GOLANG_SOURCE_DIR = "var/golang_packages/src/github.com/xsvutils/xsvutils";

my $sources = '';

foreach my $source (@ARGV) {
    die unless ($source =~ /^src\/(.+)\.go$/);
    my $source_name = $1;

    my $package_name = '';
    my $package_dir = '';

    open(my $fp, '<', $source) or die $!;
    while (my $line = <$fp>) {
        if ($line =~ /^package\s+([0-9a-z]+)\s*$/) {
            $package_name = $1;
            if ($package_name eq "main") {
                $package_dir = "";
            } else {
                $package_dir = "/$package_name";
            }
            last;
        }
    }
    close($fp);

    die if ($package_name eq '');

    print "$GOLANG_SOURCE_DIR$package_dir/$source_name.go: src/$source_name.go\n";
    print "\tmkdir -p $GOLANG_SOURCE_DIR$package_dir\n";
    print "\tcp src/$source_name.go $GOLANG_SOURCE_DIR$package_dir/$source_name.go\n";
    print "\n";

    $sources = $sources . " $GOLANG_SOURCE_DIR$package_dir/$source_name.go";
}

print "var/GOLANG_VERSION_HASH: $sources\n";
print "\tcat $sources | shasum | cut -b1-40 > var/GOLANG_VERSION_HASH.tmp\n";
print "\tmv var/GOLANG_VERSION_HASH.tmp var/GOLANG_VERSION_HASH\n";
print "\n";

