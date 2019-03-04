MAKEDIR=common proto data_cache logic connect connect/session_auth connect/gateway client_tool dbsvr main_logic tcplinker test lua_lib #tools

all:$(MAKEDIR)
	$(foreach temp, $(MAKEDIR), make -C $(temp);)

clean:
	$(foreach temp, $(MAKEDIR), make -C $(temp) clean;)
