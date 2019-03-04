CXX = g++
CC = gcc
RM = rm -f
CXXFLAGS += -Wall -D_GNU_SOURCE  -g -DLINUX  

INCS = -I ../../libsrc/ -I../ 

OBJS=user_distribute.o msg_define.o speed_control.o packet_interface.o queue_pipe.o

TARGETS=libservercommon.a
all:$(TARGETS)

libservercommon.a:$(OBJS)
	ar  rcs $@ $^
	
%.o: %.cpp
	$(CXX) -c $(CXXFLAGS) $(INCS) $< -o $@

clean:
	$(RM) $(TARGETS) *.o 

