ifdef fcgi
	LDFLAGS += ../lib/libwebfast.a 
else
	LDFLAGS += ../lib/libweb.a 
endif

CC = g++
CGIS = test
CFLAGS = -Wall -g -DLINUX -I../inc

all:$(CGIS)

$(CGIS):%:%.o
	$(CC) $< $(LDFLAGS) -o $@ 

%.o:%.cpp
	$(CC) $(CFLAGS) -c $< -o $@
	
clean:
	rm -f $(CGIS) $(patsubst %,%.o,$(CGIS))


