#!/usr/bin/python

import os
import os.path
import shutil


shutil.rmtree("../src")
shutil.rmtree("../res")

os.rename("../src_back","../src")
os.rename("../res_back","../res")


print "decode ok"