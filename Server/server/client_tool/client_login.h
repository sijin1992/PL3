#ifndef __CLIENT_LOGIN_H__
#define __CLIENT_LOGIN_H__

#include "client_interface.h"

#include "proto/CmdLogin.pb.h"

class CClientLogin: public CClientInterface
{
public:
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		int server = 1;
		string sid;
		string ver;
		if( argc == 2 )
		{
			sid = argv[0];
			ver = argv[1];
			//server = atoi(argv[0]);
		}
		else
			{
			sid = "1";
			ver = "1.0.0";
			}
		req.set_user_name(m_userName);
		req.set_key(m_userKey);
		req.set_server(server);
		req.set_platform(13);
		req.set_domain("1234");
		req.set_device_type("device_type");
		req.set_resolution("resolution");
		req.set_os_type("os_type");
		req.set_isp("ISP");
		req.set_net("net");
		req.set_mcc("MCC");
		req.set_sid(sid);
		req.set_version(ver);
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_LOGIN_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_LOGIN_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}
	virtual void help(ostream& out)
	{
		out << "login";
	}

protected:
	LoginReq req;
	LoginResp resp;
};

#endif

