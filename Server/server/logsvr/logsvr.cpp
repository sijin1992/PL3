#include <iostream>
#include "ini/ini_file.h"
#include "log/log.h"
#include "logic/driver.h"
#include <time.h>
#include <map>
using namespace std;

//!!todo: modify 
#include "time/interval_ms.h"
#include "mysql_proxy.h"

#include "logic_logproxy.h"

CMysqlProxy gMysqlProxy;

unsigned int MSG_QUEUE_ID_LOG = 0; 

int LOCK_PERIOD = 0;

int gDebugFlag = 0;
#define INI_LOG_SECTOR "LOG_SVR"
#define INI_LISTEN_QUEUE_SECTOR "LOG_SVR"
#define INI_LISTEN_QUEUE_ITEM "LISTEN_QUEUE_ID"
#define INI_DRIVER_SECTOR "LOGIC_DRIVER"
#define INI_SERVER_TOOL_SECTOR "LOG_SVR"

#define INI_MYSQL_PROXY_CONFIG_SECTOR "MYSQL_PROXY"


#define GLOBAL_SRV_REGIST_CMD(cmdName, className) \
	if(gDriver.regist_handle(cmdName, CLogicCreator(new className))!=0) \
{ \
	return 0; \
}

#define LOG_SRV_REGIST_CMD_UNIQ(cmdName, className) \
	if(gDriver.regist_handle(cmdName, CLogicCreator(new className, true))!=0) \
{ \
	return 0; \
}

class CGlobalLogicDriver: public CLogicDriver
{
public:
	CGlobalLogicDriver()
	{
		loopTimes = 0;
	}

	CToolkit *getToolkit()
	{
		return &m_toolkit;
	}
	
	virtual int hook_loop_end()
	{
		if(++loopTimes >= 100)
		{
			loopTimes = 0;
		}
		if( gMysqlProxy.update(time(NULL)) != 0)
		{
			LOG(LOG_ERROR, "gMysqlProxy.update failed");
			return 0;
		}
		return 0;
	}
	
protected:
	int loopTimes;
	CIntervalMs intvlMs;
};

CGlobalLogicDriver gDriver;

static void stophandle(int iSigNo)
{
	gDriver.stopFlag = 1;
	LOG(LOG_INFO, "recieve siganal %d, stop",  iSigNo);
	LOG(LOG_ERROR, "recieve siganal %d, stop",  iSigNo);
}

static void usr1handle(int iSigNo)
{
	gDebugFlag = (gDebugFlag+1)%2;
	cout << "gDebug=" << gDebugFlag << endl;
}


int main(int argc, char **argv)
{	
	int ret = 0;
	//!!todo: modify if you have other arg
	if(argc < 3)
	{
		cout << argv[0] << "log_config_ini pipe_conf_ini" << endl;
		return 0;
	}

	//server conf
	CIniFile oIni(argv[1]);
	if(!oIni.IsValid())
	{
		cout <<  "read server ini "<< argv[1] << " fail" << endl;
		return 0;
	}

	//open log
	LOG_CONFIG logConf(oIni, INI_LOG_SECTOR);
	logConf.debug(cout);
	LOG_CONFIG_SET(logConf);
	cout << "log open=" << LOG_OPEN_DEFAULT(NULL) << " " << LOG_GET_ERRMSGSTRING << endl;
	
	CMysqlProxyConfig mysqlProxyConf;
	if( mysqlProxyConf.read_from_ini(oIni, INI_MYSQL_PROXY_CONFIG_SECTOR) != 0 )
	{
		cout << "mysqlProxyConf.read_from_ini failed" << endl;
		return 0;
	}

	if( gMysqlProxy.init(mysqlProxyConf) != 0 )
	{
		cout << "gMysqlProxy.init() failed" << endl;
		return 0;
	}

	//pipe config
	CPIPEConfigInfo pipeconfig;
	if(pipeconfig.set_config(argv[2])!= 0)
	{
		cout << "CPIPEConfigInfo config fail " << endl;
		return 0;
	}

	if(oIni.GetInt(INI_LISTEN_QUEUE_SECTOR, INI_LISTEN_QUEUE_ITEM, 0, &MSG_QUEUE_ID_LOG)!=0)
	{
		cout << "LOGSRV.MSG_QUEUE_ID_LOG not found" << endl;
		return 0;
	}
	cout << INI_LISTEN_QUEUE_ITEM << "=" << MSG_QUEUE_ID_LOG << endl;

	//init driver
	CDequePIPE pipeLogic;
	ret = pipeLogic.init(pipeconfig, MSG_QUEUE_ID_LOG, false);
	if(ret != 0)
	{
		cout << "pipeLogic.init " << pipeLogic.errmsg() << endl;
		return 0;
	}
	CMsgQueuePipe queuePipeLogic(pipeLogic, &gDebugFlag);


	if(gDriver.add_msg_queue(MSG_QUEUE_ID_LOG, &queuePipeLogic)!=0)
	{
		return 0;
	}
	
	LOG_SRV_REGIST_CMD_UNIQ(CMD_GAME_LOG_REPORT_REQ, CLogicLogProxy)

	CLogicDriverConfig configDriver;
	ret = configDriver.readFromIni(oIni, INI_DRIVER_SECTOR);
	if(ret < 0)
	{
		cout << "CLogicDriverConfig readFromIni fail" << endl;
		return 0;
	}
	
	ret = gDriver.init(configDriver);
	if(ret != 0)
	{
		cout << "init fail" << endl;
		return 0;
	}

	//lock & daemon
	if(CServerTool::run_by_ini(&oIni, INI_SERVER_TOOL_SECTOR)!=0)
	{
		cout << "run_by_ini  fail" << endl;
		return 0;
	}

	//signal
	CServerTool::sighandle(SIGTERM, stophandle);
	CServerTool::sighandle(SIGUSR1, usr1handle);

	cout << argv[0] << " main_loop=" << gDriver.main_loop(-1) << endl;
		
	return 1;
}

