#ifndef __CLIENT_SERVER_H__
#define __CLIENT_SERVER_H__

#include "client_interface.h"
#include <sstream>

#include "proto/inner_cmd.pb.h"

class CClientServerBroadcast: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "ServerBroadcastReq:[message]([begin_time][end_time])";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		if( argc < 1 )
		{
			return false;
		}
		req.set_message(argv[0]);
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_HTTPCB_BROADCAST_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_HTTPCB_BROADCAST_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	ServerBroadcastReq req;
	ServerBroadcastResp resp;
};


#endif

