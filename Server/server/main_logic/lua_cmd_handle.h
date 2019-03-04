#ifndef __LUA_CMD_HANDLE_H__
#define __LUA_CMD_HANDLE_H__
#include <map>
#include <string>

#include "lua52wrap.h"

struct LUA_handle
{
	//std::string file;				// lua file
	//std::string module;				// module name
	//std::string feature_function;	// default is [module]_feature()
	//std::string do_logic_function;	// default is [module]_do_logic()
	lua_State *l;
};

// 从逻辑上讲,lua模块隶属于Driver,所以这个map是CLogicMainDriver的成员变量
// 但是目前的框架下，Driver很难直接和具体的CLogicProcessor(CLogicLUA)共享数据，
// 所以基于要么大动框架要么尽量契合原框架的原则，这里将这个map指针作为全局变量，供CLogicLUA访问
extern std::map<unsigned int, LUA_handle> *g_lua_cmd_map;


int lua_load_handles(const char *path,
	std::map<unsigned int, LUA_handle>& cmd_map);


#endif // __LUA_CMD_HANDLE_H__

