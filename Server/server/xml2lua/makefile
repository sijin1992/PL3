lua = $(patsubst %.xml, %.lua, $(wildcard *.xml))

lua_module = $(patsubst %.xml, %, $(wildcard *.xml))
h_file = $(patsubst %.xml, %_conf.h, $(wildcard *.xml))

all:$(lua) all_config.h
	rm -f all_config.lua
	cp *.lua ../lua/config/
	echo "--this file is created by xml2lua.makefile. don't modify it" > all_config.lua
	for x in $(lua_module); do echo "require \"$$x\"" >> all_config.lua; done
	cp all_config.lua ../lua/

xml2lua : tinyxml2.cpp tinyxml2.h xml2lua.cpp
	g++ $^ -o $@
	
all_config.h:
	echo "#ifndef __ALL_CONFIG_H__" > all_config.h
	echo "#define __ALL_CONFIG_H__" >> all_config.h
	for x in $(h_file); do echo "#include \"xml2lua/$$x\"" >> all_config.h; done
	echo "#endif" >> all_config.h

%.lua : *.xml xml2lua
	./xml2lua $*

robot:tinyxml2.h tinyxml2.cpp robot2lua.cpp
	g++ $^ -o $@

clean:
	rm -f *.lua
	rm -f *_conf.h
	rm -f all_config.h
	rm -f ../lua/config/*.lua
    


