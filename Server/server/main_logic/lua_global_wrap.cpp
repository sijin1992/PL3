#include "lua_global_wrap.h"
#include <sstream>
CLuaGlobalWrap::CLuaGlobalWrap()
{
	mGlobalState = NULL;
}

CLuaGlobalWrap::~CLuaGlobalWrap()
{

}

CLuaGlobalWrap &CLuaGlobalWrap::getInstance()
{
	static CLuaGlobalWrap *pSIns = NULL;
	if( NULL == pSIns )
	{
		pSIns = new CLuaGlobalWrap;
	}
	return *pSIns;
}

bool CLuaGlobalWrap::init(lua_State *gloabl)
{
	mGlobalState = gloabl;
	return true;
}

int CLuaGlobalWrap::getGlobalInt(const std::string &key)
{
	int num = 0;
	lua_getglobal(mGlobalState, key.c_str());
	if( lua_isnumber(mGlobalState, -1) )
	{
		num = lua_tointeger(mGlobalState, -1);
	}
	else if( lua_isstring(mGlobalState, -1) )
	{
		std::string str = lua_tostring(mGlobalState, -1);
		std::stringstream sstream;
		sstream << str;
		sstream >> num;
	}
	lua_pop(mGlobalState, 1);
	return num;
}

std::string CLuaGlobalWrap::getGlobalString(const std::string &key)
{
	std::string str = "";
	lua_getglobal(mGlobalState, key.c_str());
	if( lua_isnumber(mGlobalState, -1) )
	{
		int num = lua_tointeger(mGlobalState, -1);
		std::stringstream sstream;
		sstream << num;
		sstream >> str;
	}
	else if( lua_isstring(mGlobalState, -1) )
	{
		str = lua_tostring(mGlobalState, -1);
	}
	lua_pop(mGlobalState, 1);
	return str;
}



