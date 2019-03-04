include ../../makefile.depend

CXX = g++
CC = gcc
RM = rm -f
CXXFLAGS += -Wall -D_GNU_SOURCE  -g -DLINUX

LIBS = ../common/libservercommon.a ../../lib/libxoxxoo.a ../proto/libAllProto.a $(PROTOBUFF_LIB) 
INCS = -I ../../libsrc/ -I../

TARGETS= new_client main_robot 

all:$(TARGETS)
	
main_client:main_client.o client_interface.o
	$(CXX) -o $@ $^ $(LIBS)

new_client:new_client.o client_interface.o cmd_reader.o
	$(CXX) -o $@ $^ $(LIBS) -L/usr/lib64/ -lncurses

main_robot:main_robot.o client_interface.o
	$(CXX) -o $@ $^ $(LIBS)

%.o: %.cpp
	$(CXX) -c $(CXXFLAGS) $(INCS) $< -o $@

clean:
	$(RM) $(TARGETS) *.o 

install:
	strip new_client
	cp new_client /home/jinbi/issue/tools/
