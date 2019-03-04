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

// ���߼��Ͻ�,luaģ��������Driver,�������map��CLogicMainDriver�ĳ�Ա����
// ����Ŀǰ�Ŀ���£�Driver����ֱ�Ӻ;����CLogicProcessor(CLogicLUA)�������ݣ�
// ���Ի���Ҫô�󶯿��Ҫô��������ԭ��ܵ�ԭ�����ｫ���mapָ����Ϊȫ�ֱ�������CLogicLUA����
extern std::map<unsigned int, LUA_handle> *g_lua_cmd_map;


int lua_load_handles(const char *path,
	std::map<unsigned int, LUA_handle>& cmd_map);


#endif // __LUA_CMD_HANDLE_H__

