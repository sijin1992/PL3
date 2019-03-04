#ifndef __CLIENT_HEARTBEAT_H__
#define __CLIENT_HEARTBEAT_H__

#include "client_interface.h"
#include "proto/heartBeatResp.pb.h"
#include "proto/logprotocol.pb.h"

class CClientHeartBeat: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "heartbeat";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_HEART_BEAT_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_HEART_BEAT_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	HeartBeatResp resp;
};

class CClientUserLog: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "userlog: logid ...";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		if(argc < 1)
			return false;
		req.Clear();
		req.set_logid(atoi(argv[0]));
		for(int i =1; i<argc; ++i)
		{
			if(i==1)
			{
				req.set_logval1(atoi(argv[i]));
			}
			else if(i==2)
			{
				req.set_logval2(atoi(argv[i]));
			}
			else if(i==3)
			{
				req.set_logval3(atoi(argv[i]));
			}
			else if(i==4)
			{
				req.set_logval4(atoi(argv[i]));
			}
			else if(i==5)
			{
				req.set_logval5(atoi(argv[i]));
			}
			else if(i==6)
			{
				req.set_logval6(atoi(argv[i]));
			}
			else if(i==7)
			{
				req.set_logval7(atoi(argv[i]));
			}
			else if(i==8)
			{
				req.set_logval8(atoi(argv[i]));
			}
			else if(i==9)
			{
				req.set_logval9(atoi(argv[i]));
			}
		}
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_USERLOG_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return 0;
	}
	
	virtual Message* resp_msg()
	{
		return NULL;
	}

protected:
	LogReportReq req;
};



#endif

