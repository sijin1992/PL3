#ifndef __CLIENT_GROUP_H__
#define __CLIENT_GROUP_H__

#include "client_interface.h"
#include "proto/cmd_group.pb.h"

class CClientGetGroup: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "get group";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GET_GROUP_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GET_GROUP_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GetGroupReq req;
	GetGroupResp resp;
};

class CClientCreateGroup: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "create group";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
		{
			return false;
		}
		req.set_nickname(argv[0]);
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_CREATE_GROUP_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_CREATE_GROUP_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	CreateGroupReq req;
	GetGroupResp resp;
};

class CClientGroupJuan: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "group juanxian";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 2)
		{
			return false;
		}
		req.set_type(atoi(argv[0]));
		req.set_value(atoi(argv[1]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GROUP_JUAN_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GROUP_JUAN_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GroupJuanReq req;
	GroupJuanResp resp;
};


class CClientGroupLevelup: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "group levelup";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GROUP_LEVELUP_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GROUP_LEVELUP_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GroupLevelupResp resp;
};

class CClientGroupJuexue: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "group juexue";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
		{
			return false;
		}
		req.set_juexue_idx(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GROUP_JUEXUE_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GROUP_JUEXUE_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GroupJuexueReq req;
	GroupJuexueResp resp;
};

class CClientGroupBroadcast: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "group broad";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
		{
			return false;
		}
		req.set_broadcast(argv[0]);
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GROUP_BROADCAST_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GROUP_BROADCAST_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GroupBroadcastReq req;
	GroupBroadcastResp resp;
};

class CClientGroupWXJY: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "group wxjy";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
		{
			return false;
		}
		req.set_wxjy_idx(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GROUP_WXJY_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GROUP_WXJY_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GroupWXJYReq req;
	GroupWXJYResp resp;
};


class CClientGroupPVEReset: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "group pve reset";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 2)
		{
			return false;
		}
		req.set_fortress_id(atoi(argv[0]));
		req.set_first(atoi(argv[1]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GROUP_PVE_RESET_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GROUP_PVE_RESET_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GroupPVEResetReq req;
	GroupPVEResetResp resp;
};

class CClientGroupPVE: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "group pve";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 2)
		{
			return false;
		}
		req.set_fortress_id(atoi(argv[0]));
		req.set_stage_id(atoi(argv[1]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GROUP_PVE_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GROUP_PVE_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GroupPVEReq req;
	GroupPVEResp resp;
};

class CClientGroupResetSelfPVE: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "group reset self pve";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
		{
			return false;
		}
		req.set_fortress_id(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GROUP_RESET_SELF_PVE_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GROUP_RESET_SELF_PVE_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GroupResetSelfPVEReq req;
	GroupResetSelfPVEResp resp;
};

class CClientGroupAskReward: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "group ask reward";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
		{
			return false;
		}
		req.set_item_id(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GROUP_REWARD_ASK_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GROUP_REWARD_ASK_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GroupAskRewardReq req;
	GroupAskRewardResp resp;
};

class CClientGroupAllotReward: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "group allot reward";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 2)
		{
			return false;
		}
		req.set_item_id(atoi(argv[0]));
		req.set_guid(atoi(argv[1]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GROUP_REWARD_ALLOT_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GROUP_REWARD_ALLOT_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GroupAllotRewardReq req;
	GroupAllotRewardResp resp;
};

class CClientGroupSearch: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "group search";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 2)
		{
			return false;
		}
		//req.set_groupid(argv[0]);
		req.set_page(atoi(argv[1]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GROUP_SEARCH_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GROUP_SEARCH_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GroupSearchReq req;
	GroupSearchResp resp;
};

class CClientGroupJoinReq: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "group join req";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
		{
			return false;
		}
		req.set_groupid(argv[0]);
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GROUP_JOIN_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GROUP_JOIN_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GroupJoinReq req;
	GroupJoinResp resp;
};

class CClientGroupAllowJoin: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "group allow join";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
		{
			return false;
		}
		req.set_username(argv[0]);
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GROUP_ALLOW_JOIN_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GROUP_ALLOW_JOIN_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GroupAllowJoinReq req;
	GroupAllowJoinResp resp;
};

class CClientGroupExit: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "group exit";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		/*req.Clear();
		if(argc != 1)
		{
			return false;
		}
		req.set_username(argv[0]);
		retpReq = &req;
		*/
		retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GROUP_EXIT_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GROUP_EXIT_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	//GroupAllowJoinReq req;
	GroupExitGroupResp resp;
};

class CClientGroupKick: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "group kick";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
		{
			return false;
		}
		req.set_username(argv[0]);
		retpReq = &req;
		
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GROUP_KICK_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GROUP_KICK_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GroupKickReq req;
	GroupKickResp resp;
};

class CClientGroupMaster: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "group master";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 2)
		{
			return false;
		}
		req.set_username(argv[0]);
		req.set_type(atoi(argv[1]));
		retpReq = &req;
		
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GROUP_MASTER_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GROUP_MASTER_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GroupMasterReq req;
	GroupMasterResp resp;
};

class CClientGroupDisband: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "group disband";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		/*req.Clear();
		if(argc != 2)
		{
			return false;
		}
		req.set_username(argv[0]);
		req.set_type(atoi(argv[1]));
		retpReq = &req;
		*/
		retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GROUP_DISBAND_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GROUP_DISBAND_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GroupDisbandResp resp;
};

class CClientGroupUpdate: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "group update";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return 0;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GROUP_UPDATE;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GroupUpdate resp;
};


#endif

