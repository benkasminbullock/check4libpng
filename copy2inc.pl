#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use File::Copy;
use Deploy 'older';
my $dir = $ARGV[0];
if (! $dir) {
    die "Specify a directory on the command line";
}
if (! -d $dir) {
    die "$dir is not a directory";
}
my $file = 'CheckForLibPng.pm';
my $our = "$Bin/lib/$file";
die "No $our" unless -f $our;
my $their = "$dir/$file";
if (-f $their) {
    chmod 0644, $their or die $!;
}
if (older ($their, $our)) {
    copy $our, $their or die $!;
}
chmod 0444, $their or die $!;
exit;

