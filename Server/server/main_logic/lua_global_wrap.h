#ifndef __LUA_GLOBAL_WRAP_H__
#define __LUA_GLOBAL_WRAP_H__
#include <string>
#include "lua52wrap.h"
class CLuaGlobalWrap
{
protected:
	CLuaGlobalWrap();
	~CLuaGlobalWrap();
public:
	static CLuaGlobalWrap &getInstance();
	bool init(lua_State *gloabl);
	int getGlobalInt(const std::string &key);
	std::string getGlobalString(const std::string &key);

protected:
	lua_State *mGlobalState;
};

#define luaGlobal() CLuaGlobalWrap::getInstance()

#endif // __LUA_CONFIG_WRAP_H__

