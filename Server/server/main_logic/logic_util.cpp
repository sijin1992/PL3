#include "logic_util.h"

#include <time.h>

#include "xml2lua/all_config.h"
#include "log/log.h"
#include "lua_manager.h"

using namespace std;

int get_day_hour(time_t *now_time, int* day, int* hour)
{
	struct tm nowtm;
	localtime_r(now_time, &nowtm);
	int nowday = (nowtm.tm_year + 1900) * 1000 + nowtm.tm_yday;
	if(day != NULL) *day = nowday;
	if(hour != NULL) *hour = nowtm.tm_hour;
	return 0;
}

int day_diff(int dayold, int daynew)
{
	int year1 = dayold/1000;
	int year2 = daynew/1000;
	int diff = 999;
	if(year2 == year1)
	{
		diff = daynew - dayold;
	}
	else if(year2 == year1+1)
	{
		int yearday = 365;
		if((year1 % 4==0 && year1 % 100!=0) || year1 % 400==0)
		{
			yearday = 366;
		}

		diff = (daynew - 1000) + yearday - dayold;
	}
	return diff;
}

int create_user(const USER_NAME& user_name, const RegistReq& req, UserInfo& user_info, ShipList& ship_list, ItemList& item_list, MailList& mail_list)
{
	string sUserInfo;
	string sShipList;
	string sItemList;
	string sMailList;
	lua_State *l = g_lua_env.global_state;
	int ret = 0;

	if(lua_gettop(l) != 0)
		LOG(LOG_ERROR, "%s|%d| call %s err: stack top is %u",__FILE__,__LINE__, "create_user", lua_gettop(l));

	lua_getglobal(l, "create_user");
	lua_pushstring(l, user_name.str());
	lua_pushstring(l, req.rolename().c_str());
	lua_pushinteger(l, req.lead());
	if(lua_pcall(l, 3, 4, 0) != 0)
	{
		LOG(LOG_ERROR, "%s|%d| func %s, call error %s",__FILE__,__LINE__, "create_user", lua_tostring(l, -1));
		lua_pop(l, 1);
		return -2;	//nick name err
	}

	size_t len = 0;
	const char *t = lua_tolstring(l, -4, &len);
	sUserInfo.assign(t, len);
	t = lua_tolstring(l, -3, &len);
	sShipList.assign(t, len);
	t = lua_tolstring(l, -2, &len);
	sItemList.assign(t, len);
	t = lua_tolstring(l, -1, &len);
	sMailList.assign(t, len);
	lua_pop(l,4);

	if(!user_info.ParseFromString(sUserInfo))
	{
		LOG(LOG_ERROR, "user_info.ParseFromString fail" );
		ret = -1;
	}
	if(!ship_list.ParseFromString(sShipList))
	{
		LOG(LOG_ERROR, "ship_list.ParseFromString fail" );
		ret = -1;
	}
	if(!item_list.ParseFromString(sItemList))
	{
		LOG(LOG_ERROR, "item_list.ParseFromString fail" );
		ret = -1;
	}
	if(!mail_list.ParseFromString(sMailList))
	{
		LOG(LOG_ERROR, "mail_list.ParseFromString fail" );
		ret = -1;
	}
	return ret;
}

int update_user(const USER_NAME& user_name, UserInfo& user_info, ShipList& ship_list, ItemList& item_list, MailList& mail_list)
{
	string sUserInfo;
	string sShipList;
	string sItemList;
	string sMailList;

	string sUserName(user_name.to_str());

	if(!user_info.SerializeToString(&sUserInfo))
	{
		LOG(LOG_ERROR, "sUserInfo.SerializeToString fail" );
	}
	if(!ship_list.SerializeToString(&sShipList))
	{
		LOG(LOG_ERROR, "sShipList.SerializeToString fail" );
	}
	if(!item_list.SerializeToString(&sItemList))
	{
		LOG(LOG_ERROR, "sItemList.SerializeToString fail" );
	}
	if(!mail_list.SerializeToString(&sMailList))
	{
		LOG(LOG_ERROR, "sMailList.SerializeToString fail" );
	}

	lua_State* L = g_lua_env.global_state;

	if (lua_gettop(L) != 0)
		LOG(LOG_ERROR, "%s|%d| call %s err: stack top is %u", __FILE__,__LINE__, "update_user", lua_gettop(L));

	lua_getglobal(L, "update_user");
	lua_pushlstring(L, sUserName.c_str(), sUserName.length());
	lua_pushlstring(L, sUserInfo.c_str(), sUserInfo.length());
	lua_pushlstring(L, sShipList.c_str(), sShipList.length());
	lua_pushlstring(L, sItemList.c_str(), sItemList.length());
	lua_pushlstring(L, sMailList.c_str(), sMailList.length());
	int ret;
	if (lua_pcall(L, 5, 5, 0) == 0)
	{
		ret = lua_tointeger(L, -5);
		size_t len = 0;
		const char* szRet = NULL;

		szRet = lua_tolstring(L, -4, &len);
		sUserInfo.assign(szRet, len);
		szRet = lua_tolstring(L, -3, &len);
		sShipList.assign(szRet, len);
		szRet = lua_tolstring(L, -2, &len);
		sItemList.assign(szRet, len);
		szRet = lua_tolstring(L, -1, &len);
		sMailList.assign(szRet, len);
		lua_pop(L, 5);
		LOG(LOG_INFO, "func update_user, %s, success", sUserName.c_str());
	}
	else
	{
		ret = -1;
		LOG(LOG_ERROR, "func update_user, call error %s", lua_tostring(L, -1));
	}

	if (ret == 1)
	{
		if(!user_info.ParseFromString(sUserInfo))
		{
			LOG(LOG_ERROR, "user_info.ParseFromString fail");
			if(user_info.ParsePartialFromString(sUserInfo))
			{
				LOG(LOG_ERROR, "user_info.ParsePartialFromArray: %s", user_info.DebugString().c_str());
			}
			else
			{
				LOG(LOG_ERROR, "user_info.ParsePartialFromArray fail");
			}
			ret = -1;
		}
		if(!ship_list.ParseFromString(sShipList))
		{
			LOG(LOG_ERROR, "ship_list.ParseFromString fail" );
			ret = -1;
		}
		if(!item_list.ParseFromString(sItemList))
		{
			LOG(LOG_ERROR, "item_list.ParseFromString fail" );
			ret = -1;
		}
		if(!mail_list.ParseFromString(sMailList))
		{
			LOG(LOG_ERROR, "mail_list.ParseFromString fail" );
			ret = -1;
		}
	}
	return ret;
}

/*int create_main_data(UserInfo &userinfo, int sex, USER_NAME &user_name,
	const std::string &nickname, KnightList &knight_bag, ItemList &item_list, MailList & mail_list,
	const RegistReq &req)
{
	string user_info_s;
	string knight_list_s;
	string item_list_s;
	string mail_list_s;
	lua_State *l = g_lua_env.global_state;
	int ret = 0;

	if(lua_gettop(l) != 0)
		LOG(LOG_ERROR, "%s|%d| call %s err: stack top is %u",__FILE__,__LINE__, "create_new_user", lua_gettop(l));
	lua_getglobal(l, "create_new_user");
	lua_pushstring(l, nickname.c_str());
	lua_pushinteger(l, sex);
	lua_pushstring(l, user_name.str());
	if(req.has_real_name())
		lua_pushstring(l, req.real_name().c_str());
	else
		lua_pushstring(l, "");
	if(req.has_mcc())
		lua_pushstring(l, req.mcc().c_str());
	else
		lua_pushstring(l, "");
	if(req.has_ip())
		lua_pushstring(l, req.ip().c_str());
	else
		lua_pushstring(l, "");

	lua_pushinteger(l, req.ext_info().real_money());
	lua_pushinteger(l, req.ext_info().money());

	if(lua_pcall(l, 8, 4, 0) != 0)
	{
		LOG(LOG_ERROR, "%s|%d| func %s, call error %s",__FILE__,__LINE__, "create_new_user", lua_tostring(l, -1));
		lua_pop(l, 1);
		return -2;	// nick name err
	}

	size_t len = 0;
	const char *t = lua_tolstring(l, -4, &len);
	user_info_s.assign(t, len);
	t = lua_tolstring(l, -3, &len);
	knight_list_s.assign(t, len);
	t = lua_tolstring(l, -2, &len);
	item_list_s.assign(t, len);
	t = lua_tolstring(l, -1, &len);
	mail_list_s.assign(t, len);
	lua_pop(l,4);

	if(!userinfo.ParseFromString(user_info_s))
	{
		LOG(LOG_ERROR, "userinfo.ParseFromString fail" );
		ret = -1;
	}
	//if(req.has_platform())
		//userinfo.set_platform(req.platform());
	if(req.has_version())
		userinfo.set_client_version(req.version());
	if(!knight_bag.ParseFromString(knight_list_s))
	{
		LOG(LOG_ERROR, "knight_list.ParseFromString fail" );
		ret = -1;
	}
	if(!item_list.ParseFromString(item_list_s))
	{
		LOG(LOG_ERROR, "item_list.ParseFromString fail" );
		ret = -1;
	}
	if(!mail_list.ParseFromString(mail_list_s))
	{
		LOG(LOG_ERROR, "mail_list.ParseFromString fail" );
		ret = -1;
	}
	return ret;
}

int update_user_info_when_login(USER_NAME &name, UserInfo& user_info, KnightList &knight_list, ItemList &item_list, MailList &mail_list, int &mail_num,
	HuodongList &huodong_list)
{
	string user_info_s;
	string item_list_s;
	string mail_list_s;
	string knight_list_s;
	if(!user_info.SerializeToString(&user_info_s))
	{
		LOG(LOG_ERROR, "theUserProto.SerializeToString fail" );
	}
	if(!knight_list.SerializeToString(&knight_list_s))
	{
		LOG(LOG_ERROR, "theUserProto.SerializeToString fail" );
	}
	if(!item_list.SerializeToString(&item_list_s))
	{
		LOG(LOG_ERROR, "theUserProto.SerializeToString fail" );
	}
	if(!mail_list.SerializeToString(&mail_list_s))
	{
		LOG(LOG_ERROR, "theUserProto.SerializeToString fail" );
	}

	int rank_idx = 0;
	int ret = 0;
	lua_State *gl = g_lua_env.global_state;
	//if(lua_gettop(gl) != 0)
	//	LOG(LOG_ERROR, "call get_rank_by_name err: stack top is %u", lua_gettop(gl));
	lua_getglobal(gl, "get_rank_by_name");
	const char *n = name.str();
	lua_pushlstring(gl, n, strlen(n));
	if(lua_pcall(gl, 1, 1, 0) != 0)
	{
		LOG(LOG_ERROR, "func get_rank_by_name, call error %s", lua_tostring(gl, -1));
		lua_pop(gl, 1);
		ret = -1;
	}
	else
	{
		rank_idx = lua_tointeger(gl, -1);
		lua_pop(gl,1);
	}
	if(ret == -1)
		return ret;

	lua_State *l = g_lua_env.global_state;

	if(lua_gettop(l) != 0)
		LOG(LOG_ERROR, "call update_when_login err: stack top is %u", lua_gettop(l));
	lua_getglobal(l, "update_when_login");
	lua_pushlstring(l, n, strlen(n));
	lua_pushlstring(l, user_info_s.c_str(),user_info_s.size());
	lua_pushlstring(l, knight_list_s.c_str(), knight_list_s.size());
	lua_pushlstring(l, item_list_s.c_str(),item_list_s.size());
	lua_pushlstring(l, mail_list_s.c_str(),mail_list_s.size());
	lua_pushinteger(l, rank_idx);
	if(lua_pcall(l, 6, 6, 0) != 0)
	{
		LOG(LOG_ERROR, "func update_when_login, call error %s", lua_tostring(l, -1));
		lua_pop(l, 1);
		ret = -1;
	}
	else
	{
		bool r = lua_toboolean(l, -6);
		if(r) ret = 1;
		else ret = 0;
		size_t len = 0;
		const char *t1 = lua_tolstring(l, -5, &len);
		user_info_s.assign(t1, len);
		const char *t4 = lua_tolstring(l, -4, &len);
		knight_list_s.assign(t4, len);
		const char *t2 = lua_tolstring(l, -3, &len);
		item_list_s.assign(t2, len);
		const char *t3 = lua_tolstring(l, -2, &len);
		mail_list_s.assign(t3, len);
		mail_num = lua_tointeger(l, -1);
		lua_pop(l,6);
	}

	if (ret == -1)
		return ret;
	if(!user_info.ParseFromString(user_info_s))
	{
		LOG(LOG_ERROR, "user_info.ParseFromString fail" );

		if(user_info.ParsePartialFromString(user_info_s))
		{
			LOG(LOG_ERROR, "user_info.ParsePartialFromArray: %s",  user_info.DebugString().c_str());
		}
		else
		{
			LOG(LOG_ERROR, "user_info.ParsePartialFromArray fail");
		}
		ret = -1;
	}
	if(!knight_list.ParseFromString(knight_list_s))
	{
		LOG(LOG_ERROR, "theUserProto.ParseFromString fail" );
		ret = -1;
	}
	if(!item_list.ParseFromString(item_list_s))
	{
		LOG(LOG_ERROR, "theUserProto.ParseFromString fail" );
		ret = -1;
	}
	if(!mail_list.ParseFromString(mail_list_s))
	{
		LOG(LOG_ERROR, "theUserProto.ParseFromString fail" );
		ret = -1;
	}
	if (ret == -1)
		return ret;

	lua_getglobal(l, "get_huodong_list");
	lua_pushlstring(l, user_info_s.c_str(),user_info_s.size());
	if(lua_pcall(l, 1, 1, 0) != 0)
	{
		LOG(LOG_ERROR, "func get_huodong_list, call error %s", lua_tostring(l, -1));
		lua_pop(l, 1);
		ret = -1;
	}
	else
	{
		size_t len = 0;
		const char *t1 = lua_tolstring(l, -1, &len);
		string huodong_list_s;
		huodong_list_s.assign(t1, len);
		user_info_s.assign(t1, len);
		lua_pop(l,1);
		if(!huodong_list.ParseFromString(huodong_list_s))
		{
			LOG(LOG_ERROR, "theUserProto.ParseFromString fail" );
			ret = -1;
		}
	}
	return ret;
}*/


