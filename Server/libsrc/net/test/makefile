CXX = g++
CC = gcc
RM = rm -f
CXXFLAGS += -Wall -D_GNU_SOURCE  -g -DLINUX

LIBS = 
INCS = -I../..


all:main curltest
	
main:main.o
	$(CXX) -o $@ $< ../tcpwrap.o ../tcp_client.o ../../random/random.o

curltest:curltest.o ../curlwrap.h
	$(CXX) -o $@ $^ ../../binary/binary_util.o /usr/local/lib/libcurl.a -lz -lrt
	
%.o: %.cpp
	$(CXX) -c $(CXXFLAGS) $(INCS) $< -o $@

clean:
	$(RM) $(TARGETS) *.o 

