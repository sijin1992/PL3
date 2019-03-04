CXX = g++
CC = gcc
RM = rm -f
CXXFLAGS += -Wall -D_GNU_SOURCE  -g -DLINUX

LIBS = 
INCS = -I../..

TARGETS=main_dequeue main_fsa main_timer main_fifo main_hashmap main_msa
all:$(TARGETS)
	
main_dequeue:main_dequeue.o
	$(CXX) -o $@ $< 
	
main_fsa:main_fsa.o 
	$(CXX) -o $@ $< ../fixedsize_allocator.o
	
	
main_timer:main_timer.o
	$(CXX) -o $@ $< 

main_fifo:main_fifo.o
	$(CXX) -o $@ $< ../../../lib/libxoxxoo.a 

main_hashmap:main_hashmap.o
	$(CXX) -o $@ $< ../../../lib/libxoxxoo.a 
	
main_msa:main_msa.o 
	$(CXX) -o $@ $< ../fixedsize_allocator.o ../mutilsize_allocator.o ../../../lib/libxoxxoo.a

%.o: %.cpp
	$(CXX) -c $(CXXFLAGS) $(INCS) $< -o $@

clean:
	$(RM) $(TARGETS) *.o 

