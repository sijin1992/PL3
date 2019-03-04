include ../../makefile.depend

CXX = g++
CC = gcc
RM = rm -f
CXXFLAGS += -Wall -D_GNU_SOURCE  -g -DLINUX
LDFLAGS+=

LIBS = ../common/libservercommon.a ../logic/liblogicdriver.a ../data_cache/libdatacache.a ../../lib/libxoxxoo.a ../proto/libAllProto.a $(PROTOBUFF_LIB) \
    $(LUA_LIB)
INCS = -I./ -I ../../libsrc/ -I../ -I../flagsvr -I$(LUA_INCLUDE)

ifeq ($(release),1)
	LDFLAGS+=-s
endif

ifeq ($(closeshop),1)
	CXXFLAGS += -D CLOSE_SHOP
endif

CPPFILE=$(shell ls *.cpp)
OBJS=$(patsubst %.cpp,%.o,$(CPPFILE))
RANK_CPPFILE=$(shell ls ../flagsvr/*rank*.cpp)
OBJS+=$(patsubst %.cpp,../flagsvr/%.o,$(RANK_CPPFILE))
RANK_OBJS=$(patsubst %.cpp,%.o,$(RANK_CPPFILE))
TARGETS=main_logic

all:$(TARGETS)
	
main_logic:$(OBJS)
	$(CXX) $(LDFLAGS) -o $@ $^ $(LIBS) $(STATIC_LIBCRYPT)

%.o: %.cpp
	$(CXX) -Wno-deprecated -c $(CXXFLAGS) $(INCS) $< -o $@

clean:
	$(RM) $(TARGETS) *.o 

