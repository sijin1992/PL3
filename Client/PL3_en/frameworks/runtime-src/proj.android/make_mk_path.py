#!/usr/bin/python

import os
import os.path
import stat
import fnmatch

dirList = []
cppList = []

def add_dir_2_list(rootDir):

	dirList.append(rootDir)

	for filename in os.listdir(rootDir):

		fullPath = os.path.join(rootDir, filename)

		if os.path.isfile(fullPath):
			
			if filename.endswith('.cpp') or filename.endswith('.cc') or filename.endswith('.c'):
				print fullPath
				cppList.append(fullPath)
		if os.path.isdir(fullPath):
			print fullPath
			add_dir_2_list(fullPath)

def create_mk_file(filename):

	f = file(filename,"wb")

	f.write('LOCAL_PATH := $(call my-dir)\n')
	f.write('\n')
	f.write('include $(CLEAR_VARS)\n')
	f.write('\n')
	f.write('LOCAL_MODULE := cocos2dlua_shared\n')
	f.write('\n')
	f.write('LOCAL_MODULE_FILENAME := libcocos2dlua\n')
	f.write('\n')

	f.write('LOCAL_SRC_FILES := hellolua/main.cpp\n')
	
	for cppname in cppList:
		f.write('LOCAL_SRC_FILES += ../' + cppname + '\n')

	f.write('\nLOCAL_C_INCLUDES := \\\n')

	for dirname in dirList:
		f.write('LOCAL_C_INCLUDES += $(LOCAL_PATH)/../' + dirname + '\n')


	f.write('\n')

	f.write('LOCAL_STATIC_LIBRARIES := cocos2d_lua_static\n')
	f.write('LOCAL_STATIC_LIBRARIES += cocos2d_simulator_static\n')

	f.write('\n')

	f.write('include $(BUILD_SHARED_LIBRARY)\n')

	f.write('\n')

	f.write('$(call import-module,scripting/lua-bindings/proj.android)\n')
	f.write('$(call import-module,tools/simulator/libsimulator/proj.android)\n')

	f.close()
	 


# -------------- main --------------
if __name__ == '__main__':

	search_path = '../Classes'

	mk_path = './Android.mk'

	add_dir_2_list(search_path)

	create_mk_file(mk_path)


	print 'make ok!'