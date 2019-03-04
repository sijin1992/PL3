CXX = g++
CC = gcc
RM = rm -f
CXXFLAGS += -Wall -D_GNU_SOURCE  -g -DLINUX

ifeq ($(debug),1)
    CXXFLAGS += -D DEBUG
endif

LIBS = 
INCS =

TARGETS += $(patsubst %.cpp,%.o,$(wildcard *.cpp))

all:$(TARGETS)

%.o: %.cpp
	$(CXX) -c $(CXXFLAGS) $(INCS) $< -o $@

clean:
	$(RM) $(TARGETS) *.o 

