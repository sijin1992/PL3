#!/usr/bin/python

import os, sys, stat
import os.path
import shutil
import platform

FILEPATH = os.path.dirname(os.path.realpath(__file__))
print "FILEPATH: " + FILEPATH

key = "utugames"
signment = "liuxutao"

command = "cocos luacompile -s ../src -d ../src_encode -e -k utugames -b liuxutao --disable-compile"
shutil.copytree('../src/protobuf_messages', '../src_encode/protobuf_messages')

os.system(command)

os.rename("../src","../src_back")
os.rename("../src_encode","../src")

shutil.copytree("../res/fonts", "../fonts")
shutil.copytree("../res/sound","../sound")

if platform.system() == "Windows":
	command = FILEPATH + "/bin/pack_files.bat -i ../res -o ../res_encode -ek utugames -es liuxutao"
	os.system(command)
else:
	command = "sh bin/pack_files.sh -i ../res -o ../res_encode -ek utugames -es liuxutao"  
	os.system(command)

shutil.rmtree("../res_encode/fonts")
shutil.rmtree("../res_encode/sound")

shutil.copytree("../fonts","../res_encode/fonts")
shutil.copytree("../sound","../res_encode/sound")

shutil.rmtree("../res/fonts")
shutil.rmtree("../res/sound")

shutil.copytree("../fonts","../res/fonts")
shutil.copytree("../sound","../res/sound")

shutil.rmtree("../fonts")
shutil.rmtree("../sound")

os.rename("../res","../res_back")
os.rename("../res_encode","../res")

shutil.copy("../res_back/particle_texture.png", "../res/particle_texture.png")

BackResPath = FILEPATH + "/../res_back"
EncodeResPath = FILEPATH + "/../res"
for rt, dirs, files in os.walk(BackResPath):
	for f in files:
		fname = os.path.splitext(f)
		if fname[1] == ".plist" or fname[1] == ".fnt "or fname[1] == ".json":
			orgpath = os.path.join(rt,f)
			distpath = orgpath.replace(BackResPath, EncodeResPath, 1)
			print orgpath + " -> " + distpath
			shutil.copy(orgpath, distpath)


print "encode ok"