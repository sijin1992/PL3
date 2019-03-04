#include <string.h>
extern "C"
{
    #include <lua.h>
    #include <lauxlib.h>
}

#include "log.h"
#define luaL_newlibtable(L,l)	\
  lua_createtable(L, 0, sizeof(l)/sizeof((l)[0]) - 1)
  
void luaL_setfuncs (lua_State *L, const luaL_Reg *l, int nup) {
  //luaL_checkversion(L);
  luaL_checkstack(L, nup, "too many upvalues");
  for (; l->name != NULL; l++) {  /* fill the table with given functions */
    int i;
    for (i = 0; i < nup; i++)  /* copy upvalues to the top */
      lua_pushvalue(L, -nup);
    lua_pushcclosure(L, l->func, nup);  /* closure with those upvalues */
    lua_setfield(L, -(nup + 2), l->name);
  }
  lua_pop(L, nup);  /* remove upvalues */
}

int log_something(int loglevel, lua_State *l)
{
    CLogProxy *logobj = (CLogProxy *)lua_touserdata(l, lua_upvalueindex(1));
    const char *str = luaL_checkstring(l, -1);
    (logobj->m_len = 
        snprintf(logobj->m_buff, sizeof(logobj->m_buff), "%s|from lua| %s\r\n", logobj->head_str(), str)) > 0 ? logobj->write(loglevel) : -1;
    return 0;
}

#define LOG_STAT_PTR(logptr, loglevel, format, args...) \
	(logptr->m_len = snprintf(logptr->m_buff, sizeof(logptr->m_buff), "%s|%s|%d|"format"|end\r\n", logptr->head_str(),__FILE__,__LINE__,##args))>0?logptr->write(loglevel): -1

int log_stat(int loglevel, lua_State *l)
{
	CLogProxy *logobj = (CLogProxy *)lua_touserdata(l, lua_upvalueindex(1));
	const char *str = luaL_checkstring(l, -1);
	LOG_STAT_PTR(logobj, loglevel, "%s", str);
	return 0;
}

int log_debug(lua_State *l)
{
    return log_something(LOG_DEBUG, l);
}

int log_info(lua_State *l)
{
    return log_something(LOG_INFO, l);
}

int log_error(lua_State *l)
{
    return log_something(LOG_ERROR, l);
}

int log_ext_info(lua_State *l)
{
    return log_something(LOG_EXT_INFO, l);
}

int log_stat_data(lua_State *l)
{
	return log_stat(LOG_EXT_INFO, l);
}

extern "C"
int luaopen_log_c(lua_State *l)
{
    luaL_Reg funcs[] =
    {
        {"LOG_DEBUG", log_debug},
        {"LOG_INFO", log_info},
        {"LOG_ERROR", log_error},
        {"LOG_EXT_INFO", log_ext_info},
		{"LOG_STAT", log_stat_data},
        {NULL, NULL},
    };
    luaL_newlibtable(l, funcs);
    lua_getfield(l, LUA_REGISTRYINDEX, "log_obj");
    //lua_pushlightuserdata(l, xxx);
    luaL_setfuncs(l, funcs, 1);
    return 1;
}
