#ifndef __CLIENT_TRIAL_H__
#define __CLIENT_TRIAL_H__

#include "client_interface.h"
#include <sstream>

#include "proto/cmd_pve.pb.h"

class CClientPVETrialInfo: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "Trial Info:(isreset = 1)";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc > 0)
		{
			req.set_is_reset(atoi(argv[0]));
		}
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_PVE_TRIAL_INFO_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_PVE_TRIAL_INFO_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	PVETrialInfoGetReq req;
	PVETrialInfoGetResp resp;
};

class CClientPVETrialStart: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "PVETrialStart:[tar_layer](issweep)(isrevive)";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		if(argc < 1)
		{
			return false;
		}
		req.Clear();
		req.set_tar_layer(atoi(argv[0]));
		if( argc > 1 )
		{
			req.set_is_sweep(atoi(argv[1]));
		}
		if( argc > 2 )
		{
			req.set_is_revive(atoi(argv[2]));
		}

		retpReq = &req;
		return true;
	}
	virtual unsigned int req_cmd() 
	{
		return CMD_PVE_TRIAL_START_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_PVE_TRIAL_START_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	PVETrialStartReq req;
	PVETrialStartResp resp;
};

#endif

