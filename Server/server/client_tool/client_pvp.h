#ifndef __CLIENT_PVP_H__
#define __CLIENT_PVP_H__

#include "client_interface.h"
#include <sstream>

#include "proto/cmd_pvp.pb.h"

class CClientPVPGetTarget: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "pvp get target";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_PVP_GET_RANKING_LIST_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_PVP_GET_RANKING_LIST_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GetRankingTagResp resp;
};

class CClientPVPGetTop50: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "pvp get top n";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_PVP_RANKING_TOPN_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_PVP_RANKING_TOPN_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GetRankingListResp resp;
};

class CClientPVPGetSelf: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "pvp get self";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_PVP_RANKING_SELF_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_PVP_RANKING_SELF_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GetRankingSelfResp resp;
};

class CClientPVPGetDetail: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "pvp get detail";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
		{
			return false;
		}
		req.set_name(argv[0]);
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_PVP_GET_DETAIL_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_PVP_GET_DETAIL_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GetDetailReq req;
	GetDetailResp resp;
};



class CClientPVPFight: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "pvp:fight";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 2)
		{
			return false;
		}
		
		RankingData a;
		a.set_idx(atoi(argv[0]));
		a.mutable_entry()->set_name(argv[1]);
		a.mutable_entry()->set_power(0);
		req.mutable_target()->CopyFrom(a);
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_PVP_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_PVP_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	PVPReq req;
	PVPResp resp;
};


class CClientPVPGetPVPInof: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "pvp get pvpinfo";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_PVP_GET_PVPINFO_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_PVP_GET_PVPINFO_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected: 
	GetPVPInfoResp resp;
};

class CClientPVPGetRcd : public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "pvp get rcd";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
		{
			return false;
		}
		req.set_rcd_idx(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_PVP_GET_RCD_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_PVP_GET_RCD_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GetPVPRcdReq req;
	GetPVPRcdResp resp;
};

class CClientPVPRefleshShop : public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "pvp reflesh shop";
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
		return CMD_PVP_REFLESH_SHOP_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_PVP_REFLESH_SHOP_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	PVPRefleshShopReq req;
	PVPRefleshShopResp resp;
};

class CClientPVPShopping : public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "pvp shopping";
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
		return CMD_PVP_SHOPPING_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_PVP_SHOPPING_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	PVPShoppingReq req;
	PVPShoppingResp resp;
};

class CClientPVPMoney2Chance : public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "money2chance";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_PVP_MONEY2CHANCE_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_PVP_MONEY2CHANCE_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	PVPMoney2ChanceResp resp;
};

class CClientWlzbReg : public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "wlzb reg";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
		{
			return false;
		}
		req.set_type(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_WLZB_REG_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_WLZB_REG_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	WlzbRegReq req;
	WlzbRegResp resp;
};

class CClientWlzbSelf : public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "wlzb get fight info";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_WLZB_GET_FIGHT_INFO_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_WLZB_GET_FIGHT_INFO_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	WlzbGetFightInfoResp resp;
};


class CClientWlzbRcd : public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "wlzb get rcd";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
		{
			return false;
		}
		req.set_rcd_idx(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_WLZB_RCD_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_WLZB_RCD_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	WlzbGetRcdReq req;
	WlzbGetRcdResp resp;
};

class CClientWlzbReward : public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "wlzb get reward";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
		{
			return false;
		}
		req.set_reward_id(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_WLZB_REWARD_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_WLZB_REWARD_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	WlzbGetRewardReq req;
	WlzbGetRewardResp resp;
};

class CClientWlzbRewardList : public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "wlzb get wlzb reward list";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_WLZB_GET_REWARD_LIST_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_WLZB_GET_REWARD_LIST_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	WlzbGetRewardListResp resp;
};

//没有请求的
class CClientMpzGetInfo: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "MPZ getinfo:[flag] [groupid] [pre] [fieldno]";
	}

	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		if(argc < 1)
		{
			return false;
		}

		req.set_flag(atoi(argv[0]));
		if(argc > 1)
			req.set_groupname(argv[1]);
		if(argc > 2)
			req.set_pre(atoi(argv[2]));
		if(argc > 3)
			req.set_fieldno(atoi(argv[3]));

		retpReq = &req;
		return true;
	}

	virtual unsigned int req_cmd() 
	{
		return CMD_MPZ_GET_REQ;
	}

	virtual unsigned int resp_cmd()
	{
		return CMD_MPZ_GET_RESP;
	}

	virtual Message* resp_msg()
	{
		return &resp;
	}


protected:
	MPZGetReq req;
	MPZGetResp resp;
};

class CClientMpzSign: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "MPZ mastersign: fieldinfos{num, user[3]}";
	}

	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		if(argc < 2)
		{
			return false;
		}
		req.Clear();
		int idx = 0;
		while(idx < argc)
		{
			int num = atoi(argv[idx]);
			MPZRegFieldInfo* p = req.add_fieldinfo();
			p->set_fighternum(num);
			for(int i=idx+1; i < idx+1+num && i < argc; i++)
			{
				p->add_fighter(argv[i]);
			}

			idx += num+1;
		}

		retpReq = &req;
		return true;
	}

	virtual unsigned int req_cmd() 
	{
		return CMD_MPZ_MASTER_REG_REQ;
	}

	virtual unsigned int resp_cmd()
	{
		return CMD_MPZ_MASTER_REG_RESP;
	}

	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	MPZRegReq req;
	MPZRegResp resp;
};

class CClientMpzMemSign: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "MPZ mem sign";
	}

	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		retpReq = NULL;
		return true;
	}

	virtual unsigned int req_cmd() 
	{
		return CMD_MPZ_MEM_REG_REQ;
	}

	virtual unsigned int resp_cmd()
	{
		return CMD_MPZ_MEM_REG_RESP;
	}

	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	MPZRegMemResp resp;
};

class CClientMpzVideo: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "MPZ get Rcd: [videoidx] [round] [user1] [user2] [fieldno] [videono]";
	}

	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		if(argc < 1)
		{
			return false;
		}

		req.set_videoidx(atoi(argv[0]));
		if (argc > 1)
			req.set_round(atoi(argv[1]));

		if(argc > 3)
		{
			string tmp1;
			string tmp2;
			tmp1.assign(argv[2]);
			tmp2.assign(argv[3]);
			req.mutable_fightinfo()->set_user1(tmp1);
			req.mutable_fightinfo()->set_user2(tmp2);
		}
		if(argc > 4)
			req.set_fieldno(atoi(argv[4]));
		else
		{
			req.set_fieldno(-1);
			req.set_videono(-1);
		}

		if(argc > 5)
			req.set_videono(atoi(argv[5]));
		else
			req.set_videono(-1);

		retpReq = &req;

		return true;
	}

	virtual unsigned int req_cmd() 
	{
		return CMD_MPZ_GET_RCD_REQ;
	}

	virtual unsigned int resp_cmd()
	{
		return CMD_MPZ_GET_RCD_RESP;
	}

	virtual Message* resp_msg()
	{
		return &resp;
	}


protected:
	MPZGetVideoReq req;
	MPZGetVideoResp resp;
};

#endif

