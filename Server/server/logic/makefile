CXX = g++
CC = gcc
RM = rm -f
CXXFLAGS += -Wall -D_GNU_SOURCE  -g -DLINUX

INCS = -I ../../libsrc/ -I../

CPPFILE=$(shell ls *.cpp)
OBJS=$(patsubst %.cpp,%.o,$(CPPFILE))
TARGETS=liblogicdriver.a

all:$(TARGETS)
	
liblogicdriver.a:$(OBJS)
	ar rcs $@ $^

%.o: %.cpp
	$(CXX) -Wno-deprecated -c $(CXXFLAGS) $(INCS) $< -o $@

clean:
	$(RM) $(TARGETS) *.o 

