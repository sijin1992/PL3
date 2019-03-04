#ifndef __LUA52WRAP_H__
#define __LUA52WRAP_H__

#ifdef __cplusplus
extern "C" {
#endif
	#include <lua.h>
	#include <lualib.h>
	#include <lauxlib.h>
#ifdef __cplusplus
}
#endif

// �������еĺ����������̰߳�ȫ�ģ���Ϊ�����ܲ��Ƕ��߳̿��

// �õ�ĳ��ȫ��table��ָ����
inline void lua_gettabledata(lua_State *L, const char *table, const char *field)
{
	lua_getglobal(L, table);
	lua_pushstring(L, field);
	lua_rawget(L, -2);
	lua_remove(L, -2);
}

#endif // __LUA52WRAP_H__