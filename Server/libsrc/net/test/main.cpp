#include "../tcpwrap.h"
#include "../tcp_client.h"
#include <iostream>
#include <string.h>
using namespace std;

void server()
{
	signal(SIGPIPE, SIG_IGN);
	char buff[100*1024-1];
	CTcpListenSocket socket;
	if(socket.init() < 0)
	{
		cout << "socket.init " << socket.errmsg() << endl;
		return;
	}
	
	int ret = socket.listen("172.25.42.21", 1234);
	if(ret < 0)
	{
		cout << "socket.listen(\"172.25.42.21\", 1234) " << socket.errmsg() << endl;
		return;
	}

	while(true)
	{
		CTcpAcceptedSocket newSocket;
		if(socket.accept(newSocket) < 0)
		{
			cout << "socket.accept " << socket.errmsg() << endl;
			continue;
		}

		cout << "accept:" << newSocket.get_socket() << endl;

		while(true)
		{
			int len = newSocket.read(buff, sizeof(buff));
			if(len < 0)
			{
				cout << "newSocket.read " << newSocket.errmsg() << endl;
				break;
			}
			else if(len == 0)
			{
				cout << "read = 0" << endl;
				break;
			}

			cout << "read:" << len << endl;
			#if  1
			len = newSocket.write(buff, sizeof(buff));
			if(len < 0)
			{
				cout << "newSocket.write " << newSocket.errmsg() << endl;
				break;
			}
			else
			{
				cout << "write:" << len << endl;
			}

			#endif
		}
	}
}

int main(int argc, char** argv)
{
	if(argc > 1)
	{
		server();
		return 0;
	}

	const char* sendstr = "GET /index.htm HTTP/1.1\r\n\r\n";
	unsigned int len = strlen(sendstr);
	CTcpClient client;
	client.add_server("172.25.42.21", 80);
	client.add_server("172.25.42.21", 1234);

//²âÊÔ
	client.config()->tryTimes = 1;
	client.config()->timeout = 1;
	client.config()->randIP = false;
	client.config()->errClose = 1;
//	client.config()->useSelect = true;
	
	client.config()->debug(cout);
	cout << endl;

	int ret = client.init();
	client.debug(cout);
	if(ret != 0)
	{
		cout << "init=" << ret << " " << client.errmsg() << endl;
		return -1;
	}

	cout << "inited" << endl;

	for(int i=0; i<3; ++i)
	{
		ret = client.send(sendstr, len);
		cout << endl ;
		client.debug(cout);
		cout << "SEND|len=" << len << ",ret=" << ret << endl;
		if(ret  < 0)
		{
			cout << "send " << client.errmsg() << endl;
			return -1;
		}

		char buff[100*1024];
		memset(buff, 0x0, sizeof(buff));
		ret = client.recieve(buff, sizeof(buff));
		cout <<  endl ;
		client.debug(cout);
		if(ret < 0)
		{
			cout << "read " << client.errmsg() << endl;
		}
		else
		{
			cout <<  "RECV|" << ret << "|" <<  "|..." << endl;
		}
	}

	return 0;
}

