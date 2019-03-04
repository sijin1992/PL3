include ../../makefile.depend

CXX = g++
CC = gcc
RM = rm -f
CXXFLAGS += -Wall -D_GNU_SOURCE  -g -DLINUX -Wno-deprecated

ifeq ($(memcache),1)
	CXXFLAGS+=-D USE_MEMCACHED
endif

LIBS = ../common/libservercommon.a ../logic/liblogicdriver.a ../../lib/libxoxxoo.a  ../proto/libAllProto.a $(PROTOBUFF_LIB) 
INCS = -I ../../libsrc/ -I../
TC_LIB = /usr/local/services/xxlm/lib/libtokyocabinet.so -lz -lrt -lpthread -lm -lc
TARGETS=flagsvr flagbackup

all:$(TARGETS)
	
flagsvr:rank_pool.o flagsvr.o 
	$(CXX) -o $@ $^ $(LIBS) $(TC_LIB)

memcache_helper:memcache_helper.o
	$(CXX) -o $@ $^ $(LIBS) $(STATIC_LIBMEMCACHED)

flagbackup:flagbackup.o
	$(CXX) -o $@ $^ $(LIBS) 

%.o: %.cpp
	$(CXX) -c $(CXXFLAGS) $(INCS) $< -o $@

clean:
	$(RM) $(TARGETS) *.o 

