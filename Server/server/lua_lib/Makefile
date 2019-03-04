include ../../makefile.depend

INCLUDE = ../../libsrc/log -I../../libsrc/lock -I../../libsrc/ini

all:log.so rank_module.so util.so

log.so:lua_lib.cpp ../../libsrc/log/log.cpp ../../libsrc/lock/lock_file.cpp ../../libsrc/ini/ini_file.cpp
	g++ -fPIC -O2 -Wall -o $@ --shared $^ -I$(INCLUDE) -I$(LUA_INCLUDE)
	cp $@ ../lua/

rank_module.so:rank_list_module.c
	gcc -fPIC -O2 -Wall -o $@ --shared $^ -I$(LUA_INCLUDE) -std=c99
	cp $@ ../lua/

util.so:util.c
	gcc -fPIC -O2 -Wall -o $@ --shared $^ -I$(LUA_INCLUDE) -std=c99
	cp $@ ../lua/

clean:
	rm -f log.so rank_module.so util.so *.o