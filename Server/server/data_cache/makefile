include ../../makefile.depend
CXX = g++
CC = gcc
RM = rm -f
CXXFLAGS += -Wall -D_GNU_SOURCE  -g -DLINUX  

LIBS = ../../lib/libxoxxoo.a ../proto/libAllProto.a $(shell pkg-config --cflags --libs protobuf)
INCS = -I ../../libsrc/ -I../ 

OBJS=data_cache.o data_cache_api.o

TARGETS=libdatacache.a
all:$(TARGETS)

libdatacache.a:data_cache.o data_cache_api.o
	ar  rcs $@ $^
	
%.o: %.cpp
	$(CXX) -c $(CXXFLAGS) $(INCS) $< -o $@

clean:
	$(RM) $(TARGETS) *.o 

