#include "net/tcpwrap.h"
#include "net/tcp_client.h"
#include "time/calculagraph.h"
#include "process_manager/process_manager.h"
#include "../common/packet_interface.h"
#include "../common/msg_define.h"
#include <iostream>
#include <string.h>
using namespace std;

class CTestClientManager:public CProcessManager
{
protected:
	virtual int entity( int argc, char *argv[] )
	{
		const int maxSize = 4096;
		char sendBuf[maxSize] = {0};
		char recvBuf[maxSize] = {0};
		CTcpClient client;
		client.add_server("172.25.42.21", 2012);

		BIN_PRO_HEADER* phead = (BIN_PRO_HEADER*)sendBuf;
		memset(phead, 0x0, sizeof(phead));


		CCalculagraph cc(cout);
		client.config()->timeout = 1;
		
		int ret = 0;
		int ifLong = atoi(argv[3]);
		int dataSize = atoi(argv[4]);
		if(dataSize < (int)sizeof(BIN_PRO_HEADER))
			dataSize = sizeof(BIN_PRO_HEADER);

		if(dataSize > maxSize)
		{
			dataSize = maxSize;
		}

		USER_NAME theUserName;
		snprintf(theUserName.val, sizeof(theUserName.val), "12345");
		phead->format(theUserName, 0, dataSize, true);
		

		if(ifLong)
		{
			ret = client.init();
			if(ret < 0)
			{
				cout << "init " << client.errmsg() << endl;
				return -1;
			}
			cout << "long cenncet" << endl;
		}

		for(int i=0; i<atoi(argv[2]); ++i)
		{
			if(!ifLong)
			{
				ret = client.init();
				if(ret < 0)
				{
					cout << "init " << client.errmsg() << endl;
					return -1;
				}
				cout << "short cenncet" << endl;
			}
			
			ret = client.send(sendBuf, dataSize);
			if(ret < 0)
			{
				cout << "send " << client.errmsg() << endl;
				return -1;
			}
			//phead->debug(cout);
			//cout << "send " << ret << endl;

			ret = client.recieve(recvBuf, dataSize);
			if(ret < 0)
			{
				cout << "[" << i << "] recieve " << client.errmsg() << endl;
				return -1;
			}	

			//cout << "[" << i << "] recieve " << ret << endl;
			if(ret == dataSize)
			{
				phead = (BIN_PRO_HEADER*)recvBuf;
				//phead->debug(cout);
			}
			else
			{
				cout << "recieve=" << ret << endl;
			}
		}
		cc.stop();
		cout << endl;

		return 0;
	}
};

int main(int argc, char** argv)
{
	CTestClientManager oMannager;
	if(argc < 5)
	{
		cout << argv[0] << " child_num loop_num connect_type(0=short,1=long) datasize" << endl;
		return 0;
	}

	oMannager.set_child_num(atoi(argv[1]));

	oMannager.run(argc, argv);
	return 0;
}

