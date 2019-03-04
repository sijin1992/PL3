#include <sys/epoll.h>
#include "net/tcpwrap.h"
#include <errno.h>
#include <string.h>
#include <iostream>
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

	CTcpListenSocket s;
	int ret = s.init();
	if(ret < 0)
	{
		cout << "CTcpListenSocket::init " <<  s.errmsg() << endl;
		return 0;
	}
	
	ret = s.listen(argv[1], atoi(argv[2]));
	if(ret < 0)
	{
		cout << "CTcpListenSocket::listen " <<  s.errmsg() << endl;
		return 0;
	}

	CTcpAcceptedSocket newsock;
	ret = s.accept(newsock);
	if(ret < 0)
	{
		cout << "CTcpListenSocket::accept " <<  s.errmsg() << endl;
		return 0;
	}

	while(!gstop)
	{
		char buff[1024*100];
		ret = newsock.read(buff, sizeof(buff));
		if(ret < 0 )
		{
			cout << "CTcpAcceptedSocket::read " <<  s.errmsg() << endl;
		}
		else if(ret == 0)
		{
			cout << "peerclosed" << endl;
			break;
		}
	}
	
	return 1;
}

