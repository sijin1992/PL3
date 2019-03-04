#ifndef __LUA_MANAGER_H__
#define __LUA_MANAGER_H__

#include "lua52wrap.h"
#include "lua_cmd_handle.h"

struct _LUA_ENV
{
	lua_State *l;
	lua_State *global_state;
	lua_State *special_logic_state;
};

extern _LUA_ENV g_lua_env;

/*
	注册和读取所有的lua handle
	reg_file为注册文件，默认是./lua/reg.lua
	logic_path是lua handle的存放路径，默认是./lua/logic
	cmd_map默认应该引用CLogicDriver::m_lua_map
*/
int lua_load_reg(const char *file);

int lua_load_all(
	const char *reg_file,
	const char *global_file,
	const char *special_logic_file,
	const char *logic_path, 
	std::map<unsigned int, LUA_handle>& cmd_map);

int lua_release_all();


int lua_debug_cmd_map(std::map<unsigned int, LUA_handle>& cmd_map);

#define CALL_LUA_FUNC_BS_S(l, func, ret, arg)\
	if(lua_gettop(l) != 0)\
		LOG(LOG_ERROR, "call %s err: stack top is %u", func, lua_gettop(l));\
	lua_getglobal(l, func);\
	lua_pushlstring(l, arg.c_str(),arg.size());\
	if(lua_pcall(l, 1, 2, 0) != 0)\
	{\
		LOG(LOG_ERROR, "func %s, call error %s", func, lua_tostring(l, -1));\
		lua_pop(l, 1);\
		ret = -1;\
	}\
	else\
	{\
		bool r = lua_toboolean(l, -2);\
		if(r) ret = 1;\
		else ret = 0;\
		size_t len = 0;\
		const char *t = lua_tolstring(l, -1, &len);\
		arg.assign(t, len);\
		lua_pop(l,2);\
	}

#define CALL_LUA_FUNC_BSSSI_SSSSI(l, func, ret, arg1, arg2, arg3, arg4, arg5, ret1)\
	if(lua_gettop(l) != 0)\
		LOG(LOG_ERROR, "call %s err: stack top is %u", func, lua_gettop(l));\
	lua_getglobal(l, func);\
	lua_pushlstring(l, arg1.c_str(),arg1.size());\
	lua_pushlstring(l, arg2.c_str(),arg2.size());\
	lua_pushlstring(l, arg3.c_str(),arg3.size());\
	lua_pushlstring(l, arg4.c_str(),arg4.size());\
	lua_pushinteger(l, arg5);\
	if(lua_pcall(l, 5, 5, 0) != 0)\
	{\
		LOG(LOG_ERROR, "func %s, call error %s", func, lua_tostring(l, -1));\
		lua_pop(l, 1);\
		ret = -1;\
	}\
	else\
	{\
		bool r = lua_toboolean(l, -5);\
		if(r) ret = 1;\
		else ret = 0;\
		size_t len = 0;\
		const char *t1 = lua_tolstring(l, -4, &len);\
		arg1.assign(t1, len);\
		const char *t2 = lua_tolstring(l, -3, &len);\
		arg2.assign(t2, len);\
		const char *t3 = lua_tolstring(l, -2, &len);\
		arg3.assign(t3, len);\
		ret1 = lua_tointeger(l, -1);\
		lua_pop(l,5);\
	}




#endif
