#include "data_cache/data_cache_api.h"
#include "ini/ini_file.h"
#include "dbsvr/login_lock.h"
#include <iostream>
#include <string>
using namespace std;
/*
* 查看db服务器状态的工具
*/

CDataCache gDataCache;
CLoginLock gLoginLock;

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

int show_login(CIniFile& oIni, const char* usr=NULL)
{
	LOGIN_LOCK_CONFIG loginLockConf;
	if(loginLockConf.read_from_ini(oIni, "LOGIN_LOCK")!=0)
	{
		cout << "loginLockConf.read_from_ini fail" << endl;
		return 0;
	}

	if(gLoginLock.init(loginLockConf, false)!=0)
	{
		cout << "gLoginLock.init fail" << endl;
		return 0;
	}

	if(usr)
		gLoginLock.info(cout, usr);
	else
		gLoginLock.info(cout);

	return 1;
}


int help(const char* self)
{
	cout << self << " [somedir/dbsvr.ini] [cmd]" << endl;
	cout << "cmd=cache (cache的状态)" << endl;
	cout << "cmd=login (loginlock的状态)" << endl;
	cout << "cmd=login userid (返回userid当前登录服务器)" << endl;
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
	else if(cmd == "login")
	{
		if(argc > 3)
			return show_login(oIni, argv[3]);
		else
			return show_login(oIni);
	}
	else
		return help(argv[0]);
	
	return 1;
}

