#include "data_cache/data_cache_api.h"
#include "main_logic/online_cache.h"
#include "ini/ini_file.h"
#include "common/user_distribute.h"
#include <iostream>
#include <string>
#include "common/shm_timer.h"
using namespace std;
/*
* 查看逻辑服务器状态的工具
*/

COnlineCache gOnlineCache;
CDataCache gDataCache;
CUserDistribute gDistribute; 
CShmTimer<unsigned int> gTheTimer;

class COnlineVisitor:public CHashMapVisitor<USER_NAME, ONLINE_CACHE_UNIT>
{
	public:
		virtual ~COnlineVisitor(){}
		int call(const TYPE_KEY& key, TYPE_VAL& val ,int callTimes)
		{
			cout << "openid=" << key.str() << endl;
			val.debug(cout);
			return 0;
		}
};


int show_dbcache(CIniFile& oIni)
{
	DATA_CACHE_CONFIG cacheConfig;
	if(cacheConfig.read_from_ini(oIni, "CACHE")!=0)
	{
		cout << "cacheConfig.read_from_ini fail" << endl;
		return 0;
	}

	int ret = gDataCache.init(cacheConfig, false);
	if(ret != 0)
	{
		cout << "gDBCache init fail" << endl;
		return 0;
	}

	gDataCache.info(cout);
	
	return 1;
}

int show_online(CIniFile& oIni, int detail)
{
	ONLINE_CACHE_CONFIG onlineCacheConfig;
	if(onlineCacheConfig.read_from_ini(oIni, "ONLINE_CACHE")!=0)
	{
		cout << "onlineCacheConfig.read_from_ini fail" << endl;
		return 0;
	}
	onlineCacheConfig.debug(cout);

	int ret = gOnlineCache.init(onlineCacheConfig);
	if(ret != 0)
	{
		cout << "gOnlineCache init fail" << endl;
		return 0;
	}

	gOnlineCache.info(cout);

	ret = gTheTimer.init(onlineCacheConfig.timershmkey, onlineCacheConfig.timerNum);
	if(ret != 0)
	{
		cout << "gTheTimer init fail" << endl;
		return 0;
	}

	gTheTimer.get_timer()->get_head()->debug(cout);

	if(detail)
	{
		ONLINE_CACHE_MAP* p = gOnlineCache.get_map();
		COnlineVisitor visitor;
		p->for_each_node(&visitor);
	}
	
	return 1;
}

int show_dist(CIniFile& oIni)
{
	int ret = gDistribute.init(oIni, "DISTRIBUTE");
	if(ret != 0)
	{
		cout << "gDistribute init fail" << endl;
		return 0;
	}

	gDistribute.info(cout);
	return 1;
}



int help(const char* self)
{
	cout << self << " [somedir/main_logic.ini] [cmd]" << endl;
	cout << "cmd=cache 查看二级cache的状态" << endl;
	cout << "cmd=online 查看在线的状态 [detail=0]" << endl;
	cout << "cmd=dist 查看db分布的状态" << endl;
	return 0;
}

int main(int argc, char** argv)
{
	if(argc < 3)
	{
		return help(argv[0]);
	}

	CIniFile oIni(argv[1]);
	if(!oIni.IsValid())
	{
		cout << "read ini " << argv[1] << "fail" << endl;
		return 0;
	}

	string cmd = argv[2];
	
	if(cmd == "cache")
		return show_dbcache(oIni);
	else if(cmd == "online")
	{
		int detail = 0;
		if(argc > 3)
		{
			detail = atoi(argv[3]);
		}
		return show_online(oIni, detail);
	}
	else if(cmd == "dist")
		return show_dist(oIni);
	else if(cmd ==  "userpool")
		return show_userpool(oIni);
	else
		return help(argv[0]);
	
	return 1;
}

