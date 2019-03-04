#ifndef __CLIENT_ROBMINE_H__
#define __CLIENT_ROBMINE_H__

#include "client_interface.h"
#include <sstream>

#include "proto/cmd_robmine.pb.h"

class CClientMineReward : public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "Mine get reward";
	}

	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		retpReq = NULL;
		return true;
	}

	virtual unsigned int req_cmd() 
	{
		return CMD_MINE_REWARD_REQ;
	}

	virtual unsigned int resp_cmd()
	{
		return CMD_MINE_REWARD_RESP;
	}

	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	RobMineRewardResp resp;
};

class CClientMineGetInfo: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "Mine get info:[flag]";
	}

	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		if(argc < 1)
		{
			return false;
		}

		req.set_flag(atoi(argv[0]));

		retpReq = &req;
		return true;
	}

	virtual unsigned int req_cmd() 
	{
		return CMD_MINE_GET_REQ;
	}

	virtual unsigned int resp_cmd()
	{
		return CMD_MINE_GET_RESP;
	}

	virtual Message* resp_msg()
	{
		return &resp;
	}


protected:
	RobMineGetReq req;
	RobMineGetResp resp;
};

class CClientMineSearch: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "Mine Search: [uid]";
	}

	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		if(argc < 1)
		{
			return false;
		}
		req.Clear();
		req.set_uid(argv[0]);

		retpReq = &req;
		return true;
	}

	virtual unsigned int req_cmd() 
	{
		return CMD_MINE_CHANGE_REQ;
	}

	virtual unsigned int resp_cmd()
	{
		return CMD_MINE_CHANGE_RESP;
	}

	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	RobMineSearchReq req;
	RobMineSearchResp resp;
};

class CClientMineSetFightList: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "Mine Set FightList: [deflist]";
	}

	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		if(argc < 1)
		{
			return false;
		}
		req.Clear();
		for (int i =0 ; i < argc ; i++)
		{
			req.add_deflist(atoi(argv[i]));
		}

		retpReq = &req;
		return true;
	}

	virtual unsigned int req_cmd() 
	{
		return CMD_MINE_SET_FIGHTLIST_REQ;
	}

	virtual unsigned int resp_cmd()
	{
		return CMD_MINE_SET_FIGHTLIST_RESP;
	}

	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	RobMineSetFightListReq req;
	RobMineSetFightListResp resp;
};

class CClientMineGetRcd: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "Mine get Rcd: [videoidx]";
	}

	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		if(argc < 1)
		{
			return false;
		}

		req.set_videoidx(atoi(argv[0]));

		retpReq = &req;

		return true;
	}

	virtual unsigned int req_cmd() 
	{
		return CMD_MINE_GET_RCD_REQ;
	}

	virtual unsigned int resp_cmd()
	{
		return CMD_MINE_GET_RCD_RESP;
	}

	virtual Message* resp_msg()
	{
		return &resp;
	}


protected:
	RobMineGetVideoReq req;
	RobMineGetVideoResp resp;
};

class CClientMineGetJingLi: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "Mine get JingLi: [rcdno]";
	}

	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		if(argc < 1)
		{
			return false;
		}

		req.set_rcdno(atoi(argv[0]));

		retpReq = &req;

		return true;
	}

	virtual unsigned int req_cmd() 
	{
		return CMD_MINE_GET_JINGLI_REQ;
	}

	virtual unsigned int resp_cmd()
	{
		return CMD_MINE_GET_JINGLI_RESP;
	}

	virtual Message* resp_msg()
	{
		return &resp;
	}


protected:
	RobMineGetJingLiReq req;
	RobMineGetJingLiResp resp;
};

class CClientMineRob: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "Mine Rob: [mineid] size1 size2 [zhenxing]  [enemylist]";
	}

	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		if(argc < 4)
		{
			return false;
		}

		req.Clear();
		req.set_mineid(argv[0]);
		int zxsize = atoi(argv[1]);
		int emylsize = atoi(argv[2]);
		int i = 3;
		for (; i < zxsize + 3 ; i++)
		{
			req.add_zhenxing(atoi(argv[i]));
		}

		for (; i < zxsize + emylsize + 3; i++ )
		{
			//req.mutable_enmeylist()->add_fightlist(atoi(argv[i]));
		}

		retpReq = &req;

		return true;
	}

	virtual unsigned int req_cmd() 
	{
		return CMD_MINE_ROB_REQ;
	}

	virtual unsigned int resp_cmd()
	{
		return CMD_MINE_ROB_RESP;
	}

	virtual Message* resp_msg()
	{
		return &resp;
	}


protected:
	RobMineReq req;
	RobMineResp resp;
};

class CClientMineGetEnemylist: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "Mine get Enemylist: [uid]";
	}

	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		if(argc < 1)
		{
			return false;
		}

		req.set_uid(argv[0]);

		retpReq = &req;

		return true;
	}

	virtual unsigned int req_cmd() 
	{
		return CMD_MINE_GET_ENEMYLIST_REQ;
	}

	virtual unsigned int resp_cmd()
	{
		return CMD_MINE_GET_ENEMYLIST_RESP;
	}

	virtual Message* resp_msg()
	{
		return &resp;
	}


protected:
	RobMineGetEnemyListReq req;
	RobMineGetEnemyListResp resp;
};

#endif