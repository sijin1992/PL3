#ifndef __CLIENT_TEST_H__
#define __CLIENT_TEST_H__

#include "client_interface.h"
//#include "proto/cmd_fighting.pb.h"
#include <sstream>

#include "proto/UserInfo.pb.h"
#include "proto/gm_cmd.pb.h"
#include "proto/CmdUser.pb.h"


class CClientTest: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "test";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		if(argc < 0 || argc > 2)
			return false;
		req.set_orderno("123");
		req.set_sid("456");
		req.set_money(atoi(argv[0]));
		if (argc == 2)
			req.set_extinfo(argv[1]);
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return 0x18ff;
	}
	
	virtual unsigned int resp_cmd()
	{
		return 0x1900;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	TestHttpAddMondyReq req;
	AddMoneyCallBack resp;
};



#endif

