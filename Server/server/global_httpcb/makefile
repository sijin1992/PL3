include ../../makefile.depend

CXX = g++
CC = gcc
RM = rm -f
CXXFLAGS += -Wall -D_GNU_SOURCE  -g -DLINUX -Wno-deprecated

LIBS = ../common/libservercommon.a ../logic/liblogicdriver.a  ../../lib/libxoxxoo.a ../proto/libAllProto.a $(PROTOBUFF_LIB)
INCS = -I ../../libsrc/ -I../
TARGETS=global_httpcb

all:$(TARGETS)
	
global_httpcb:global_httpcb.o 
	$(CXX) -o $@ $^ $(LIBS)

%.o: %.cpp
	$(CXX) -c $(CXXFLAGS) $(INCS) $< -o $@

clean:
	$(RM) $(TARGETS) *.o 

