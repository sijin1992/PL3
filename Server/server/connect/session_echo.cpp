#include "net/tcp_client.h"
#include "../common/packet_interface.h"
#include "connect_protocol.h"
#include <iostream>
#include <unistd.h>
#include "../logic/msg.h"
#include "../logic/msg_queue.h"
#include "../logic/toolkit.h"
#include "connect_protocol.h"
 
using namespace std;


int main(int argc, char** argv)
{
	//与server相反
	CDequePIPE pipe;
	int ret = pipe.init(0x20122, 100*1024, 0x20121, 100*1024);
	if(ret != 0)
	{
		cout << "pipe.init=" << ret << " " << pipe.errmsg();
		return 0;
	}

	CMsgQueuePipe queuePipe(pipe);
	CToolkit toolkit;
	MSG_SESSION* p = NULL;
	char* packet;
	int packLen;
	
	while(true)
	{
		//轮询之
		CLogicMsg msg(toolkit.readBuff, toolkit.BUFFLEN); 

		
		ret = queuePipe.get_msg(msg);
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
			CConnectProtocol protocol(toolkit.get_body(msg), toolkit.get_body_len(msg));
			packLen = protocol.packet_len();
			if(packLen < 0)
			{
				cout << "msg len too small" << endl;
				continue;
			}
			else if(packLen == 0)
			{
				packet = NULL;
			}
			else
			{
				packet = protocol.packet();
			}

			p = protocol.session();

			if(p->flag == SESSION_FLAG_ZERO)
			{
				memcpy(toolkit.send_buff(), toolkit.get_body(msg), toolkit.get_body_len(msg));
				ret = toolkit.send_to_queue(CMD_SESSION_RESP, &queuePipe, toolkit.get_body_len(msg));
				if(ret != 0)
				{
					cout << "send_msg error" << endl;
				}
			}
			
		}

	}
	
	return 0;
}
