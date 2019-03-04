include ../../makefile.depend

CXX = g++
CC = gcc
RM = rm -f
CXXFLAGS += -Wall -D_GNU_SOURCE  -g -DLINUX -Wno-deprecated

LIBS = ../common/libservercommon.a ../logic/liblogicdriver.a ../../lib/libxoxxoo.a
INCS = -I ../../libsrc/ -I../ -I$(MYSQL_INCLUDE)
TARGETS=svr_centre

all:$(TARGETS)
	
svr_centre:svr_centre.o 
	$(CXX) -o $@ $^ $(LIBS)  $(STATIC_MYSQL_LIB)

%.o: %.cpp
	$(CXX) -c $(CXXFLAGS) $(INCS) $< -o $@

clean:
	$(RM) $(TARGETS) *.o 

