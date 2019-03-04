#include <lua.h>
#include <lauxlib.h>
#include <stdint.h>

#include "mmap_module.h"
#include <string.h>

struct mem_head
{
	int32_t total_count;	// 总的记录条数
};

struct node
{
	char name[40];
	char nick_name[40];
	int32_t power;
	int16_t level;
	int8_t sex;
	int8_t star;
	int32_t reputation;
};

struct snapshot
{
	int32_t max_count;
	struct mem_head *head;
	struct node *start;
	int fd;
	size_t size;
};


static int check_load_mmap(const char *file_name, int32_t max_count, struct snapshot *ss)
{
	size_t size = sizeof(struct mem_head) + sizeof(struct node) * max_count;
	struct mmap_struct ret;
	if(open_mmap(file_name, size, &ret) != 0)
	{
		return -1;
	}	
	ss->head = (struct mem_head *)ret.mem;
	ss->start = (struct node *)(ss->head + 1);
	ss->max_count = max_count;
	ss->fd = ret.fd;
	ss->size = size;
	if(ret.isnew == 1)
		ss->head->total_count = 0;
	return 0;
}

static int save_close_mmap(struct snapshot *ss)
{
	close_mmap(ss->head, ss->size, ss->fd);
	return 0;
}

static int add_rank_data(int idx, struct node *data, struct snapshot *ss)
{
	if(idx > (ss->head->total_count + 1) || idx <= 0)
		return -1;
	int new_total = ss->head->total_count + 1;
    int remove_old = 0;
	if(new_total > ss->max_count)
    {
		new_total = ss->max_count;
        remove_old = 1;
    }
    if (remove_old == 0)
        memcpy((void *)(ss->start + new_total - 1), (void *)(ss->start + idx - 1), sizeof(struct node));
    
	memcpy((void *)(ss->start + idx - 1), data, sizeof(struct node));
	++ss->head->total_count;
	return 0;
}

static int force_modify_data(int idx, struct node *data, struct snapshot *ss)
{
	if(idx > (ss->head->total_count) || idx <= 0)
		return -1;
	memcpy((void *)(ss->start + idx - 1), data, sizeof(struct node));
	return 0;
}


static int change_rank(int idx1, int idx2, struct snapshot *ss)
{
	if(idx1 > ss->head->total_count ||
		idx2 > ss->head->total_count)
		return -1;
	struct node temp = ss->start[idx1 - 1];
	ss->start[idx1 - 1] = ss->start[idx2 - 1];
	ss->start[idx2 - 1] = temp;
	return 0;
}

void create_node_on_stack(struct node *data, lua_State *l)
{
	lua_newtable(l);
	lua_pushstring(l, "name");
	lua_pushstring(l, data->name);
	lua_rawset(l, -3);
	lua_pushstring(l, "nickname");
	lua_pushstring(l, data->nick_name);
	lua_rawset(l, -3);
	lua_pushstring(l, "power");
	lua_pushinteger(l, data->power);
	lua_rawset(l, -3);
	lua_pushstring(l, "level");
	lua_pushinteger(l, data->level);
	lua_rawset(l, -3);
	lua_pushstring(l, "sex");
	lua_pushinteger(l, data->sex);
	lua_rawset(l, -3);
	lua_pushstring(l, "reputation");
	lua_pushinteger(l, data->reputation);
	lua_rawset(l, -3);
	lua_pushstring(l, "star");
	lua_pushinteger(l, data->star);
	lua_rawset(l, -3);
}

int fill_node_from_stack(struct node *data, lua_State *l, int idx)
{
	struct node t;
	lua_pushstring(l, "name");
	lua_rawget(l, idx);
	if(lua_type(l, -1) == LUA_TSTRING)
	{
		strncpy(t.name, lua_tostring(l, -1), 32);
		t.name[32] = 0;
		lua_pop(l, 1);
	}
	else
	{
		lua_pop(l,1);
		return -1;
	}
	lua_pushstring(l, "nickname");
	lua_rawget(l, idx);
	if(lua_type(l, -1) == LUA_TSTRING)
	{
		strncpy(t.nick_name, lua_tostring(l, -1), 32);
		t.nick_name[32] = 0;
		lua_pop(l, 1);
	}
	else
	{
		lua_pop(l,1);
		return -1;
	}
	lua_pushstring(l, "power");
	lua_rawget(l, idx);
	if(lua_type(l, -1) == LUA_TNUMBER)
	{
		t.power = lua_tointeger(l, -1);
		lua_pop(l,1);
	}
	else
	{
		lua_pop(l,1);
		return -1;
	}
	lua_pushstring(l, "level");
	lua_rawget(l, idx);
	if(lua_type(l, -1) == LUA_TNUMBER)
	{
		t.level = lua_tointeger(l, -1);
		lua_pop(l,1);
	}
	else
	{
		lua_pop(l,1);
		return -1;
	}
	lua_pushstring(l, "sex");
	lua_rawget(l, idx);
	if(lua_type(l, -1) == LUA_TNUMBER)
	{
		t.sex = lua_tointeger(l, -1);
		lua_pop(l,1);
	}
	else
	{
		lua_pop(l,1);
		return -1;
	}
	lua_pushstring(l, "reputation");
	lua_rawget(l, idx);
	if(lua_type(l, -1) == LUA_TNUMBER)
	{
		t.reputation = lua_tointeger(l, -1);
		lua_pop(l,1);
	}
	else
	{
		lua_pop(l,1);
		return -1;
	}
	lua_pushstring(l, "star");
	lua_rawget(l, idx);
	if(lua_type(l, -1) == LUA_TNUMBER)
	{
		t.star = lua_tointeger(l, -1);
		lua_pop(l,1);
	}
	else
	{
		lua_pop(l,1);
		return -1;
	}
	memcpy(data, &t, sizeof(t));
	return 0;
}

int lua_load_rank(lua_State *l)
{
	if(lua_gettop(l) != 3 || lua_type(l, 1) != LUA_TTABLE || lua_type(l, 2) != LUA_TSTRING || lua_type(l, 3) != LUA_TNUMBER)
	{
		lua_pushboolean(l, 0);
		return 1;
	}

	const char *file_name = lua_tostring(l, 2);
	int max_count = lua_tointeger(l, 3);

	struct snapshot *ss = lua_newuserdata(l, sizeof(struct snapshot));
	ss->fd = -1;
	ss->head = NULL;
	luaL_getmetatable(l, "rank_list_c");
	lua_setmetatable(l, -2);


	int ret = check_load_mmap(file_name, max_count, ss);
	if(ret != 0)
	{
		lua_pushboolean(l, 0);
		return 2;
	}
	for(int i = 0; i < ss->head->total_count; ++i)
	{
		create_node_on_stack(&(ss->start[i]), l);
		lua_rawseti(l, 1, i+1);
	}
	lua_pushboolean(l, 2);
	
	return 2;
}

int lua_add_rank(lua_State *l)
{
	if(lua_gettop(l) != 3 || lua_type(l, 1) != LUA_TUSERDATA || lua_type(l, 2) != LUA_TNUMBER || lua_type(l, 3) != LUA_TTABLE)
	{
		lua_pushboolean(l, 0);
		return 1;
	}
	int idx = lua_tointeger(l, 2);
	
	struct snapshot *ss = (struct snapshot *)lua_touserdata(l, 1);
	struct node t;
	if(fill_node_from_stack(&t, l, 3) != 0)
	{
		lua_pushboolean(l, 0);
		return 1;
	}
	if(add_rank_data(idx, &t, ss) != 0)
	{
		lua_pushboolean(l, 0);
		return 1;
	}
	lua_pushboolean(l, 1);
	return 1;
}

int lua_force_modify(lua_State *l)
{
	if(lua_gettop(l) != 3 || lua_type(l, 1) != LUA_TUSERDATA || lua_type(l, 2) != LUA_TNUMBER || lua_type(l, 3) != LUA_TTABLE)
	{
		lua_pushboolean(l, 0);
		return 1;
	}
	int idx = lua_tointeger(l, 2);
	
	struct snapshot *ss = (struct snapshot *)lua_touserdata(l, 1);
	struct node t;
	if(fill_node_from_stack(&t, l, 3) != 0)
	{
		lua_pushboolean(l, 0);
		return 1;
	}
	if(force_modify_data(idx, &t, ss) != 0)
	{
		lua_pushboolean(l, 0);
		return 1;
	}
	lua_pushboolean(l, 1);
	return 1;
}


int lua_change_rank(lua_State *l)
{
	if(lua_gettop(l) != 3 || lua_type(l, 1) != LUA_TUSERDATA || lua_type(l, 2) != LUA_TNUMBER || lua_type(l, 3) != LUA_TNUMBER)
	{
		lua_pushboolean(l, 0);
		return 1;
	}
	int idx1 = lua_tointeger(l, 2);
	int idx2 = lua_tointeger(l, 3);
	
	struct snapshot *ss = (struct snapshot *)lua_touserdata(l, 1);

	if(change_rank(idx1, idx2, ss) != 0)
	{
		lua_pushboolean(l, 0);
		return 1;
	}
	lua_pushboolean(l, 1);
	return 1;
}

int lua_modify_data(lua_State *l)
{
    if(lua_gettop(l) != 4 || lua_type(l, 1) != LUA_TUSERDATA || lua_type(l, 2) != LUA_TNUMBER || lua_type(l, 3) != LUA_TNUMBER || lua_type(l, 4) != LUA_TNUMBER)
	{
		lua_pushboolean(l, 0);
		return 1;
	}
    int idx = lua_tointeger(l, 2);
	int type = lua_tointeger(l, 4);
	int value = lua_tointeger(l, 3);
	
	struct snapshot *ss = (struct snapshot *)lua_touserdata(l, 1);

    if(idx > ss->head->total_count)
    {
        lua_pushboolean(l, 0);
		return 1;
    }
    //type:1=power 1=level 2=star 3=reputation
    if(type < 0 || type > 3)
    {
        lua_pushboolean(l, 0);
		return 1;
    }
    switch(type)
    {
    case 0:
        ss->start[idx - 1].power = value;
        break;
    case 1:
        ss->start[idx - 1].level = value;
        break;
    case 2:
        ss->start[idx - 1].star = value;
        break;
    case 3:
        ss->start[idx - 1].reputation = value;
        break;
    }
    lua_pushboolean(l, 1);
	return 1;
}


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



int rank_list_gc(lua_State *l)
{
	struct snapshot *ss = (struct snapshot*)lua_touserdata(l, 1);
	save_close_mmap(ss);
	return 0;
}

int luaopen_rank_module_c(lua_State *l)
{
	luaL_newmetatable(l, "rank_list_c");
	lua_pushstring(l, "__gc");
	lua_pushcfunction(l, rank_list_gc);
	lua_settable(l, -3);
	
    luaL_Reg funcs[] =
    {
        {"load", lua_load_rank},
        {"add_rank", lua_add_rank},
        {"change_rank", lua_change_rank},
        {"modify", lua_modify_data},
        {"force_modify", lua_force_modify},
        {NULL, NULL},
    };
    luaL_newlibtable(l, funcs);
    luaL_setfuncs(l, funcs, 0);
    return 1;
}


