#include "linker_config.h"
#include "linker_process.h"
#include <sstream>
using namespace std;

int gDebug = 0;
int gStopFlag = 0;
static void stophandle(int iSigNo)
{
	gStopFlag = 1;
	LOG(LOG_INFO, "recieve siganal %d, stop",  iSigNo);
	LOG(LOG_ERROR, "recieve siganal %d, stop",  iSigNo);
}

static void usr1handle(int iSigNo)
{
	gDebug = (gDebug+1)%2;
	cout << "gDebug=" << gDebug << endl;
}

int main(int argc, char** argv)
{
	if(argc < 3)
	{
		cout << argv[0] << " linker.ini pipe_ini" << endl;
		return 0;
	}

	CIniFile oIni(argv[1]);
	if(!oIni.IsValid())
	{
		cout <<  "read ini "<< argv[1] << " fail" << endl;
		return 0;
	}

	
    //log
    LOG_CONFIG logConf(oIni, "TCP_LINKER");
    logConf.debug(cout);
    LOG_CONFIG_SET(logConf);
    cout << "log open=" << LOG_OPEN_DEFAULT(NULL) << " " << LOG_GET_ERRMSGSTRING << endl;

	//config
	CLinkerConfig config;
	if(config.read_from_ini(oIni)!=0)
	{
		cout << "CLinkerConfig read_from_ini fail" << endl;
		return 0;
	}
	config.debug(cout);

	//pipe
	CPIPEConfigInfo pipeconfig;
	if(pipeconfig.set_config(argv[2])!= 0)
	{
		cout << "parse ini fail " << endl;
		return 0;
	}

	
	//lock & daemon
	if(CServerTool::run_by_ini(&oIni, "TCP_LINKER")!=0)
	{
		cout << "run_by_ini  fail" << endl;
		return 0;
	}

	//signal
	CServerTool::sighandle(SIGTERM, stophandle);
	CServerTool::sighandle(SIGUSR1, usr1handle);
	CServerTool::ignore(SIGPIPE);

	CLinkerProcess theProcess;
	
	if(theProcess.init(config,pipeconfig)!=0)
	{
		cout << "theProcess.init fail" << endl;
		return 0;
	}

	if(theProcess.main_loop()!=0)
	{
		return -1;
	}
	return 1;
}

