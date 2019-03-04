/*
* 用户身份认证的server
*/
#include "struct/common_def.h"
#include "common/msg_define.h"
#include "logic_auth_task.h"
#include "logic_log_task.h"
#include "logic_notify_logic_info.h"
#include "logic_userinfo_report.h"
#include "process_manager/process_manager.h"
#include "select_server.h"
#include "string/strutil.h"
#include "vector"

int gDebug = 0;
using namespace std;

unsigned int MSG_QUEUE_ID_AUTH;
unsigned int MSG_QUEUE_ID_LOGIC_TASK;
CServerSelector gServerSelector;
unsigned short PORTAL_SERVER_PORT;
CQQLogAdapter gadapter;
int gCloseLog;

CLogicDriver driver;
static void stophandle(int iSigNo)
{
	driver.stopFlag = 1;
	LOG(LOG_INFO, "recieve siganal %d, stop",  iSigNo);
	LOG(LOG_ERROR, "recieve siganal %d, stop",  iSigNo);
}

static void usr1handle(int iSigNo)
{
	gDebug = (gDebug+1)%2;
	cout << "gDebug=" << gDebug << endl;
}

class CGatewayManager: public CProcessManager
{
public:
	CGatewayManager()
	{
	}
	
protected:
	virtual int entity( int argc, char *argv[] )
	{
		//开始run吧
		cout << "auth_task main_loop=" << driver.main_loop(-1) << endl;
		return 0;
	}
};


int main(int argc, char** argv)
{
	if(argc < 3)
	{
		cout << argv[0] << " auth_config_ini pipe_conf_ini" << endl;
		return 0;
	}

	CIniFile oIni(argv[1]);
	if(!oIni.IsValid())
	{
		cout << "read ini " << argv[1] << "fail" << endl;
		return 0;
	}

	//log
	LOG_CONFIG logConf(oIni, "GATEWAY");
	logConf.debug(cout);
	LOG_CONFIG_SET(logConf);
	cout << "log open=" << LOG_OPEN("gateway", LOG_DEBUG) << " " << LOG_GET_ERRMSGSTRING << endl;

	//并发数量
	int procNum;
	if(oIni.GetInt("GATEWAY", "PROC_NUM", 0, &procNum)!=0)
	{
	 	cout << "GATEWAY.PROC_NUM not found" << endl;
		return 0;
	}

	//portal 配置
	char buff[128];
	int tmpport;
	int t;
	if(oIni.GetInt("GATEWAY", "PORTAL_TYPE", 0, &t)!=0)
	{
	 	cout << "GATEWAY.PORTAL_TYPE not found" << endl;
		return 0;
	}

	if(oIni.GetInt("GATEWAY", "PORTAL_SERVER_PORT", 0, &tmpport)!=0)
	{
	 	cout << "GATEWAY.PORTAL_SERVER_PORT not found" << endl;
		return 0;
	}
	PORTAL_SERVER_PORT = tmpport;

	//默认的server set
	if(oIni.GetString("GATEWAY", "PORTAL_URL", "", buff, sizeof(buff))!=0)
	{
	 	cout << "GATEWAY.PORTAL_URL not found" << endl;
		return 0;
	}
	string host = buff;

	if(oIni.GetString("GATEWAY", "PORTAL_SERVER_IP", "", buff, sizeof(buff))!=0)
	{
	 	cout << "GATEWAY.PORTAL_SERVER_IP not found" << endl;
		return 0;
	}
	string PORTAL_SERVER_IP = buff;
	strutil::Tokenizer token(PORTAL_SERVER_IP, ",");
	while(token.nextToken())
	{
		gServerSelector.add_server(0, token.getToken(), host);
	}

	//output
	cout << "Portal: type=" << t << ", " << PORTAL_SERVER_IP.c_str() << ":" << PORTAL_SERVER_PORT << " " << host << endl;

	/*
	if(oIni.GetString("GATEWAY", "PORTAL_OTHER_PLATFORMS", "", buff, sizeof(buff))!=0)
	{
	 	cout << "GATEWAY.PORTAL_OTHER_PLATFORMS not found" << endl;
		return 0;
	}
	cout << "other platform: " << buff << endl;
	
	string plats = buff;
	strutil::Tokenizer tokenplat(plats, ",");
	char itemname[32] = {0};
	while(tokenplat.nextToken())
	{
		int idx = atoi(tokenplat.getToken().c_str());
		if(idx == 0)
		{
			cout << "invalid idx " << idx << endl;
			return 0;
		}

		snprintf(itemname, sizeof(itemname), "PORTAL_URL_%d", idx);
		if(oIni.GetString("GATEWAY", itemname, "", buff, sizeof(buff))!=0)
		{
			cout << "GATEWAY." << itemname << " not found" << endl;
			return 0;
		}
		string plathost = buff;
		
		snprintf(itemname, sizeof(itemname), "PORTAL_SERVER_IP_%d", idx);
		if(oIni.GetString("GATEWAY", itemname, "", buff, sizeof(buff))!=0)
		{
			cout << "GATEWAY." << itemname << " not found" << endl;
			return 0;
		}
		
		string platservers = buff;
		strutil::Tokenizer tokenservers(platservers, ",");
		while(tokenservers.nextToken())
		{
			gServerSelector.add_server(idx, tokenservers.getToken(), plathost);
			cout << "plat(" << idx << ") add server " << tokenservers.getToken() << " " << plathost << endl;
		}
	}
	*/
	if(oIni.GetString("GATEWAY", "LOCAL_SERVER_IP", "", buff, sizeof(buff))!=0)
	{
	 	cout << "GATEWAY.LOCAL_SERVER_IP not found" << endl;
		return 0;
	}
	string serverIP = buff;
	cout << "LocalSvrIP:" << serverIP << endl;

	/*
	if(gadapter.init(serverIP, &gDebug) !=0)
	{
		cout << "CQQLogAdapter init fail" << endl;
		LOG(LOG_ERROR, "CQQLogAdapter init fail");
		return 0;
	}
	*/

	//配置server
	//pipe config
	CPIPEConfigInfo pipeconfig;
	if(pipeconfig.set_config(argv[2])!= 0)
	{
		cout << "parse ini fail " << endl;
		return 0;
	}
	
	if(oIni.GetInt("GATEWAY", "GLOBE_PIPE_ID_AUTH", 0, &MSG_QUEUE_ID_AUTH)!=0)
	{
	 	cout << "GATEWAY.GLOBE_PIPE_ID_AUTH not found" << endl;
		return 0;
	}

	oIni.GetInt("GATEWAY", "CLOSE_REPORT_LOG", 0, &gCloseLog);

	cout << "MSG_QUEUE_ID_AUTH=" << MSG_QUEUE_ID_AUTH << endl;

	if(oIni.GetInt("GATEWAY", "GLOBE_PIPE_ID_LOGIC_TASK", 0, &MSG_QUEUE_ID_LOGIC_TASK)!=0)
	{
		cout << "GATEWAY.GLOBE_PIPE_ID_LOGIC_TASK not found" << endl;
		return 0;
	}

	cout << "MSG_QUEUE_ID_LOGIC_TASK=" << MSG_QUEUE_ID_LOGIC_TASK << endl;

	CDequePIPE pipeAuth;
	int ret = pipeAuth.init(pipeconfig, MSG_QUEUE_ID_AUTH, false);
	if(ret != 0)
	{
		cout << "pipeAuth.init " << pipeAuth.errmsg() << endl;
		return 0;
	}
	CMsgQueuePipe queuePipeAuth(pipeAuth, &gDebug);

	if(driver.add_msg_queue(MSG_QUEUE_ID_AUTH, &queuePipeAuth)!=0)
	{
		return 0;
	}

	CDequePIPE pipeLogicTask;
	ret = pipeLogicTask.init(pipeconfig, MSG_QUEUE_ID_LOGIC_TASK, false);
	if(ret != 0)
	{
		cout << "pipeLogicTask.init " << pipeLogicTask.errmsg() << endl;
		return 0;
	}
	CMsgQueuePipe queueLogicTask(pipeLogicTask, &gDebug);

	if(driver.add_msg_queue(MSG_QUEUE_ID_LOGIC_TASK, &queueLogicTask)!=0)
	{
		return 0;
	}

	if(driver.regist_handle(CMD_AUTH_REQ, CLogicCreator(new CLogicAuth, true))!=0)
	{
		return 0;
	}

	/*
	if(driver.regist_handle(CMD_GATEWAY_LOG_REPORT_REQ, CLogicCreator(new CLogicQQLog, true))!=0)
	{
		return 0;
	}
	*/

	if(driver.regist_handle(CMD_NOTIFY_LOGIC_INFO_REQ, CLogicCreator(new CLogicNotifyLogicInfo, true))!=0)
	{
		return 0;
	}
	if(driver.regist_handle(CMD_NOTIFY_GLOBALCB_REQ, CLogicCreator(new CLogicNotifyLogicInfo, true))!=0)
	{
		return 0;
	}
	if(driver.regist_handle(CMD_GATEWAY_USERINFO_REPORT_REQ, CLogicCreator(new CLogicUserInfoReport, true))!=0)
	{
		return 0;
	}
	
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
	if(CServerTool::run_by_ini(&oIni, "GATEWAY")!=0)
	{
		cout << "run_by_ini  fail" << endl;
		return 0;
	}
	CServerTool::sighandle(SIGTERM, stophandle);
	CServerTool::sighandle(SIGUSR1, usr1handle);

	CGatewayManager manager;
	manager.attach_stop_flag((int*)(&(driver.stopFlag)));
	manager.set_child_num(procNum);
	if(manager.run(argc, argv)!=manager.SUCCESS)
	{
		return 0;
	}

	return 1;
}

