#!/usr/bin/perl

#############################################################################
# This script reads a portion of a file and prints it to STDOUT to be slurped
#    up.
#############################################################################

my $file = shift @ARGV;
my $pos = shift @ARGV;

open(FILE, "$file");
seek(FILE, $pos, 0);

while ( <FILE> ) {
    my $line = $_;
    print $line;
}

close(FILE);
