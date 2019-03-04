#ifndef __CLIENT_WBOSS_H__
#define __CLIENT_WBOSS_H__

#include "client_interface.h"
#include <sstream>

#include "proto/cmd_worldboss.pb.h"

class CClientWBossUserInfo: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "WBossUserInfo.";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_WBOSS_USER_INFO_GET_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_WBOSS_USER_INFO_GET_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	WBossUserInfoGetResp resp;
};

class CClientWBossRankRewardList: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "WBossRankRewardList";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		retpReq = NULL;
		return true;
	}
	virtual unsigned int req_cmd() 
	{
		return CMD_WBOSS_GET_RANK_REWARD_LIST_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_WBOSS_GET_RANK_REWARD_LIST_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	WBossGetRankRewardListResp resp;
};

class CClientWBossAttack: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "WBossAttack:[BossSeason]";
	}

	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		if( argc < 1 )
		{
			return false;
		}
		req.Clear();
		WBossHeadInfo &headInfo = *req.mutable_wboss_head();
		headInfo.set_boss_season(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	virtual unsigned int req_cmd() 
	{
		return CMD_WBOSS_ATTACK_REQ;
	}

	virtual unsigned int resp_cmd()
	{
		return CMD_WBOSS_ATTACK_RESP;
	}

	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	WBossAttackReq req;
	WBossAttackResp resp;
};

class CClientWBossRank: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "WBossRank:[BossSeason]";
	}

	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		if( argc < 1 )
		{
			return false;
		}
		req.Clear();
		WBossHeadInfo &headInfo = *req.mutable_wboss_head();
		headInfo.set_boss_season(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	virtual unsigned int req_cmd() 
	{
		return CMD_WBOSS_RANK_REQ;
	}

	virtual unsigned int resp_cmd()
	{
		return CMD_WBOSS_RANK_RESP;
	}

	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	WBossRankReq req;
	WBossRankResp resp;
};

#endif

