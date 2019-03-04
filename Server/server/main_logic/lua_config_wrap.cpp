#include "lua_config_wrap.h"

#include <string.h>
#include <stdlib.h>

#include "lua_manager.h"
#include "log/log.h"


int get_config_data_by_id(const char *config_tab, int id, char ** data)
{
	if(*data != NULL)
	{// 理论上不应该出现异常情况，因为这个函数只会被精心设计的固定代码调用
		return -1;
	}
	int ret = 0;
	lua_State *l = g_lua_env.global_state;
	/*
	printf("id_________\n");
	for (int i = 1; i <= lua_gettop(l); ++i)
	{
		int t = lua_type(l,i);
		switch(t)
		{
		case LUA_TSTRING:
			printf("str : %s\n", lua_tostring(l,i));
			break;
		case LUA_TBOOLEAN:
			printf(lua_toboolean(l,i)?"true\n":"false\n");
			break;
		case LUA_TNUMBER:
			printf("num : %f\n", lua_tonumber(l, i));
			break;
		default:
			printf("%s\n", lua_typename(l,t));
			break;
		}
	}
	printf("---------end\n");
	*/
	lua_gettabledata(l, config_tab, "get_data_by_idx");
	lua_pushinteger(l, id);
	lua_pcall(l, 1, 1, 0);
	//LOG(LOG_DEBUG, "end, stack = %d", lua_gettop(l));
	if(lua_isstring(l,-1))
	{
		size_t len = 0;
		const char *p = lua_tolstring(l, -1, &len);
		if(p == NULL)
		{
			ret = -1;
		}
		else
		{
			// 这里分配的空间会被精心设计的固定代码释放，不用担心
			*data = (char *)malloc(len + 1);
			memcpy(*data, p, len);
			(*data)[len] = '\0';
		}
	}
	else
	{
		ret = -1;
	}
	lua_pop(l, 1);
	return ret;
}

int get_config_data_by_real_id(const char *config_tab, int id, char ** data)
{
	if(*data != NULL)
	{// 理论上不应该出现异常情况，因为这个函数只会被精心设计的固定代码调用?
		return -1;
	}
	int ret = 0;
	lua_State *l = g_lua_env.global_state;
	/*
	printf("realid_________\n");
	for (int i = 1; i <= lua_gettop(l); ++i)
	{
		int t = lua_type(l,i);
		switch(t)
		{
		case LUA_TSTRING:
			printf("str : %s\n", lua_tostring(l,i));
			break;
		case LUA_TBOOLEAN:
			printf(lua_toboolean(l,i)?"true\n":"false\n");
			break;
		case LUA_TNUMBER:
			printf("num : %f\n", lua_tonumber(l, i));
			break;
		default:
			printf("%s\n", lua_typename(l,t));
			break;
		}
	}
	printf("---------end\n");
	*/
	lua_gettabledata(l, config_tab, "get_data_by_real_idx");
	//LOG(LOG_DEBUG, "meddle, stake = %d(1)", lua_gettop(l));
	lua_pushinteger(l, id);
	lua_pcall(l, 1, 1, 0);
	//LOG(LOG_DEBUG, "end, stake = %d(1)", lua_gettop(l));
	if(lua_isstring(l,-1))
	{
		size_t len = 0;
		const char *p = lua_tolstring(l, -1, &len);
		if(p == NULL)
		{
			ret = -1;
		}
		else
		{
			// 这里分配的空间会被精心设计的固定代码释放，不用担心
			*data = (char *)malloc(len + 1);
			memcpy(*data, p, len);
			(*data)[len] = '\0';
		}
	}
	else
	{
		ret = -1;
	}
	lua_pop(l, 1);
	return ret;
}


int cut_config_data(char *data, char ** fields, int field_num, const char *table_name)
{
	if(data == NULL)
		return -1;
	char *p = data;
	fields[0] = p;
	int i = 1;
	while(*p != 0)
	{
		if(*p == ';')
		{
			*p = 0;
			if(*(p+1) != 0)
			{
				fields[i] = p + 1;
				++i;
				++p;
				if(i > field_num)
					break;
			}
			else
			{
				break;
			}
		}
		else
		{
			++p;
		}
	}
	if(i != field_num)
	{
		LOG(LOG_ERROR, "%s get_field err, i = %d, field_num = %d", table_name, i, field_num);
		return -1;
	}
	return 0;
}

int cut_sub_data(int *data, int len, char *str)
{
	int i = 0;
	char *p = str;
	data[0] = atoi(p);
	i = 1;
	p++;
	while(*p != '\0')
	{
		if(*(p - 1) == ',')
		{
			if(i == len)
			{// 数据项超标了
				return -1;
			}
			data[i++] = atoi(p);
		}
		p++;
	}
	for(; i < len; ++i)
	{
		data[i] = -1;
	}
	return 0;
}


