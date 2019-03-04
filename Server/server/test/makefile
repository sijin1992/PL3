include ../../makefile.depend
CXX = g++
CC = gcc
RM = rm -f
CXXFLAGS += -Wall -D_GNU_SOURCE  -g -DLINUX  

LIBS =  ../../lib/libxoxxoo.a
INCS = -I../ext/rapidxml-1.13 -I ../../libsrc/ -I../ -I$(MYSQL_INCLUDE) -Wno-deprecated
SVRLIBS = ../common/libservercommon.a ../logic/liblogicdriver.a

TARGETS=mysqltest_main noblocksendSvr noblocksendClt msgechosvr cryptpassword testindex
all:$(TARGETS)
	
mysqltest_main:mysqltest_main.o
	$(CXX) -o $@ $< $(LIBS) $(MYSQL_LIB)

noblocksendSvr:noblocksendSvr.o
	$(CXX) -o $@ $< $(LIBS) $(SVRLIBS)

noblocksendClt:noblocksendClt.o
	$(CXX) -o $@ $< $(LIBS) $(SVRLIBS)

msgechosvr:msgechosvr.o
	$(CXX) -o $@ $<  $(SVRLIBS) $(LIBS)

test_memcache:test_memcache.o
	$(CXX) -o $@ $<  $(STATIC_LIBMEMCACHED)

cryptpassword:cryptpassword.o
	$(CXX) -o $@ $<  $(STATIC_LIBCRYPT)

testindex:testindex.o
	$(CXX) -o $@ $< $(LIBS)

test_wabao:test_wabao.o
	$(CXX) -o $@ $<  ../xml_reader/libxmlconfig.a $(LIBS)
	
%.o: %.cpp
	$(CXX) -c $(CXXFLAGS) $(INCS) $< -o $@

clean:
	$(RM) $(TARGETS) *.o 

