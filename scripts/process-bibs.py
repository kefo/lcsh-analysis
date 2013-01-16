#!/usr/bin/python

# import string
# import threading
import time
from time import gmtime, strftime
import glob
import fileinput

# For HTML escaping/unescaping
import cgi

import subprocess
from subprocess import Popen

# import shutil

# from StringIO import StringIO

# bibid  (record this even if no subjects?)
# lccn
# Heading, as written, with hyphens
# Heading, remove all punctuation
# how many components
# types of components - topic, geographic, temporal, genre/form
# subfield order usage, avxv for example

# How many subject headings
# How many total resources
# How many total resources without subjects
# How many *unique* subject headings
# Greatest number of components
# Frequency of components % topic, % geographic, % temporal, % genre/form

# 600, 610, 611, 630, 648, 650, 651
# Second indicator = 2

MARCRECORD = "{http://www.loc.gov/MARC21/slim}record"
MARCCF = "{http://www.loc.gov/MARC21/slim}controlfield"
MARCDF = "{http://www.loc.gov/MARC21/slim}datafield"
MARCSF = "{http://www.loc.gov/MARC21/slim}subfield"

DATADIR = "../data/xml/"
# DATADIR = "../data/xml-bfid2/"

FILES = glob.glob(DATADIR + '*.xml')

fo = open("../data/tsv/subjects.tsv", "w")
fo.close()

for f in FILES:
    # print 'Current f :', f
    zorbaCommand = "zorba -i -r -f -q process-bibs-zorba.xqy -e marcxmluri:=\"" + f + "\" --omit-xml-declaration"
    # print zorbaCommand
    xresult, xerrors = Popen([zorbaCommand], stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True).communicate()
    if xresult == "":
        out = cgi.escape(xerrors)
    else:
        out = xresult

    print out
