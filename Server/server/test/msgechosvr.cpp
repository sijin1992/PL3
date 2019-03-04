#include "net/tcpwrap.h"
#include <errno.h>
#include <string.h>
#include <iostream>
#include "time/calculagraph.h"
#include "../logic/msg.h"
#include "../logic/msg_queue.h"
#include "../logic/toolkit.h"
#include <iostream>
using namespace std;

int gstop = 0;
static void stophandle(int iSigNo)
{
	gstop = 1;
	cout << "recv signal(" << iSigNo << ") stop=" << gstop << endl;
}


int main(int argc, char** argv)
{
	//与server相反
	if(argc < 6)
	{
		cout << argv[0] << "somedir/queue_pipe.ini queueid isactive selfid desid" << endl;
	}
	
	//pipe
	CPIPEConfigInfo pipeconfig;
	if(pipeconfig.set_config(argv[1])!= 0)
	{
		cout << "parse ini fail " << endl;
		return 0;
	}

	bool isactive = atoi(argv[3]) > 0;
	
	CDequePIPE pipe;
	int ret = pipe.init(pipeconfig, atoi(argv[2]), isactive);
	if(ret != 0)
	{
		cout << "pipe.init=" << ret << " " << pipe.errmsg();
		return 0;
	}
	CMsgQueuePipe msgpipe(pipe) ;

	//signal
	CServerTool::sighandle(SIGTERM, stophandle);
	CServerTool::ignore(SIGPIPE);

	unsigned int serverID;
	unsigned int desServerID;
	CTcpSocket::str_to_addr(argv[4], serverID);
	CTcpSocket::str_to_addr(argv[5], desServerID);
	CToolkit toolkit;
	toolkit.init(NULL, NULL, serverID);
	int readnum = 0;
	int writefailnum = 0;
	int writenum = 0;
	USER_NAME user;
	user.str("12345", 5);
	
	CCalculagraph cc(cout);
	while(!gstop)
	{
		//轮询之
		if(isactive)
		{
			if(toolkit.send_bin_msg_to_queue(1, user, &msgpipe, 0, desServerID) !=0)
			{
				writefailnum++;
				usleep(1000);
			}
			writenum++;
			if(writenum%1000==0)
			{
				usleep(1000);
			}
		}
		else
		{
		
			CLogicMsg msg(toolkit.readBuff, toolkit.BUFFLEN); 
			ret = msgpipe.get_msg(msg);
			if(ret == CMsgQueue::ERROR)
			{
				cout << "get_msg error" << endl;
			}
			else if(ret == CMsgQueue::EMPTY)
			{
				//empty
				usleep(1000); //1ms
			}
			else
			{
				readnum++;
			}
		}

	}
	cc.stop();
	cout << "readnum=" << readnum << ",writenum=" << writenum << endl;

	CServerTool::sighandle(SIGTERM, stophandle);
	
	return 0;
}
