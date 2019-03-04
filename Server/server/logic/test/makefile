CXX = g++
CC = gcc
RM = rm -f
CXXFLAGS += -Wall -D_GNU_SOURCE  -g -DLINUX

LIBS = ../../common/libservercommon.a  ../liblogicdriver.a ../../../lib/libxoxxoo.a 
INCS = -I ../../../libsrc/ -I../../

TARGETS=testlogic clientlogic
all:$(TARGETS)
	
testlogic:testlogic.o
	$(CXX) -o $@ $< $(LIBS)
	
clientlogic:clientlogic.o
	$(CXX) -o $@ $< $(LIBS)
	
%.o: %.cpp
	$(CXX) -c $(CXXFLAGS) $(INCS) $< -o $@

clean:
	$(RM) $(TARGETS) *.o 

