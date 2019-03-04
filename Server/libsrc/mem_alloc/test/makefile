CXX = g++
CC = gcc
RM = rm -f
CXXFLAGS += -Wall -D_GNU_SOURCE  -g -DLINUX

LIBS = 
INCS = -I../..

TARGETS=main main_pool
all:$(TARGETS)
	
main:main.o
	$(CXX) -o $@ $< ../*.o

main_pool:main_pool.o
	$(CXX) -o $@ $< ../*.o
	
%.o: %.cpp
	$(CXX) -c $(CXXFLAGS) $(INCS) $< -o $@

clean:
	$(RM) $(TARGETS) *.o 

