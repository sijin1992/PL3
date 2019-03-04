CXX = g++
CC = gcc
RM = rm -f
CXXFLAGS += -Wall -D_GNU_SOURCE  -g -DLINUX

LIBS = 
INCS = -I../..


all:dwtool
	
dwtool:dwtool.o
	$(CXX) -o $@ $< ../../lib/libxoxxoo.a
	
%.o: %.cpp
	$(CXX) -c $(CXXFLAGS) $(INCS) $< -o $@

clean:
	$(RM) $(TARGETS) *.o 

