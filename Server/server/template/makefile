CXX = g++
CC = gcc
RM = rm -f
CXXFLAGS += -Wall -D_GNU_SOURCE  -g -DLINUX

LIBS = ../../lib/libxoxxoo.a ../proto/libAllProto.a $(shell pkg-config --cflags --libs protobuf) ../dbsvr/cache.o
INCS = -I ../../libsrc/ -I../  -I../main_logic

TARGETS=server_template

all:$(TARGETS)
	
server_template:server_template.o ../main_logic/data_control.o
	$(CXX) -o $@ $^ $(LIBS)

%.o: %.cpp
	$(CXX) -c $(CXXFLAGS) $(INCS) $< -o $@

clean:
	$(RM) $(TARGETS) *.o 

