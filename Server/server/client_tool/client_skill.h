#ifndef __CLIENT_SKILL_H__
#define __CLIENT_SKILL_H__

#include "client_interface.h"
//#include "proto/cmd_fighting.pb.h"
#include <sstream>

#include "proto/cmd_skill.pb.h"

class CClientSkillLevUp: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "skill level up";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 2)
		{
			return false;
		}
		
		req.set_guid(atoi(argv[0]));
		req.set_add_level(atoi(argv[1]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_SKILL_LEVELUP_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_SKILL_LEVELUP_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	SkillLevelUpReq req;
	SkillLevelUpResp resp;
};


#endif

