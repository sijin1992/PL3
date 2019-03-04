/*
* db svr负责从 
*/
#include "lua52wrap.h"

#include "data_cache/data_cache_api.h"
#include <iostream>
#include "ini/ini_file.h"
#include "log/log.h"
#include "lock/lock_sem.h"
#include "logic/msg_queue.h"
#include "mysql_wrap/mysql_wrap.h"
#include "process_manager/process_manager.h"
#include "common/server_tool.h"
#include "logic_db.h"
//#include "logic_feeds.h"
//#include "logic_leitaidb.h"
//#include "logic_dbgroupuser.h"
#include <sstream>
#include "login_lock.h"
#include "logic_dbgroupuser.h"

lua_State *g_general_state;
//#include "logic_notify.h"
using namespace std;

int gMysqlTimeout = 1;
CDataCache gDataCache;
CDataCache gDataCacheGroup;
int gDebug = 0;
unsigned int MSG_QUEUE_ID_FROM_LOGIC = 0;
unsigned int MSG_QUEUE_ID_TO_MYSQL = 0;

CLoginLock gLoginLock;

#define WRITE_BACK_LOG_COUNT 1000

class CDataCacheWriteBackDB: public CDataCacheWriteBack
{
	public:
		CDataCacheWriteBackDB()
		{			
			m_pqueueMysql = NULL;
		}

		void bind_queue(CMsgQueuePipe* pqueueMysql)
		{
			m_pqueueMysql = pqueueMysql;
		}

		//返回一个可用的DataBlockSet
		virtual DataBlockSet* get_obj()
		{
			DataBlockSet& theBlockSet = m_theSet.get_clear_obj();
			return &theBlockSet;
		}
		
		//获取成功，返回的是有修改的数据
		//如果return=0 数据将被标记成未修改
		virtual int on_get_ok(USER_NAME& user, DataBlockSet* pdataSet) 
		{
			pdataSet->set_noresp(1);
			if(m_toolkit.send_protobuf_msg(gDebug, *pdataSet,
				m_cmd, user, m_pqueueMysql) != 0)
				return -1;
			return 0;
		}

		inline void set_cmd(unsigned int cmd)
		{
			m_cmd = cmd;
		}

	protected:
		CDataBlockSet m_theSet;
		CMsgQueuePipe* m_pqueueMysql;
		CToolkit m_toolkit;
		unsigned int m_cmd;
};

CDataCacheWriteBackDB gWriteBack;
CDataCacheWriteBackDB gWriteBackGroup;


class CLogicDBDriver: public CLogicDriver
{
public:
	virtual int hook_loop_end()
	{
		//检查淘汰和回写
		int timeoutcnt;
		gDataCache.check_release(&gWriteBack);
		if(gDataCache.check_write_back_timeout(&gWriteBack, timeoutcnt) == gDataCache.RET_OK)
		{
			m_timeoutcnt += timeoutcnt;
			m_timeoutxxx += timeoutcnt;
			if(m_timeoutxxx > WRITE_BACK_LOG_COUNT)
			{
				m_timeoutxxx -= WRITE_BACK_LOG_COUNT;
				LOG(LOG_INFO, "WRITE_BACK_CNT|%lu", m_timeoutcnt);
			}
		}
		gDataCacheGroup.check_release(&gWriteBackGroup);
		if(gDataCacheGroup.check_write_back_timeout(&gWriteBackGroup, timeoutcnt) == gDataCacheGroup.RET_OK)
		{
			m_timeoutcnt += timeoutcnt;
			m_timeoutxxx += timeoutcnt;
			if(m_timeoutxxx > WRITE_BACK_LOG_COUNT)
			{
				m_timeoutxxx -= WRITE_BACK_LOG_COUNT;
				LOG(LOG_INFO, "WRITE_BACK_CNT|%lu", m_timeoutcnt);
			}
		}
		return 0;
	}
public:
	unsigned long m_timeoutcnt;
	int m_timeoutxxx;
};

CLogicDBDriver driver;

static void stophandle(int iSigNo)
{
	driver.stopFlag = 1;
	LOG(LOG_INFO, "recieve siganal %d, stop",  iSigNo);
	LOG(LOG_ERROR, "recieve siganal %d, stop",  iSigNo);
}

static void statushandle(int iSigNo)
{
	ostringstream os;
	gDataCache.info(os);
	LOG(LOG_DEBUG, "%s", os.str().c_str());
}

static void usr1handle(int iSigNo)
{
	gDebug = (gDebug+1)%2;
	cout << "gDebug=" << gDebug << endl;
}

#define MAIN_LOGIC_REGIST_CMD(cmdName, className) \
if(driver.regist_handle(cmdName, CLogicCreator(new className))!=0) \
{ \
	return 0; \
}

#define MAIN_LOGIC_REGIST_CMD_UNIQ(cmdName, className) \
if(driver.regist_handle(cmdName, CLogicCreator(new className, true))!=0) \
{ \
	return 0; \
}


int main(int argc, char **argv)
{
	if(argc < 4)
	{
		cout << argv[0] << " dbsvr.ini pipe_ini forceFormat(0 or 1) [group id start num = 1]" << endl;
		return 0;
	}

	CIniFile oIni(argv[1]);
	if(!oIni.IsValid())
	{
		cout <<  "read ini "<< argv[1] << " fail" << endl;
		return 0;
	}

	bool forceFormat = false;
	if(atoi(argv[3]) == 1)
	{
		forceFormat = true;
	}

	//log
	LOG_CONFIG logConf(oIni, "DBSVR");
	logConf.debug(cout);
	LOG_CONFIG_SET(logConf);
	cout << "log open=" << LOG_OPEN_DEFAULT(NULL) << " " << LOG_GET_ERRMSGSTRING << endl;
	//lua
	setenv("LUA_PATH", "../../../bin/db/dbsvr/lua/?.lua;../../../bin/logic/main_logic/lua/?.lua"
	";../../../bin/logic/main_logic/lua/logic/?.lua", 1);
	setenv("LUA_CPATH", "../../../bin/logic/main_logic/lua/?.so", 1);
	lua_State *l = luaL_newstate();
	luaL_openlibs(l);
	int r = luaL_dofile(l, "../../../bin/db/dbsvr/lua/logic.lua");
	if(r != 0/*LUA_OK*/)
	{
		cout << "load logic.lua err," << lua_tostring(l, -1) << endl;
		return 0;
	}
	g_general_state = l;

	//timeout
	oIni.GetInt("DBSVR", "MYSQL_TIME_OUT_S", 1, &gMysqlTimeout);
	cout << "mysql timeout=" << gMysqlTimeout << "s" << endl;

	//loginlock init
	LOGIN_LOCK_CONFIG loginLockConf;
	if(loginLockConf.read_from_ini(oIni, "LOGIN_LOCK")!=0)
	{
		cout << "loginLockConf.read_from_ini fail" << endl;
		return 0;
	}
	loginLockConf.debug(cout);
	
	if(gLoginLock.init(loginLockConf, forceFormat)!=0)
	{
		cout << "gLoginLock.init fail" << endl;
		return 0;
	}

	//cache config
	DATA_CACHE_CONFIG dataCacheConfig;
	DATA_CACHE_CONFIG dataCacheGroupConfig;
	if(dataCacheConfig.read_from_ini(oIni, "CACHE")!=0)
	{
		cout << "config.read_from_ini fail" << endl;
		return 0;
	}
	dataCacheConfig.debug(cout);

	if(dataCacheGroupConfig.read_from_ini(oIni, "CACHE_USERGROUP")!=0)
	{
		cout << "config.read_from_ini fail" << endl;
		return 0;
	}
	dataCacheGroupConfig.debug(cout);

	if(oIni.GetInt("DBSVR", "GLOBE_QUEUE_ID", 0, &MSG_QUEUE_ID_FROM_LOGIC)!=0)
	{
	 	cout << "DBSVR.GLOBE_QUEUE_ID not found" << endl;
		return 0;
	}

	if(oIni.GetInt("MYSQL_HELPER", "GLOBE_QUEUE_ID", 0, &MSG_QUEUE_ID_TO_MYSQL)!=0)
	{
	 	cout << "MYSQL_HELPER.GLOBE_QUEUE_ID not found" << endl;
		return 0;
	}

	//init cache
	int ret = gDataCache.init(dataCacheConfig, forceFormat, &gDebug);
	if(ret != 0)
	{
		cout << "gDataCache init fail" << endl;
		return 0;
	}
	ret = gDataCacheGroup.init(dataCacheGroupConfig, forceFormat, &gDebug);
	if(ret != 0)
	{
		cout << "gDataCacheGroup init fail" << endl;
		return 0;
	}

	//queue pipe
	CPIPEConfigInfo pipeconfig;
	if(pipeconfig.set_config(argv[2])!= 0)
	{
		cout << "parse ini fail " << endl;
		return 0;
	}

	CDequePIPE pipeLogic;
	if(pipeLogic.init(pipeconfig, MSG_QUEUE_ID_FROM_LOGIC, false) != 0)
	{
		cout << "pipeLogic init " << pipeLogic.errmsg() << endl;
		return 0;
	}
	CMsgQueuePipe queueLogic(pipeLogic, &gDebug);

	CDequePIPE pipeMysql;
	if(pipeMysql.init(pipeconfig, MSG_QUEUE_ID_TO_MYSQL, true) != 0)
	{
		cout << "pipeLogic init " << pipeMysql.errmsg() << endl;
		return 0;
	}
	CMsgQueuePipe queueMysql(pipeMysql, &gDebug);
	gWriteBack.bind_queue(&queueMysql);
	gWriteBack.set_cmd(CMD_DBCACHE_SET_REQ);
	gWriteBackGroup.bind_queue(&queueMysql);
	gWriteBackGroup.set_cmd(CMD_DBCACHE_SET_USERGROUP_REQ);

	if(driver.add_msg_queue(MSG_QUEUE_ID_FROM_LOGIC, &queueLogic)!=0)
	{
		return 0;
	}

	if(driver.add_msg_queue(MSG_QUEUE_ID_TO_MYSQL, &queueMysql)!=0)
	{
		return 0;
	}

	MAIN_LOGIC_REGIST_CMD(CMD_DBCACHE_CREATE_REQ,CLogicDB)
	MAIN_LOGIC_REGIST_CMD(CMD_DBCACHE_GET_REQ,CLogicDB)
	MAIN_LOGIC_REGIST_CMD(CMD_DBCACHE_SET_REQ,CLogicDB)
	MAIN_LOGIC_REGIST_CMD(CMD_DBCACHE_LOGIN_GET_REQ,CLogicDB)
	MAIN_LOGIC_REGIST_CMD(CMD_DBCACHE_LOGOUT_REQ,CLogicDB)

	MAIN_LOGIC_REGIST_CMD(CMD_DBCACHE_SEND_MAIL_REQ, CLogicDB)
	MAIN_LOGIC_REGIST_CMD(CMD_CDKEY_INNER_REQ, CLogicDB)
	MAIN_LOGIC_REGIST_CMD(CMD_QUERY_BEFORE_REGIST_REQ, CLogicDB)

	MAIN_LOGIC_REGIST_CMD(CMD_DBCACHE_CREATE_USERGROUP_REQ, CLogicDBUserGroup)
	MAIN_LOGIC_REGIST_CMD(CMD_DBCACHE_GET_USERGROUP_REQ, CLogicDBUserGroup)
	MAIN_LOGIC_REGIST_CMD(CMD_DBCACHE_SET_USERGROUP_REQ, CLogicDBUserGroup)
	//MAIN_LOGIC_REGIST_CMD(CMD_DBCACHE_LIST_USERGROUP_REQ, CLogicDBUserGroup)
	
	//init diver
	CLogicDriverConfig configDriver;
	ret = configDriver.readFromIni(oIni);
	if(ret < 0)
	{
		cout << "CLogicDriverConfig readFromIni fail" << endl;
		return 0;
	}
	
	ret = driver.init(configDriver);
	if(ret != 0)
	{
		cout << "init fail" << endl;
		return 0;
	}
	
	//lock & daemon
	if(CServerTool::run_by_ini(&oIni, "DBSVR")!=0)
	{
		cout << "run_by_ini  fail" << endl;
		return 0;
	}

	//signal
	CServerTool::sighandle(SIGTERM, stophandle);
	CServerTool::sighandle(SIGUSR1, usr1handle);
	CServerTool::sighandle(SIGUSR2, statushandle);

	//开始
	cout << "main_loop=" << driver.main_loop(-1) << endl;
	return 1;
}


