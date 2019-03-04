#include "lua_manager.h"

#include "stdio.h"
#include "log/log.h"
//#include "wboss_for_lua.hpp"

_LUA_ENV g_lua_env;

int lua_load_reg(const char *file)
{
	lua_State *l = luaL_newstate();
	luaL_openlibs(l);
	int r = luaL_dofile(l, file);
	if(r != 0/*LUA_OK*/)
	{
		LOG(LOG_ERROR, "load %s err", file);
		return -1;
	}
	g_lua_env.l = l;
	return 0;
}

int lua_load_global(const char *file)
{
	lua_State *l = luaL_newstate();
	luaL_openlibs(l);
	lua_pushlightuserdata(l, &gLogObj);
	lua_setfield(l, LUA_REGISTRYINDEX, "log_obj");
	//wboss_regist_lua_func(l);
	int r = luaL_dofile(l, file);
	if(r != 0/*LUA_OK*/)
	{
		LOG(LOG_ERROR, "load %s err, %s", file, lua_tostring(l, -1));
		return -1;
	}
	g_lua_env.global_state = l;
	return 0;
}

int lua_load_special_logic(const char *file)
{
	lua_State *l = luaL_newstate();
	luaL_openlibs(l);
	int r = luaL_dofile(l, file);
	if(r != 0/*LUA_OK*/)
	{
		LOG(LOG_ERROR, "load %s err, %s", file, lua_tostring(l, -1));
		return -1;
	}
	g_lua_env.special_logic_state= l;
	return 0;
}


int lua_load_all(
	const char *reg_file,
	const char *global_file,
	const char *special_logic_file,
	const char *logic_path, 
	std::map<unsigned int, LUA_handle>& cmd_map)
{
	if(lua_load_reg(reg_file) != 0)
		return -1;
	if(lua_load_global(global_file) != 0)
		return -1;
	//if(lua_load_special_logic(special_logic_file) != 0)
		//return -1;
	if(lua_load_handles(logic_path, cmd_map) != 0)
		return -1;
	return 0;
}

int lua_release_all()
{
	/*for(map<unsigned int, LUA_handle>::iterator it = g_lua_cmd_map->begin();
		it != g_lua_cmd_map->end(); it++)
	{
		lua_close(it->second.l);
	}*/
	lua_close(g_lua_env.l);
	lua_close(g_lua_env.global_state);
	return 0;
}


int lua_debug_cmd_map(std::map<unsigned int, LUA_handle>& cmd_map)
{
	std::map<unsigned int, LUA_handle>::iterator it;
	char buf[256];
	int i = 0;
	LOG(LOG_DEBUG, "begin debug lua_cmd_map");
	for(it = cmd_map.begin(); it != cmd_map.end(); it++)
	{
		++i;
		snprintf(buf, 256, "%d: cmd = %d, lua = %p",
			i, it->first, it->second.l);
		LOG(LOG_DEBUG, "  %s", buf);
	}
	LOG(LOG_DEBUG, "debug lua_cmd_map end");
	return 0;
}


