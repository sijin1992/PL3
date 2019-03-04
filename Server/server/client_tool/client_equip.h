#ifndef __CLIENT_EQUIP_H__
#define __CLIENT_EQUIP_H__

#include "client_interface.h"
//#include "proto/cmd_fighting.pb.h"
#include <sstream>

#include "proto/cmd_equip.pb.h"

class CClientEquipLevUp: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "equip level up";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc < 1)
		{
			return false;
		}
		
		req.set_id(atoi(argv[0]));
		if(argc == 2)
			req.set_add_value(atoi(argv[1]));
		else
			req.set_add_value(1);
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_EQUIP_LEVELUP_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_EQUIP_LEVELUP_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	EquipLevelUpReq req;
	EquipLevelUpResp resp;
};

class CClientEquipStarUp: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "equip star up";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
		{
			return false;
		}
		
		req.set_id(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_EQUIP_STARUP_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_EQUIP_STARUP_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	EquipStarUpReq req;
	EquipStarUpResp resp;
};



#endif

