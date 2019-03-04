#ifndef __MAIN_LOGIC_DB_USERGROUP_H__
#define __MAIN_LOGIC_DB_USERGROUP_H__

#include "logic/driver.h"
#include "login_lock.h"
#include "proto/Group.pb.h"
#include "data_cache/data_cache_api.h"
#include <time.h>

class CLogicDBUserGroup:public CLogicProcessor
{
public:
	CLogicDBUserGroup()
	{
	}

	virtual void on_init();
	
	//有msg到达的时候激活对象
	virtual int on_active(CLogicMsg& msg);
	
	//对象销毁前调用一次
	virtual void on_finish();
	
	virtual CLogicProcessor* create();


protected:

	inline void dump_req_msg(CLogicMsg& msg, USER_NAME& user, unsigned int cmd)
	{
		char* delmem = m_dumpMsgBuff;
		m_dumpMsgLen = msg.dump(m_dumpMsgBuff);
		if(delmem)
		{
			delete[] delmem;
		}

		m_saveCmd = cmd;
		m_saveName = user;
	}

	int send_resp(CLogicMsg& msg, int code=-1);

	int try_get(CLogicMsg& msg);

	int on_get(CLogicMsg& msg, CLogicMsg* dbmsg=NULL);
	
	//int on_list(CLogicMsg& msg);

	int on_timeout(CLogicMsg& msg);

	int on_set(CLogicMsg& msg);	
	
	int try_create(CLogicMsg& msg);
	
	int on_create(CLogicMsg& msg, CLogicMsg& dbmsg);
	
protected:

	//timer id
	unsigned int m_timerID;
	//前端过来的请求副本
	char* m_dumpMsgBuff;
	int m_dumpMsgLen;
	//cache 操作
	CDataCacheDB m_dbcache;
	//缓存的set
	CDataBlockSet m_theSet;
	//特殊命令
	unsigned int m_specialCmd;
	//保存用户id
	USER_NAME m_saveName;
	//保存命令
	unsigned int m_saveCmd;
	//保存id
//#ifndef USE_USERID_AS_GROUPID
	USER_NAME m_saveGroupid;
//#endif
	//UserGroupListResp m_listresp;
};

#endif
