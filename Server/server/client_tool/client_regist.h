#ifndef __CLIENT_REGIST_H__
#define __CLIENT_REGIST_H__

#include "client_interface.h"
#include "proto/CmdLogin.pb.h"

class CClientRegist: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "regist [nickname] [cardid]";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc < 2)
		{
			return false;
		}
		
		req.set_rolename(argv[0]);
		req.set_lead(atoi(argv[1]));
		req.set_device_type("device_type");
		req.set_resolution("resolution");
		req.set_os_type("os_type");
		req.set_isp("ISP");
		req.set_net("net");
		req.set_mcc("MCC");
		req.set_account("newclient");
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_REGIST_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_LOGIN_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}


protected:
	RegistReq req;
	LoginResp resp;
};

#endif

