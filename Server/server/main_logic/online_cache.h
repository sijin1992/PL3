#ifndef __ONLINE_CACHE_H__
#define __ONLINE_CACHE_H__

#include "common/shm_timer.h"
#include "logic/toolkit.h"
#include "common/msg_define.h"
#include "struct/hash_map.h"
#include "ini/ini_file.h"
#include "log/log.h"
#include "shm/shm_wrap.h"
#include <iostream>
using namespace std;
/*
*以在线用户为索引的信息
*/

#define ONLINE_CACHE_UNIT_STATE_NO_DATA 1
#define ONLINE_CACHE_UNIT_STATE_LOGINOK 0
#define DOMAIN_STRING_LEN 32
#define VERSION_STRING_LEN 32

#pragma pack(push)
#pragma pack(1)
struct ONLINE_CACHE_UNIT
{
	int userState; //状态，以便操作互斥
	int loginTime; //登录时间
	int lastActiveTime; //上次活动时间
	unsigned int selfCheckTimerID; //在线检查的定时器id
	unsigned int userip;
	char userdomain[DOMAIN_STRING_LEN];
	char userkey[USER_KEY_BUFF_LEN];
	char user_account[50];
	char reserve[49];
	
	inline void on_login(int state, unsigned int auserip, const string& auserkey, const string &auserdomain,
		const string &account)
	{
		userState = state;
		loginTime = time(NULL);
		lastActiveTime = loginTime;	
		selfCheckTimerID = 0;
		userip = auserip;
		snprintf(userdomain,sizeof(userdomain),"%s", auserdomain.c_str());
		snprintf(userkey,sizeof(userkey),"%s", auserkey.c_str());
		snprintf(user_account, sizeof(user_account), account.c_str());
	}

	inline void active()
	{	
		lastActiveTime = time(NULL);
	}

	inline int isActive(int timeout)
	{
		//两次检查期间内没有活跃挤下线
		if(timeout+lastActiveTime < time(NULL))
		{
			return -1;
		}

		return 0;
	}

	ONLINE_CACHE_UNIT();

	void debug(ostream& os);

};
#pragma pack(pop)

struct ONLINE_CACHE_CONFIG
{
	unsigned int nodeNum;
	unsigned int hashNum;
	unsigned int timerNum;
	key_t shmKey;
	key_t timershmkey;

	int read_from_ini(CIniFile& oIni, const char* sector="ONLINE_CACHE");

	void debug(ostream& os);
};

typedef CHashMap<USER_NAME, ONLINE_CACHE_UNIT, UserHashType> ONLINE_CACHE_MAP;

class COnlineCache
{
	public:
		COnlineCache();

		~COnlineCache();

		void info(ostream& os);

		int init(ONLINE_CACHE_CONFIG& config);

		int onLogin(int phase, USER_NAME& user, CToolkit* ptoolkit, int timeout, int level,
			unsigned int auserip, const string& auserkey, const string &auserdomain, const string &account);

		int onLogout(USER_NAME & user, CToolkit* ptoolkit);

		int onlineNum();

		//0=ok -1=fail
		//确保已经在线的情况下调用，不在线也是错误
		int getOnlineRef(USER_NAME & user, unsigned int& theIdx, ONLINE_CACHE_UNIT*& punit);

		//0=ok -1=fail
		//使用theIdx还原信息
		int checkRef(unsigned int theIdx, int timeout, USER_NAME & user, ONLINE_CACHE_UNIT*& punit);

		//0=ok -1=fail
		//punit = NULL not online, 调用此命令将更新活跃时间
		int getOnlineUnit(USER_NAME & user, ONLINE_CACHE_UNIT*& punit);


		//超过90%
		inline bool needCheck()
		{
			return m_inited && m_pmap->get_head()->curNodeNum > (m_pmap->get_head()->maxNodeNum/10)*9;
		}

		int cleanTimeoutNode(int timeout);

		inline ONLINE_CACHE_MAP* get_map()
		{
			return m_pmap;
		}

	protected:
		ONLINE_CACHE_MAP* m_pmap;
		bool m_inited;
		CShmWrapper m_shm;
};

#endif

