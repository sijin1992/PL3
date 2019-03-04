#include <iostream>
#include "ini/ini_file.h"
#include "log/log.h"
#include "logic/driver.h"

using namespace std;

//!!todo: modify 
#include "logic_template.h"
#include "logic_template_uniq.h"

#define INI_LOG_SECTOR "SERVERXXX"
#define INI_LISTEN_QUEUE_SECTOR "SERVERXXX"
#define INI_LISTEN_QUEUE_ITEM "LISTEN_QUEUE_ID"
#define INI_DRIVER_SECTOR "LOGIC_DRIVER"
#define INI_SERVER_TOOL_SECTOR "SERVERXXX"
#define BOOL_ACTIVE false
//!!end

int gListenQueueID=0;

CLogicDriver gDriver;
int gDebug=0;

static void stophandle(int iSigNo)
{
	gDriver.stopFlag = 1;
	LOG(LOG_INFO, "recieve siganal %d, stop",  iSigNo);
	LOG(LOG_ERROR, "recieve siganal %d, stop",  iSigNo);
}

static void usr1handle(int iSigNo)
{
	gDebug = (gDebug+1)%2;
	cout << "gDebug=" << gDebug << endl;
}


static int regist_all_handles()
{
	//!!to-do regist handles
	/*
	//cmd should return RET_YIELD
	if(gDriver.regist_handle(CMD_XXX, CLogicCreator(new CLogicXXX))!=0)
	{
		return 0;
	}

	//cmd should not return RET_YIELD
	if(gDriver.regist_handle(CMD_XXX, CLogicCreator(new CLogicXXX, true))!=0)
	{
		return 0;
	}

	*/
	
	return 1;
}

int main(int argc, char **argv)
{	
	int ret = 0;
	//!!todo: modify if you have other arg
	if(argc < 3)
	{
		cout << argv[0] << " server_ini pipe_ini" << endl;
		return 0;
	}

	//server conf
	CIniFile oIni(argv[1]);
	if(!oIni.IsValid())
	{
		cout <<  "read ini "<< argv[1] << " fail" << endl;
		return 0;
	}

	//open log
    LOG_CONFIG logConf(oIni, INI_LOG_SECTOR);
    logConf.debug(cout);
    LOG_CONFIG_SET(logConf);
    cout << "log open=" << LOG_OPEN_DEFAULT(NULL) << " " << LOG_GET_ERRMSGSTRING << endl;

	//listen queue id
	if(oIni.GetInt(INI_LISTEN_QUEUE_SECTOR, INI_LISTEN_QUEUE_ITEM, 0, &gListenQueueID)!=0)
	{
	 	cout << INI_LISTEN_QUEUE_SECTOR"."INI_LISTEN_QUEUE_ITEM" not found" << endl;
		return 0;
	}
	
	//pipe config
	CPIPEConfigInfo pipeconfig;
	if(pipeconfig.set_config(argv[2])!= 0)
	{
		cout << "CPIPEConfigInfo config fail " << endl;
		return 0;
	}

	//init driver
	CDequePIPE listenPipe;
	if(listenPipe.init(pipeconfig, gListenQueueID, BOOL_ACTIVE) != 0)
	{
		cout << "listenPipe init " << listenPipe.errmsg() << endl;
		return 0;
	}
	CMsgQueuePipe listenQueue(listenPipe, &gDebug);

	if(gDriver.add_msg_queue(gListenQueueID, &listenQueue)!=0)
	{
		return 0;
	}

	if(regist_all_handles()!=1)
	{
		return 0;
	}


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

