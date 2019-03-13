#!/usr/bin/python

import sys
import os
import os.path
import stat
import fnmatch

lite="option optimize_for = LITE_RUNTIME;"

def add_option_lite(dirpath):
	for filename in os.listdir(dirpath):
		if filename.endswith('.proto'):
			filepath = os.path.join(dirpath, filename)
			print filepath
			f=file(filepath,"r+")
			context = f.read()
			if context.find('option optimize_for = LITE_RUNTIME;') < 0:
				f.seek(0)
				f.write('%s%s' % (lite,context))
			f.close()

def remove_option_lite(dirpath):
	for filename in os.listdir(dirpath):
		if filename.endswith('.proto'):
			filepath = os.path.join(dirpath, filename)
			f = file(filepath, "rb")
			context = f.read()
			context = context.replace(lite,"")
			f.close()
			f = file(filepath,"wb")
			f.write(context)
			f.close()


# -------------- main --------------
if __name__ == '__main__':
	proto_path = '../proto/'
	cpp_out_path = '../frameworks/runtime-src/Classes/network/proto/'
	lua_out_path = '../src/protobuf_messages/'
	add_option_lite(proto_path)

	for filename in os.listdir(proto_path):
		if filename.endswith('.proto'):
			command = 'protoc -I=%s --cpp_out=%s %s' % (proto_path, cpp_out_path, os.path.join(proto_path, filename))
			print("command:" + command)
			os.system(command)
			# command = 'protoc -I=%s --lua_out=%s %s' % (proto_path, lua_out_path, os.path.join(proto_path, filename))
			# print("command:" + command)
			# os.system(command)

			pbName = filename
			pbName = lua_out_path + pbName.replace(".proto",".pb")
			command = 'protoc -I=%s --descriptor_set_out %s %s' % (proto_path, pbName, os.path.join(proto_path, filename))
			print("command:" + command)
			os.system(command)
	
	remove_option_lite(proto_path)

	print 'build ok!'