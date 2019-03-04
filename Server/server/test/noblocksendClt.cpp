#include <sys/epoll.h>
#include "net/tcpwrap.h"
#include <errno.h>
#include <string.h>
#include <iostream>
#include "time/calculagraph.h"
#include "common/server_tool.h"

using namespace std;
int gstop = 0;
static void stophandle(int iSigNo)
{
	gstop = 1;
	cout << "recv signal(" << iSigNo << ") stop=" << gstop << endl;
}

int main(int argc, char** argv)
{
	if(argc < 2)
	{
		cout << argv[0] << " ip port" << endl;
	}
	
	CServerTool::sighandle(SIGTERM, stophandle);
	CServerTool::ignore(SIGPIPE);
	
	CTcpClientSocket client;
	int ret = client.init();
	if(ret < 0)
	{
		cout << "CTcpClientSocket::init " <<  client.errmsg() << endl;
		return 0;
	}

	ret = client.connect(argv[1], atoi(argv[2]));
	if(ret < 0)
	{
		cout << "CTcpClientSocket::connect " <<  client.errmsg() << endl;
		return 0;
	}

	//ret = client.set_nonblock();
	//if(ret < 0)
	//{
	//	cout << "CTcpClientSocket::set_nonblock " <<  client.errmsg() << endl;
	//	return 0;
	//}

	int cnt = 0;
	int wdblock= 0;
	int halfblock = 0;
	CCalculagraph cc(cout);
	while(!gstop)
	{
		
		char buff[100] = {0};
		ret = client.write(buff, sizeof(buff));
		if(ret < 0 )
		{
			if(errno == EAGAIN)
			{
				wdblock ++;
			}
			else if(errno == EPIPE)
			{
				cout << "peer closed" << endl;
				break;
			}
			else
			{
				cout << "CTcpAcceptedSocket::write " <<  client.errmsg() << endl;
			}
		}
		else if(ret == 0)
		{
			//cout << "would block" << endl;
			wdblock ++;
		}
		else 
		{
			if(ret == sizeof(buff))
			{
				cnt++;
			}
			else
			{
				halfblock++;
			}
		}
	}
	cc.stop();
	cout << "send " << cnt << endl;
	cout << "block " << wdblock << endl;
	cout << "halfblock " << halfblock << endl;
	return 1;
}

