#ifndef __CLIENT_LOGOUT_H__
#define __CLIENT_LOGOUT_H__

#include "client_interface.h"
#include "proto/logoutReq.pb.h"
#include "proto/logoutResp.pb.h"

class CClientLogout: public CClientInterface
{
public:
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.set_nothing(0);
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_LOGOUT_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_LOGOUT_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}
	virtual void help(ostream& out)
	{
		out << "logout";
	}

protected:
	LogoutReq req;
	LogoutResp resp;
};

#endif

