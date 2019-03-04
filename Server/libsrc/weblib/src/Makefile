CC = g++
AR = ar
CFLAGS = -g -Wall
ALLINC = -I../inc/ 
FASTCGINC = 

TARGETS=../lib/libweb.a ../lib/libwebfast.a 

webobj=webparam.o webapp.o webpage.o 
webobjfast=webparamfast.o webappfast.o webpagefast.o 

all:$(TARGETS)

$(webobj):%.o:%.cpp
	$(CC) $(CFLAGS) $(ALLINC) -c $<
	
$(webobjfast):%fast.o:%.cpp
	$(CC) $(CFLAGS) -D WEBLIB_WITH_FASTCGI $(ALLINC) $(FASTCGINC) -c $< -o$@

../lib/libweb.a:$(webobj)
	ar r $@ $^
	ranlib $@
	
../lib/libwebfast.a:$(webobjfast)
	ar r $@ $^
	ranlib $@
	
clean:
	-rm -f *.o $(TARGETS) ../lib/*.a

