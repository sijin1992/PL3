#include "ini/ini_file.h"
#include <iostream>
#include <string>
#include <stdlib.h>
#include "connect/session_auth/connect_map.h"
#include <stdlib.h>
using namespace std;
/*
* 查看逻辑服务器状态的工具
*/

CSessionMap gSessionMap;

class CSessionUserVisitor:public CHashMapVisitor<USER_NAME, CSessionMap::USER_ENTRY>
{
	public:
		virtual ~CSessionUserVisitor(){}
		int call(const TYPE_KEY& key, TYPE_VAL& val ,int callTimes)
		{
			cout << "openid=" << key.str() << endl;
			cout << "openkey=" << val.userKey.str() << ",viplevel=" << val.viplevel<< ",vipyear=" << val.vipyear << endl;
			cout << "sessionid=" << val.sessionID << endl;
			return 0;
		}
};

class CSessionSessionVisitor:public CHashMapVisitor<unsigned long long, USER_NAME>
{
	public:
		virtual ~CSessionSessionVisitor(){}
		int call(const TYPE_KEY& key, TYPE_VAL& val ,int callTimes)
		{
			cout << "sessionid=" << key << endl;
			cout << "openid=" << val.str() << endl;
			return 0;
		}
};


void show_map(int detail)
{
	cout << "--------------------user map info-----------------------" << endl;
	gSessionMap.get_user_map()->get_head()->debug(cout);
	if(detail)
	{
		CSessionUserVisitor visitor;
		gSessionMap.get_user_map()->for_each_node(&visitor);
	}
	
	cout << "--------------------session map info-----------------------" << endl;
	gSessionMap.get_session_map()->get_head()->debug(cout);
	if(detail)
	{
		CSessionSessionVisitor visitor;
		gSessionMap.get_session_map()->for_each_node(&visitor);
	}
}

void show_user(const char* username)
{
	USER_NAME user;
	user.str(username, strlen(username));
	CSessionMap::USER_ENTRY entry;
	
	int ret = gSessionMap.get_user(user, entry);
	if(ret < 0)
	{
		cout << "get entry for " << user.str() << " fail" << endl;
		return;
	}
	else if(ret == 0)
	{
		cout << user.str() << " not in usermap" << endl;
		return;
	}
	else
	{
		cout << "user(" << user.str() << ") entry:" << endl;
		cout << "fd=" << entry.fd  << endl;
		cout << "sessionID=" << entry.sessionID<< endl;
		cout << "userName=" << entry.userName.str() << endl;
		cout << "userKey=" << entry.userKey.str() << endl;
		cout << "state=" << entry.state << endl;
		cout << "viplevel=" << entry.viplevel << endl;
		cout << "vipyear=" << entry.vipyear << endl;
	}

	USER_NAME user2;
	ret = gSessionMap.get_session(entry.sessionID,user2);
	if(ret < 0)
	{	
		cout << "get_session for " << entry.sessionID << " fail" << endl;
		return;
	}
	else if(ret == 0)
	{
		cout << "sessionID=" << entry.sessionID << " not in sessionmap" << endl;
		return;
	}
	else
	{
		cout << "session(" << entry.sessionID << ") user=" << user2.str() << endl;
		if(user != user2)
		{
			cout << "user(" << user.str() << ") != userInSessionMap(" << user2.str() << ")" << endl;
		}
	}
}

int help(const char* self)
{
	cout << self << " [somedir/connect.ini] [cmd]" << endl;
	cout << "cmd=map(查看sessionmap状态) [detail=0]" << endl;
	cout << "cmd=user(查看user状态) [username]" << endl;
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

	unsigned int shmkey_map;
	if(oIni.GetInt("SESSION_AUTH", "SESSION_MAP_KEY", 0, &shmkey_map)!=0)
	{
		cout << "SESSION_AUTH.SESSION_MAP_KEY not found" << endl;
		return 0;
	}

	unsigned int mapUserNum = 0;
	if(oIni.GetInt("SESSION_AUTH", "SESSION_MAP_NODE_NUM", 10000, &mapUserNum)!=0)
	{
		cout << "SESSION_AUTH.SESSION_MAP_NODE_NUM not found" << endl;
		return 0;
	}

	unsigned int mapHashNum = 0;
	if(oIni.GetInt("SESSION_AUTH", "SESSION_MAP_HASH_NUM", 10000, &mapHashNum)!=0)
	{
		cout << "SESSION_AUTH.SESSION_MAP_HASH_NUM not found" << endl;
		return 0;
	}

	cout << "init with key(" << hex << shmkey_map << dec << ") and user=" << mapUserNum << " hash=" << mapHashNum << endl;
	int ret = gSessionMap.init(shmkey_map, mapUserNum, mapHashNum);
	if(ret != 0)
	{
		cout << "gSessionMap.init fail" << endl;
		return 0;
	}

	string cmd = argv[2];

	if(cmd == "map")
	{
		int detail = 0;
		if(argc > 3)
			detail = atoi(argv[3]);
		show_map(detail);
	}
	else if(cmd == "user")
	{
		if(argc < 4)
		{
			cout << "need username" << endl;
			return help(argv[0]);
		}
		show_user(argv[3]);
	}
	else
	{
		cout << "bad cmd" << endl;
		return help(argv[0]);
	}

	return 1;
}

