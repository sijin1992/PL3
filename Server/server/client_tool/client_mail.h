#ifndef __CLIENT_MAIL_H__
#define __CLIENT_MAIL_H__

#include "client_interface.h"
//#include "proto/cmd_fighting.pb.h"
#include <sstream>

#include "proto/cmd_mail.pb.h"

class CClientGetMailList: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "get mail list";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GET_MAIL_LIST_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GET_MAIL_LIST_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GetMailListResp resp;
};

class CClientReadMail: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "read mail";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
		{
			return false;
		}
		req.set_guid(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_READ_MAIL_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_READ_MAIL_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	ReadMailReq req;
	ReadMailResp resp;
};


#endif // __CLIENT_MAIL_H__
