#ifndef __CLIENT_HUODONG_H__
#define __CLIENT_HUODONG_H__

#include "client_interface.h"
#include <sstream>

#include "proto/cmd_huodong.pb.h"

class CClientHuodongList: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "huodong list";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_HUODONG_LIST_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_HUODONG_LIST_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	HuodongListResp resp;
};

class CClientCaishendao: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "caishendao";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_HUODONG_CAISHENDAO_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_HUODONG_CAISHENDAO_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	CaishendaoResp resp;
};

class CClientCangjianGetShopList: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "cangjian get shoplist";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
	    req.Clear();
	    if(argc == 1)
			req.set_force(atoi(argv[0]));
	    else if(argc == 0)
	        req.set_force(0);
	    else
	        return false;

		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_CANGJIAN_GET_SHOPLIST_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_CANGJIAN_GET_SHOPLIST_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
    CangjianGetShopListReq req;
	CangjianGetShopListResp resp;
};

class CClientCangjianShopping: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "cangjian shopping";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
	    req.Clear();
	    if(argc != 1)
			return false;
        req.set_item_id(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_CANGJIAN_SHOPPING_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_CANGJIAN_SHOPPING_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
    CangjianShoppingReq req;
	CangjianShoppingResp resp;
};

class CClientCangjianShengwangShopping: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "cangjian shengwang shopping";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
	    req.Clear();
	    if(argc != 1)
			return false;
        req.set_item_id(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_CANGJIAN_SHENGWANG_SHOPPING_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_CANGJIAN_SHENGWANG_SHOPPING_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
    CangjianShengwangShoppingReq req;
	CangjianShengwangShoppingResp resp;
};

class CClientQiandao: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "qiandao";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
	    retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_QIANDAO_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_QIANDAO_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
    QiandaoResp resp;
};

class CClientGetCzfl: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "get czfl";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
	    retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GET_CZFL_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GET_CZFL_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
    ChongzhiResp resp;
};

class CClientCzflReward: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "get czfl reward";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
	    req.Clear();
	    if(argc != 1)
			return false;
        req.set_level(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_CZFL_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_CZFL_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	ChongzhiRewardReq req;
    ChongzhiRewardResp resp;
};

class CClientCjszTop50: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "cjsz top50";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
	    retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_CJSZ_TOP50_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_CJSZ_TOP50_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
    CjszTop50Resp resp;
};

class CClientCjszReward: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "get cjsz reward";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
	    req.Clear();
	    if(argc != 1)
			return false;
        req.set_reward_idx(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_CJSZ_REWARD_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_CJSZ_REWARD_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	CangjianRewardReq req;
    CangjianRewardResp resp;
};


class CClientCjszTotalSW: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "cjsz totalsw";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
	    retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_CJSZ_TOTAL_SW_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_CJSZ_TOTAL_SW_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
    CangjianTotalSWResp resp;
};

class CClientCjszExchangeList: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "cjsz exchange list";
	}

	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		retpReq = NULL;
		return true;
	}

	virtual unsigned int req_cmd() 
	{
		return CMD_CJSZ_EXCNANGE_LIST_REQ;
	}

	virtual unsigned int resp_cmd()
	{
		return CMD_CJSZ_EXCNANGE_LIST_RESP;
	}

	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	CangjianGetExchangeListResp resp;
};

class CClient7DayGift: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "7day gift";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
	    req.Clear();
	    if(argc != 1)
			return false;
        req.set_day_id(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_7DAY_GIFT_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_7DAY_GIFT_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	Day7GiftReq req;
    Day7GiftResp resp;
};

class CClientLevelGift: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "level gift";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
	    req.Clear();
	    if(argc != 1)
			return false;
        req.set_level_id(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_LEVEL_GIFT_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_LEVEL_GIFT_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	LevelGiftReq req;
    LevelGiftResp resp;
};

class CClientGetNewTask: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "get new task";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
	    retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GET_NEW_TASKS_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GET_NEW_TASKS_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
    GetNewTaskResp resp;
};


class CClientNewTaskReward: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "new task reward";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
	    req.Clear();
	    if(argc != 1)
			return false;
        req.set_day_id(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_NEW_TASK_REWARD_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_NEW_TASK_REWARD_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	NewTaskRewardReq req;
    NewTaskRewardResp resp;
};

class CClientCDKeyGift: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "cdkey gift:[cdkey]";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
	    req.Clear();
	    if(argc != 1)
			return false;
        req.set_cdkey(argv[0]);
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_CDKEY_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_CDKEY_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	CDKEY_Req req;
    CDKEY_Resp resp;
};

class CClientLjcz: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "ljcz";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
	    req.Clear();
	    if(argc != 1)
			return false;
        req.set_id(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_LEIJI_CHONGZHI_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_LEIJI_CHONGZHI_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GetLeijiChongzhiReq req;
    GetLeijiChongzhiResp resp;
};

class CClientDbcz: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "dbcz";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
	    req.Clear();
	    if(argc != 1)
			return false;
        req.set_id(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_DANBI_CHONGZHI_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_DANBI_CHONGZHI_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GetDanbiChongzhiReq req;
    GetDanbiChongzhiResp resp;
};

class CClientXffl: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "xffl";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
	    req.Clear();
	    if(argc != 1)
			return false;
        req.set_id(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_XIAOFEI_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_XIAOFEI_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GetXiaofeiHuodongReq req;
    GetXiaofeiHuodongResp resp;
};


class CClientLoginHuodong: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "login huodong";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
	    req.Clear();
	    if(argc != 1)
			return false;
        req.set_id(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_LOGIN_HUODONG_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_LOGIN_HUODONG_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GetLoginHuodongReq req;
    GetLoginHuodongResp resp;
};




class CClientLjczReward: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "ljcz reward";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
	    req.Clear();
	    if(argc != 2)
			return false;
        req.set_id(atoi(argv[0]));
		req.set_idx(atoi(argv[1]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_LEIJI_CHONGZHI_REWARD_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_LEIJI_CHONGZHI_REWARD_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	LeijiChongzhiRewardReq req;
    LeijiChongzhiRewardResp resp;
};

class CClientDbczReward: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "dbcz reward";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
	    req.Clear();
	    if(argc != 2)
			return false;
        req.set_id(atoi(argv[0]));
		req.set_idx(atoi(argv[1]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_DANBI_CHONGZHI_REWARD_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_DANBI_CHONGZHI_REWARD_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	DanbiChongzhiRewardReq req;
    DanbiChongzhiRewardResp resp;
};

class CClientXfflReward: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "xffl reward";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
	    req.Clear();
	    if(argc != 2)
			return false;
        req.set_id(atoi(argv[0]));
		req.set_idx(atoi(argv[1]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_XIAOFEI_REWARD_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_XIAOFEI_REWARD_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	XiaofeiHuodongRewardReq req;
    XiaofeiHuodongRewardResp resp;
};


class CClientLoginHuodongReward: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "login huodong reward";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
	    req.Clear();
	    if(argc != 2)
			return false;
        req.set_id(atoi(argv[0]));
		req.set_idx(atoi(argv[1]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_LOGIN_REWARD_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_LOGIN_REWARD_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	LoginHuodongRewardReq req;
    LoginHuodongRewardResp resp;
};

class CClientGetCzRank: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "get cz rank";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
	    retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GET_CZ_RANK_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GET_CZ_RANK_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
    GetChongzhiHongbaoListResp resp;
};

class CClientNewLevel: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "new level";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
	    retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_NEW_LEVEL_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_NEW_LEVEL_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
    NewLevelResp resp;
};

class CClientNewLevelReward: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "new level reward";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
	    req.Clear();
	    if(argc != 1)
			return false;
        req.set_level_id(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_NEW_LEVEL_REWARD_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_NEW_LEVEL_REWARD_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	NewLevelRewardReq req;
    NewLevelRewardResp resp;
};

class CClientDuihuanInfo: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "duihuan info";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
	    retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_DUIHUAN_INFO_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_DUIHUAN_INFO_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
    DuihuanInfoResp resp;
};

class CClientDuihuan: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "duihuan";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
	    req.Clear();
	    if(argc != 2)
			return false;
        req.set_id(atoi(argv[0]));
		req.set_num(atoi(argv[1]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_DUIHUAN_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_DUIHUAN_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	DuihuanReq req;
    DuihuanResp resp;
};

class CClientTianJiInfo: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "tianji info";
	}

	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		retpReq = NULL;
		return true;
	}

	virtual unsigned int req_cmd() 
	{
		return CMD_TIANJI_GET_REQ;
	}

	virtual unsigned int resp_cmd()
	{
		return CMD_TIANJI_GET_RESP;
	}

	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	TianJiInfoResp resp;
};

class CClientTianJi: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "TianJi open:[isvip]";
	}

	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
			return false;
		req.set_isvip(atoi(argv[0]));
		retpReq = &req;
		return true;
	}

	virtual unsigned int req_cmd() 
	{
		return CMD_TIANJI_REQ;
	}

	virtual unsigned int resp_cmd()
	{
		return CMD_TIANJI_RESP;
	}

	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	TianJiReq req;
	TianJiResp resp;
};

class CClientTianJiRewardInfo: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "TianJi Reward info";
	}

	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		retpReq = NULL;
		return true;
	}

	virtual unsigned int req_cmd() 
	{
		return CMD_TIANJI_REWARD_INFO_REQ;
	}

	virtual unsigned int resp_cmd()
	{
		return CMD_TIANJI_REWARD_INFO_RESP;
	}

	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	TianJiRewardInfoResp resp;
};

class CClientTianJiReward: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "TianJi reward";
	}

	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
			return false;
		req.set_idx(atoi(argv[0]));
		retpReq = &req;
		return true;
	}

	virtual unsigned int req_cmd() 
	{
		return CMD_TIANJI_REWARD_REQ;
	}

	virtual unsigned int resp_cmd()
	{
		return CMD_TIANJI_REWARD_RESP;
	}

	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	TianJiRewardReq req;
	TianJiRewardResp resp;
};

class CClientLimitShopInfo: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "LimitShop info";
	}

	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		retpReq = NULL;
		return true;
	}

	virtual unsigned int req_cmd() 
	{
		return CMD_LIMITSHOP_INFO_REQ;
	}

	virtual unsigned int resp_cmd()
	{
		return CMD_LIMITSHOP_INFO_RESP;
	}

	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	LimitShopInfoResp resp;
};

class CClientLimitShop: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "LimitShop:[idx]";
	}

	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
			return false;
		req.set_idx(atoi(argv[0]));
		retpReq = &req;
		return true;
	}

	virtual unsigned int req_cmd() 
	{
		return CMD_LIMITSHOP_REQ;
	}

	virtual unsigned int resp_cmd()
	{
		return CMD_LIMITSHOP_RESP;
	}

	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	LimitShopReq req;
	LimitShopResp resp;
};


#endif // __CLIENT_HUODONG_H__
