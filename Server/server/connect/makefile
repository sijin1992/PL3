include ../../makefile.depend
CXX = g++
CC = gcc
RM = rm -f
CXXFLAGS += -Wall -D_GNU_SOURCE  -g -DLINUX

LIBS = ../common/libservercommon.a  ../logic/liblogicdriver.a ../../lib/libxoxxoo.a ../proto/libAllProto.a $(PROTOBUFF_LIB)
INCS = -I ../../libsrc/ -I../ -Wno-deprecated

TARGETS=connect httpcb #session_echo client
all:$(TARGETS)



$(TARGETS):%:%.o
	$(CXX) -o $@ $< $(LIBS)

connect:connect.o broadcast_manager.o
	$(CXX) -o $@ $^ $(LIBS)


%.o: %.cpp
	$(CXX) -c $(CXXFLAGS) $(INCS) $< -o $@

clean:
	$(RM) $(TARGETS) *.o 

