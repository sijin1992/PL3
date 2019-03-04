#include "lua_cmd_handle.h"

#include <string>
#include <string.h>
#include <stdio.h>

#include "lua_manager.h"
#include "log/log.h"

using namespace std;

map<unsigned int, LUA_handle> *g_lua_cmd_map;

lua_State *try_load(const char *path, const char *file)
{
	return g_lua_env.global_state;
	int path_len = strlen(path);
	int file_len = strlen(file);
	char temp[path_len + file_len + 1];
	memcpy(temp, path, path_len);
	memcpy(temp + path_len, file, file_len);
	temp[path_len + file_len] = 0;
	FILE *f = fopen(temp, "rb");
	if(f == NULL)
		return NULL;
	fclose(f);
	lua_State *l = lua_newthread(g_lua_env.global_state);
	int r = luaL_dofile(l, temp);
	if(r == 0/*LUA_OK*/)
	{
		return l;
	}
	else
	{
		LOG(LOG_ERROR, "%s", lua_tostring(l, 1));
		lua_close(l);
		return NULL;
	}
}

int lua_load_handles(const char *path, 
	std::map<unsigned int, LUA_handle>& cmd_map)
{
	//std::map<string, lua_State *> temp_index;
	//std::map<string, lua_State *>::iterator idx_it;
	//std::map<unsigned int, LUA_handle>::iterator map_it;
	//string file;
	//string module;
	
	lua_State *l = g_lua_env.l;
	lua_State *gl = g_lua_env.global_state;
	lua_getglobal(l, "reg");
	lua_pushnil(l);
	while(lua_next(l, -2) != 0)
	{// 遍历reg数组
		int keytype = lua_type(l, -2);
		if(keytype != LUA_TNUMBER)
		{
			LOG(LOG_ERROR, "invalid cmd pair in reg_cmd.lua");
			return -1;
		}
		// TODO:这里应该加入类型判断
		int key = lua_tointeger(l, -2);
		/*const char *value = lua_tostring(l, -1);
		
		file = value;
		unsigned pos = file.find(":");
		if(pos != string::npos)
		{
			file = file.substr(0, pos);
			module = string(value).substr(pos + 1);
		}
		else
		{
			LOG(LOG_ERROR, "lua:cmd %d,function err", key);
			return -1;
		}*/
		if(cmd_map.find(key) != cmd_map.end())
		{// 不应该重复注册同一个消息
			LOG(LOG_ERROR, "lua:cmd %d repeated", key);
			return -1;
		}
		/*
		file += ".lua";
		lua_State *hl;
		idx_it = temp_index.find(file);
		if(idx_it != temp_index.end())
		{// 一个文件一个state，如果同一个文件中有多个module，共用state
			hl = idx_it->second;
		}
		else
		{
			hl = try_load(path, file.c_str());
			if(hl == NULL)
			{
				LOG(LOG_ERROR, "%s load err", file.c_str());
			}
			if(hl != NULL)
				temp_index[file] = hl;
		}
		if(hl != NULL)
		{*/
			LUA_handle handle;
			//handle.file = string(path) + file;
			//handle.module = module;
			//handle.feature_function = module + "_feature";
			//handle.do_logic_function = module + "_do_logic";
			handle.l = gl;//hl;
			cmd_map[key] = handle;
			//printf("%x %s:%s,%p\n",key, handle.file.c_str(),handle.feature_function.c_str(),
			//	handle.l);
		/*}
		else
		{
			return -1;
		}*/
		lua_pop(l, 1);
		
	}
	lua_pop(l, 1);
	g_lua_cmd_map = &cmd_map;
	return 0;
}

