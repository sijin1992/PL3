#!/usr/bin/python

import os
import os.path
import shutil
import zipfile
import time

FILEPATH = os.path.dirname(os.path.realpath(__file__))
print "FILEPATH: " + FILEPATH

DIR = os.path.realpath(FILEPATH + "/../frameworks/runtime-src/proj.ios_mac/")
print "DIR: " + DIR

ARC = DIR + "/StarClient.xcarchive"
print "ARC: " + ARC

Options = "AdHocExportOptions.plist"
print "Options: " + Options

CONF = "Release"
print "CONF: " + CONF

IPANAME = "StarClient_adhoc"

#----svn update----
# command = "svn up " + FILEPATH + "/.."
# os.system(command)

#----encode----
command = "python do_encode_res.py"
os.system(command)



# #----zip CONF----
# CONFDIR = FILEPATH + "/../src/conf/"
# sourceFiles = os.listdir(CONFDIR)
# z = zipfile.ZipFile('conf.zip', 'w' ,zipfile.ZIP_DEFLATED)
# for sourceFile in sourceFiles:
#     sourceFileFullDir = os.path.join(CONFDIR, sourceFile)
#     z.write(sourceFileFullDir, sourceFile) 
# z.close()

# shutil.move("conf.zip","../res/conf.zip")

# shutil.rmtree("../src/conf")



#----build IPA----

PROJ = DIR + "/StarClient.xcworkspace"

command = "xcodebuild clean -workspace " + PROJ + " -scheme StarClient-mobile -configuration " + CONF
print command
os.system(command)

command = "xcodebuild archive -workspace " + PROJ + " -scheme StarClient-mobile -archivePath " + ARC
print command
os.system(command)

command = "xcodebuild -exportArchive -archivePath " + ARC + " -exportOptionsPlist " + DIR + "/" + Options +  " -exportPath " + FILEPATH
print command
os.system(command)

os.rename("StarClient-mobile.ipa", IPANAME + time.strftime('_%y_%m_%d_%H_%M',time.localtime(time.time())) + ".ipa")


#----decode----
command = "python do_decode_res.py"
os.system(command)



print "build ipa ok"