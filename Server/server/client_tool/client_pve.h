#ifndef __CLIENT_PVE_H__
#define __CLIENT_PVE_H__

#include "client_interface.h"
#include <sstream>

#include "proto/cmd_pve.pb.h"

#include <fstream>
using namespace std;

class CClientPVE: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "pve:1,stage id;2,difficulty";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		if(argc <= 0 || argc > 2)
		{
			return false;
		}
		req.set_stage_id(atoi(argv[0]));
		req.set_fortress_id(1);
		if(argc == 2)
		    req.set_difficulty(atoi(argv[1]));
		else
		    req.set_difficulty(1);
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_PVE_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_PVE_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}
	virtual ~CClientPVE()
	{
		FightRcd rcd;
		rcd.CopyFrom(resp.fight_rcd());
		char buff[4096];
		rcd.SerializeToArray(buff, 4096);
		int len = rcd.GetCachedSize();
		ofstream f("rcd",ios::binary);
		f.write(buff, len);
		f.close();
	}

protected:
	PVE_REQ req;
	PVE_RESP resp;
};

class CClientPVEClear: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "pve clear";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc == 0 || argc > 2)
		{
			return false;
		}
		req.set_stageid(atoi(argv[0]));
		if(argc == 2)
		    req.set_difficulty(atoi(argv[1]));
	    else
		    req.set_difficulty(1);
		req.set_fortress_id(1);
		req.set_count(1);
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_PVE_CLEAR_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_PVE_CLEAR_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	PVEClearReq req;
	PVEClearResp resp;
};


class CClientPVEget_reward: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "get pve reward : 1,fortress id; 2,difficulty";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 2)
		{
			return false;
		}
		req.set_fortress_id(atoi(argv[0]));
		req.set_idx(atoi(argv[1]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_PVE_GET_REWARD_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_PVE_GET_REWARD_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	PVEGetRewardReq req;
	PVEGetRewardResp resp;
};

class CClientPVEWatchShow: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "watch show";
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
		return CMD_PVE_WATCH_SHOW_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_PVE_WATCH_SHOW_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	PVEWatchShowReq req;
	PVEWatchShowResp resp;
};

class CClientPVE2Reset: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "pve2 reset";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_PVE2_RESET_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_PVE2_RESET_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	PVE2ResetResp resp;
};

class CClientPVE2SetZhenxing: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "pve2 set zhenxing";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 7)
		{
			return false;
		}
		for(int i = 0; i < 7; ++i)
			req.add_zhenxing(atoi(argv[i]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_PVE2_SET_ZHENXING_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_PVE2_SET_ZHENXING_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	PVE2SetZhenxingReq req;
	PVE2SetZhenxingResp resp;
};


class CClientPVE2GetEnemy: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "pve2 get enemy";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 2)
		{
			return false;
		}
		req.set_user_name(argv[0]);
		req.set_index(atoi(argv[1]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_PVE2_GET_ENEMY_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_PVE2_GET_ENEMY_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	PVE2GetEnemyDetailReq req;
	PVE2GetEnemyDetailResp resp;
};

class CClientPVE2Fight: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "pve2 fight";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_PVE2_FIGHT_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_PVE2_FIGHT_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	PVE2FightResp resp;
};

class CClientPVE2GetReward: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "pve2 get reward";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_PVE2_GET_REWARD_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_PVE2_GET_REWARD_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	PVE2GetRewardResp resp;
};

class CClientPVE2SelectBuff: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "pve2 select buff";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
		{
			return false;
		}
		req.set_idx(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_PVE2_SELECT_BUFF_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_PVE2_SELECT_BUFF_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	PVE2SelectBuffReq req;
	PVE2SelectBuffResp resp;
};

class CClientPVE2RefleshShop : public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "pve2 reflesh shop";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
		{
			return false;
		}
		req.set_free(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_PVE2_REFLESH_SHOP_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_PVE2_REFLESH_SHOP_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	PVE2RefleshShopReq req;
	PVE2RefleshShopResp resp;
};

class CClientPVE2Shopping : public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "pve2 shopping";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
		{
			return false;
		}
		req.set_idx(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_PVE2_SHOPPING_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_PVE2_SHOPPING_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	PVE2ShoppingReq req;
	PVE2ShoppingResp resp;
};

class CClientJingyingReset: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "jingying reset";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
		{
			return false;
		}
		req.set_stage_id(atoi(argv[0]));
		req.set_fortress_id(1);
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_PVE_RESET_JINGYING_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_PVE_RESET_JINGYING_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	PVEJingyingResetReq req;
	PVEJingyingResetResp resp;
};

class CClientSpStage: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "sp_stage";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		if(argc != 1)
		{
			return false;
		}
		req.set_stage_id(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_SPECIAL_STAGE_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_SPECIAL_STAGE_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	SpecialStageReq req;
	SpecialStageResp resp;
};




class CClientPVEt: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "pve";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		/*if(argc < 3)
		{
			return false;
		}*/
		req.set_stage_id(50010001);
		req.set_difficulty(1);
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_PVE_REQ+10;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_PVE_RESP+10;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	PVE_REQ req;
	PVE_RESP resp;
};


#endif

