include ../../makefile.depend
CXX = g++
CC = gcc
RM = rm -f
CXXFLAGS += -Wall -D_GNU_SOURCE  -g -DLINUX  
LDFLAGS+=

ifeq ($(release),1)
LDFLAGS+=-s
endif

LIBS = ../data_cache/libdatacache.a ../common/libservercommon.a   ../logic/liblogicdriver.a  ../../lib/libxoxxoo.a ../proto/libAllProto.a $(PROTOBUFF_LIB)
INCS = -I ../../libsrc/ -I../ -I$(MYSQL_INCLUDE) -Wno-deprecated -I$(LUA_INCLUDE)

TARGETS=dbsvr db_tool mysql_helper mysql_helper_tool
all:$(TARGETS)

dbsvr:dbsvr.o logic_dbgroupuser.o
	$(CXX) $(LDFLAGS) -o $@ $^ $(LIBS) $(LUA_LIB)

db_tool:db_tool.o
	$(CXX) -o $@ $< $(LIBS)

mysql_helper_tool:mysql_helper_tool.o
	$(CXX) -o $@ $< $(LIBS)

mysql_helper:mysql_helper.o
	$(CXX) $(LDFLAGS) -o $@ $< $(LIBS) $(STATIC_MYSQL_LIB)

%.o: %.cpp
	$(CXX) -c $(CXXFLAGS) $(INCS) $< -o $@

clean:
	$(RM) $(TARGETS) *.o 

