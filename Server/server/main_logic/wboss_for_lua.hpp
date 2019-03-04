#include <string.h>
extern "C"
{
    #include <lua.h>
    #include <lauxlib.h>
}

#include "world_boss_manager.h"
#include "log/log.h"

extern CWorldBossManager gWBossMgr;

static int get_cur_boss_info(lua_State *l)
{
	do 
	{
		std::string bossInfoBuf;
		WorldBossInfo bossInfo;
		gWBossMgr.getCurBossInfo(bossInfo);
		if( !bossInfo.SerializeToString(&bossInfoBuf) )
		{
			LOG(LOG_ERROR, "bossInfo.SerializeToString failed");
			break;
		}
		lua_pushlstring(l, bossInfoBuf.data(), bossInfoBuf.size());
		return 1;
	}while(0);

	lua_pushnil(l);
	return 1;
}

static int get_cur_boss_rank(lua_State *l)
{
	do 
	{
		//先检查参数
		if( lua_gettop(l) < 1 )
		{
			LOG(LOG_ERROR, "lua_gettop failed");
			break;
		}
		std::string listBuf;
		size_t ll = 0;
		const char *proBuf = lua_tolstring(l, 1, &ll);
		
		if( NULL == proBuf )
		{
			LOG(LOG_ERROR, "lua_tostring(l, 1) == NULL");
			break;
		}
		RankItemList list;
		if (!list.ParseFromString(string(proBuf, ll)))
		{
			LOG(LOG_ERROR, "list.ParseFromString failed");
			break;
		}
		gWBossMgr.getCurBossRank(list);
		if( !list.SerializeToString(&listBuf) )
		{
			LOG(LOG_ERROR, "list.SerializeToString failed");
			break;
		}
		lua_pushlstring(l, listBuf.data(), listBuf.size());
		return 1;
	} while (0);

	lua_pushnil(l);
	return 1;
}

static int get_boss_rank(lua_State *l)
{
	do 
	{
		//先检查参数
		if( lua_gettop(l) < 2 )
		{
			LOG(LOG_ERROR, "lua_gettop failed");
			break;
		}
		std::string listBuf;

		size_t ll = 0;
		const char *proBuf = lua_tolstring(l, 1, &ll);
		if( NULL == proBuf )
		{
			LOG(LOG_ERROR, "lua_tostring(l, 1) == NULL");
			break;
		}
		WBossHeadInfo bossHead;
		if (!bossHead.ParseFromString(string(proBuf, ll)))
		{
			LOG(LOG_ERROR, "bossHead.ParseFromString failed");
			break;
		}

		proBuf = lua_tolstring(l, 2, &ll);
		if( NULL == proBuf )
		{
			LOG(LOG_ERROR, "lua_tostring(l, 2) == NULL");
			break;
		}
		RankItemList list;
		if (!list.ParseFromString(string(proBuf, ll)))
		{
			LOG(LOG_ERROR, "list.ParseFromString failed");
			break;
		}
		gWBossMgr.getBossRank(bossHead, list);
		if( !list.SerializeToString(&listBuf) )
		{
			LOG(LOG_ERROR, "list.SerializeToString failed");
			break;
		}
		lua_pushlstring(l, listBuf.data(), listBuf.size());
		return 1;
	} while (0);

	lua_pushnil(l);
	return 1;
}

static int attack_boss(lua_State *l)
{
	do 
	{
		if( lua_gettop(l) < 1 )
		{
			LOG(LOG_ERROR, "lua_gettop failed");
			break;
		}
		//userName, nowTime, damage, totalDamage
		size_t ll = 0;
		const char *proBuf = lua_tolstring(l, 1, &ll);
		if( NULL == proBuf )
		{
			LOG(LOG_ERROR, "lua_tostring(l, 1) == NULL");
			break;
		}
		WBossAttackInfo atkInfo;
		if (!atkInfo.ParseFromString(string(proBuf, ll)))
		{
			LOG(LOG_ERROR, "atkInfo.ParseFromString failed");
			break;
		}

		bool isTeminated = false;
		long long ret = gWBossMgr.attackBoss(atkInfo, isTeminated);
		
		lua_pushinteger(l, ret);
		lua_pushboolean(l, isTeminated);
		return 2;
	} while (0);

	lua_pushnil(l);
	return 1;
}

int wboss_regist_lua_func(lua_State *l)
{
	lua_pushcfunction(l, get_cur_boss_info);
	lua_setglobal(l, "wboss_get_cur_boss");

	lua_pushcfunction(l, get_cur_boss_rank);
	lua_setglobal(l, "wboss_get_cur_boss_rank");

	lua_pushcfunction(l, get_boss_rank);
	lua_setglobal(l, "wboss_get_boss_rank");

	lua_pushcfunction(l, attack_boss);
	lua_setglobal(l, "wboss_attack_boss");

    return 0;
}
