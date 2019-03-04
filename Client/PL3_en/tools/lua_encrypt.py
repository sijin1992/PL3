#!/usr/bin/python

import os
import os.path
import shutil


def ReadFile(filePath):  
    file_object = open(filePath,'rb')  
    all_the_text = file_object.read()  
    file_object.close()  
    return all_the_text  
  
def WriteFile(filePath,all_the_text):      
    file_object = open(filePath,'wb')      
    file_object.write(all_the_text)  
    file_object.close()  
      
def BakFile(filePath,all_the_text):  
    file_bak = filePath[:len(filePath)-3] + 'bak'     
    WriteFile(file_bak,all_the_text)  
  
  
  
def ListLua(path):  
    fileList = []   
    for root,dirs,files in os.walk(path):  
       for eachfiles in files:  
           if eachfiles[-4:] == '.lua' :                 
               fileList.append(root + '/' + eachfiles)  
    return fileList  
  
def EncodeWithXxteaModule(filePath,key,signment):      
    all_the_text = ReadFile(filePath)      
  
    if all_the_text[:len(signment)] == signment :  
        return  
    #bak lua  
    BakFile(filePath,all_the_text)  
         
    encrypt = xxteaModule.encrypt(all_the_text,key)  
    signment = signment + encrypt  
    WriteFile(filePath,signment)      
      
def EncodeLua(projectPath,key,signment):  
    path = projectPath + '/src'  
    fileList = ListLua(path)  
    for files in fileList:  
        EncodeWithXxteaModule(files,key,signment)  
  
def FixCpp(projectPath,key,signment):  
    filePath = projectPath + '/frameworks/runtime-src/Classes/AppDelegate.cpp'  
    all_the_text = ReadFile(filePath)  
  
    #bak cpp  
    #BakFile(filePath,all_the_text)      
  
  
    pos = all_the_text.find('stack->setXXTEAKeyAndSign')  
    left = all_the_text.find('(',pos)  
    right = all_the_text.find(';',pos)     
  
    word = str.format('("%s", strlen("%s"), "%s", strlen("%s"))' % (key,key,signment,signment))  
      
    all_the_text = all_the_text[:left] + word + all_the_text[right:-1]  
      
    WriteFile(filePath,all_the_text)   
      
      
      
projectPath = "../"  
key = "utugames"  
signment = "liuxutao"  

command = "cocos luacompile -s ../src -d ../src_encode -e -k utugames -b liuxutao --disable-compile"
shutil.copytree('../src/protobuf_messages', '../src_encode/protobuf_messages')
  
#EncodeLua(projectPath,key,signment) 
os.system(command)
#FixCpp(projectPath,key,signment)  
print "encode ok"  