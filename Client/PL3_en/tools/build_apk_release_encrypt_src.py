#!/usr/bin/python

import os
import os.path
import shutil
import zipfile
import time

FILEPATH = os.path.dirname(os.path.realpath(__file__))
print "FILEPATH: " + FILEPATH

CONF = "release"
print "CONF: " + CONF



#-----remove res---------
# print "remove some res..."
# shutil.rmtree("../res/RoleImage")
# shutil.rmtree("../res/RoleIcon")
# shutil.rmtree("../res/ShipImage")
# shutil.rmtree("../res/sfx")
# shutil.rmtree("../res/ItemIcon")
# shutil.rmtree("../res/LotteryScene")
# shutil.rmtree("../res/LevelIcon")
# shutil.rmtree("../res/TrialScene")
# shutil.rmtree("../res/WeaponIcon")


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

#----build APK----
command = "cocos compile -p android --jobs 9 --android-studio -m " + CONF + " --compile-script 1 --lua-encrypt --lua-encrypt-key haomiao --lua-encrypt-sign haomiao  --ndk-mode "+ CONF +" -o " + "./"
print command
os.system(command)


print "build apk ok"