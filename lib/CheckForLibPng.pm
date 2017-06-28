package CheckForLibPng;
use parent Exporter;
our @EXPORT = qw/check_for_libpng/;
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Carp;

# This uses $Config{ldflags} and $Config{ccflags} when it tries to
# compile a small program which links against libpng.

use Config qw/%Config/;

# If the test compilation doesn't work, edit the following two lines
# to point to your libpng library's location and the location of the
# file "png.h".

my $png_lib_dir;
my $png_include_dir;

sub check_for_libpng
{

    # The following variable switches on printing of non-error messages

    my $verbose;		# = 1;

    # $inc is a flag for the C compiler to tell it where to find header
    # files.

    my $inc = '';
    if ($png_include_dir) {
	$inc = "-I $png_include_dir";
    }

    # $libs is a flag for the C compiler to tell it where to find library
    # files.

    my $libs = '-lpng -lz -lm';
    if ($png_lib_dir) {
	$libs = "-L $png_lib_dir $libs";
    }
    my $has_pkg_config = find_program ('pkg-config', $verbose);
    if ($has_pkg_config) {
	if ($verbose) {
	    print <<EOF;

I found "pkg-config" in your PATH so I am going to use that to help
with the compilation of the C part of this module.

EOF
	}
	my $pkg_config_cflags = `pkg-config --cflags libpng`;
	$pkg_config_cflags =~ s/\s+$//;
	my $pkg_config_ldflags = `pkg-config --libs libpng`;
	$pkg_config_ldflags =~ s/\s+$//;
	if ($pkg_config_cflags) {
	    if ($verbose) {
		print "Adding '$pkg_config_cflags' to C compiler flags from pkg-config.\n";
	    }
	    $inc = "$inc $pkg_config_cflags";
	}
	if ($pkg_config_ldflags) {
	    if ($verbose) {
		print "Adding '$pkg_config_ldflags' to linker flags from pkg-config.\n";
	    }
	    $libs = "$pkg_config_ldflags $libs";
	}
    }

    # A minimal C program to test compilation and running.

    my $test_c = <<'EOF';
#include <stdlib.h>
#include <stdio.h>
#include "png.h"
void failburger (const char * message)
{
    fprintf (stderr, "%s.\n", message);
    exit (1);
}

int main ()
{
   png_structp png_ptr;
   png_infop info_ptr;
   FILE * file;
   png_uint_32 libpng_vn = png_access_version_number();
   printf ("IMAGE-PNG LIBPNG VERSION: <<%s>>\n", png_get_libpng_ver (0));
   /* Create a file because there are some CPAN testers who seem to have bogus libpngs. */
/*   file = fopen ("temporary.png", "wb");
   if (! file) {
       failburger ("cannot open file");
   }*/
   png_ptr = png_create_write_struct (PNG_LIBPNG_VER_STRING, 0, 0, 0);
   if (! png_ptr) {
       failburger ("cannot create write struct");
   }
   info_ptr = png_create_info_struct (png_ptr);
   if (! png_ptr) {
       failburger ("cannot create info struct");
   }
//   png_init_io (png_ptr, file);
   return 0;
}
EOF

    # The name of our test program.

    my $exe_file_name = 'png-compile-test';
    my $c_file_name = "$exe_file_name.c";

    # Booleans which record whether our test program could be compiled and
    # run. The default is false.

    my $compile_ok;
    my $run_ok;

    if (! -f $c_file_name && ! -f $exe_file_name) {
	if ($verbose) {
	    print "\nI am going to compile and run a test program called '$c_file_name'.\n";
	}
	# Get $ldflags and $ccflags from Config.pm.
	my $ldflags = $Config{ldflags};
	#    my $ccflags;
	my $ccflags = $Config{ccflags};
	open my $output, ">", $c_file_name
        or die "Error opening file '$c_file_name' for writing: $!";
	print $output $test_c;
	close $output
        or die "Error closing file '$c_file_name': $!";
	my $compile = "cc $ccflags $inc -o $exe_file_name $c_file_name $ldflags $libs";
	if ($verbose) {
	    print "The compile command is '$compile'.\n";
	}
	$compile_ok =
        (system ($compile) == 0);
	if ($compile_ok) {
	    $run_ok = 
            (system ("./$exe_file_name") == 0);
	}
	for my $file ($exe_file_name, $c_file_name) {
	    if (-f $file) {
		unlink $file
                or print STDERR <<EOF;
Sorry, but I could not delete a temporary file '$file' 
which I made. Please delete it yourself.
EOF
	    }
	}
    }
    else {
	print STDERR <<'EOF';
 _____ _ _                                   
|  ___(_) | ___   _ __   __ _ _ __ ___   ___ 
| |_  | | |/ _ \ | '_ \ / _` | '_ ` _ \ / _ \
|  _| | | |  __/ | | | | (_| | | | | | |  __/
|_|   |_|_|\___| |_| |_|\__,_|_| |_| |_|\___|
                                           
           _ _ _     _             
  ___ ___ | | (_)___(_) ___  _ __  
 / __/ _ \| | | / __| |/ _ \| '_ \ 
| (_| (_) | | | \__ \ | (_) | | | |
 \___\___/|_|_|_|___/_|\___/|_| |_|
                                   
EOF
	print STDERR <<"EOF";
My compilation test failed due to existing files called one or the
other of '$c_file_name' or '$exe_file_name'. I want to use these
names. Please edit Makefile.PL to make me use different names, or
rename the existing files.
EOF
	return undef;
    }

    if (! $compile_ok || ! $run_ok) {
	print STDERR <<'EOF';
 _ _ _                                     _      __                       _ 
| (_) |__  _ __  _ __   __ _   _ __   ___ | |_   / _| ___  _   _ _ __   __| |
| | | '_ \| '_ \| '_ \ / _` | | '_ \ / _ \| __| | |_ / _ \| | | | '_ \ / _` |
| | | |_) | |_) | | | | (_| | | | | | (_) | |_  |  _| (_) | |_| | | | | (_| |
|_|_|_.__/| .__/|_| |_|\__, | |_| |_|\___/ \__| |_|  \___/ \__,_|_| |_|\__,_|
          |_|          |___/                                                 

I tried to compile and run a small test program in C to see if I could
#include the libpng header file "png.h" and link to the library
"libpng". Somehow or other this didn't work out. If you don't have
libpng on your system, sorry but you need to install it to use
[% config.base %]. 

If you are on Ubuntu Linux, you probably need to do something like

    sudo aptitude install libpng-dev

to install the header file "png.h" for libpng into your system.

If you think you have libpng on your system, please edit the file
"Makefile.PL" and run "perl Makefile.PL" again. The relevant lines are
right at the top of the file,

my $png_lib_dir;
my $png_include_dir;

Edit these lines to wherever your libpng and png.h files
respectively are to be found, for example

my $png_lib_dir = '/some/strange/directory';
my $png_include_dir = '/somewhere/nobody/knows';

Then run "perl Makefile.PL" again. If you don't see this message, you
are alright.
EOF
	return undef;
    }
    else {
	if ($verbose) {
	    print <<EOF;
The program compiled and ran successfully, so it looks like you have
libpng installed in a place where I can find it. I am now going to
write out the file "Makefile" using these parameters.

EOF
	}
    }

    my %vals;
    $vals{libs} = $libs;
    $vals{inc} = $inc;
    return \%vals;
}

1;
