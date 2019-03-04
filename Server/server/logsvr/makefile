include ../../makefile.depend

CXX = g++
CC = gcc
RM = rm -f
CXXFLAGS += -Wall -D_GNU_SOURCE  -g -DLINUX

LIBS =  ../common/libservercommon.a ../logic/liblogicdriver.a  ../../lib/libxoxxoo.a 
INCS = -I ../../libsrc/ -I../ -I../../ext/rapidxml-1.13 -I$(MYSQL_INCLUDE)

ifeq ($(release),1)
	LDFLAGS+=-s
endif

CPPFILE=$(shell ls *.cpp)
OBJS=$(patsubst %.cpp,%.o,$(CPPFILE))
TARGETS=logsvr
 
all:$(TARGETS)
	
logsvr:$(OBJS)
	$(CXX) $(LDFLAGS) -o $@ $^ $(LIBS) $(STATIC_MYSQL_LIB)
%.o: %.cpp
	$(CXX) -Wno-deprecated -c $(CXXFLAGS) $(INCS) $< -o $@

clean:
	$(RM) $(TARGETS) *.o 

