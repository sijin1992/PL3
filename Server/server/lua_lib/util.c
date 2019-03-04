#include <string.h>
#include <stdlib.h>
#include <iconv.h>

#include <lua.h>
#include <lauxlib.h>

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




#define OUTLEN 1024

int convert(char *dest_code, char *src_code, char *src, size_t slen, char *dest, size_t dlen)
{
    int ret = 0;
	iconv_t cd = iconv_open(dest_code, src_code);
	if(cd == (iconv_t)-1)
    {
        return -1;
    }
	memset(dest, 0, dlen);
	if(iconv(cd, &src, &slen, &dest, &dlen)) ret = -1;
	iconv_close(cd);
	return ret;
}

int convert_a2u(char *src, size_t slen, char *dest, size_t dlen)
{
    return convert("UTF-8", "GBK", src, slen, dest, dlen);
}

int convert_encoding(lua_State *l)
{
    if(lua_gettop(l) != 1 || lua_type(l, 1) != LUA_TSTRING)
	{
		lua_pushnil(l);
		return 1;
	}
    size_t s_len;
    const char *t_s_str = lua_tolstring(l, -1, &s_len);
    char s_str[s_len+1];
    strncpy(s_str, t_s_str, s_len);
    char d_str[OUTLEN];
    int ret = convert_a2u(s_str, s_len, d_str, OUTLEN);
    if(ret == 0)
        lua_pushstring(l, d_str);
    else
        lua_pushnil(l);
    return 1;
}

int luaopen_util_c(lua_State *l)
{
    luaL_Reg funcs[] =
    {
        {"convert_encoding", convert_encoding},
        {NULL, NULL},
    };
    luaL_newlibtable(l, funcs);
    luaL_setfuncs(l, funcs, 0);
    return 1;
}
