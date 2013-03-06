#!/usr/bin/env python

#############################################################################
# This script reads a portion of a file and prints it to STDOUT to be slurped
#    up by the monitor_tomcat.sh script.
#############################################################################

import sys

filename = sys.argv[1]
offset = int(sys.argv[2])

with open( filename, "r") as infile:
    infile.seek(offset)
    for line in infile.readlines():
        print line
