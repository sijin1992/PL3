include ../../makefile.depend
CXX = g++
CC = gcc
RM = rm -f
CXXFLAGS += -Wall -D_GNU_SOURCE  -g -DLINUX
NOWDIR = $(shell pwd)
CONFIG_PROTO_DIR=~mars/issue/logic/conf/

LIBS = ../xml_reader/libxmlconfig.a ../data_cache/libdatacache.a  ../common/libservercommon.a  ../../lib/libxoxxoo.a ../proto/libAllProto.a $(PROTOBUFF_LIB) 
INCS = -I ../../libsrc/ -I../ -I../ext/rapidxml-1.13/ -I$(MYSQL_INCLUDE)
TC_LIB = /usr/local/services/xxlm/lib/libtokyocabinet.so -lz -lrt -lpthread -lm -lc


#TARGETS=hash_tool  pipe_info output worldeventcreator dbsvr_info check_config session_info neicetool arttool
#SPC_TARGETS=main_fight main_logic_info dbparser leitaitool cdkeytool cdkey gmtool
#all:$(TARGETS) $(SPC_TARGETS)
all:robot

robot:robot.c
	$(CXX) -I../ -g -o $@ $^ ../proto/libAllProto.a $(PROTOBUFF_LIB)

main_fight:main_fight.o ../main_logic/fight.o ../main_logic/globefunction.o
	$(CXX) -o $@ $^ $(LIBS)

main_logic_info:main_logic_info.o ../main_logic/online_cache.o
	$(CXX) -s -o $@ $^ $(LIBS)

dbparser:dbparser.o
	$(CXX) -s -o $@ $< $(LIBS) $(STATIC_MYSQL_LIB)

leitaitool:leitaitool.o
	$(CXX) -s -o $@ $^  ../dbsvr/leitaimap.o $(LIBS)

cdkeytool:cdkeytool.o
	$(CXX) -s -o $@ $^  $(TC_LIB)

cdkey:cdkey.o
	$(CXX) -s -o $@ $^  $(TC_LIB)

gmtool:gmtool.o
	$(CXX) -s -o $@ $^  ../../lib/libxoxxoo.a  -lz -lrt

$(TARGETS):%:%.o
	$(CXX) -s -o $@ $< $(LIBS)
	
%.o: %.cpp
	$(CXX) -c $(CXXFLAGS) $(INCS) $< -o $@

sync_world:worldevent.ini
	cp $^ $(CONFIG_PROTO_DIR)

sync_rookie:rookiercd.bin
	cp $^ $(CONFIG_PROTO_DIR)

sync_neice:neice.user
	cp $^ $(CONFIG_PROTO_DIR)

rookiercd.bin:main_fight
	./main_fight 3

worldevent.ini:worldeventcreator
	./worldeventcreator 300 ../../tools/worldevent.xml worldevent.ini

neice.user:neicetool
	./neicetool neice.list
	
clean:
	$(RM) $(TARGETS) *.o 

issue:
	cp hash_tool pipe_info dbsvr_info session_info main_logic_info ~mars/issue/tools/
