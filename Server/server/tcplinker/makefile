CXX = g++
CC = gcc
RM = rm -f
CXXFLAGS += -Wall -D_GNU_SOURCE  -g -DLINUX -Wno-deprecated

LIBS =  ../common/libservercommon.a ../logic/liblogicdriver.a ../../lib/libxoxxoo.a 
INCS = -I ../../libsrc/ -I../

TARGETS=tcplinker

all:$(TARGETS)
	
tcplinker:tcplinker.o
	$(CXX) -o $@ $^ $(LIBS)

%.o: %.cpp
	$(CXX) -c $(CXXFLAGS) $(INCS) $< -o $@

clean:
	$(RM) $(TARGETS) *.o 

