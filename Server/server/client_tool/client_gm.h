#ifndef __CLIENT_GM_H__
#define __CLIENT_GM_H__

#include "client_interface.h"
#include <sstream>

#include "proto/gm_cmd.pb.h"

class CClientGMGetUserSnap: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "GMGetUserSnap:[user]";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		if( argc < 1 )
		{
			req.set_username(m_userName);
		}
		else
		{
			req.set_username(argv[0]);
		}
		
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GM_GET_USER_SNAP_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GM_GET_USER_SNAP_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GMGetUserSnapReq req;
	GMGetUserSnapResp resp;
};

#endif

