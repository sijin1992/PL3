#ifndef __CLIENT_USER_H__
#define __CLIENT_USER_H__

#include "client_interface.h"
#include <sstream>

#include "proto/CmdUser.pb.h"

class CClientSetZhenxing: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "set zhenxing";
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
		return CMD_SET_ZHENXING_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_SET_ZHENXING_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	SetZhenxingReq req;
	SetZhenxingResp resp;
};


class CClientLeadStarUp: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "lead starup";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_LEAD_STARUP_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_LEAD_STARUP_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	LeadStarUpResp resp;
};

class CClientGetItem: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "get item";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GET_ITEM_PACKAGE_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GET_ITEM_PACKAGE_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GetItemPackageResp resp;
};
/*
class CClientUserLevelup: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "user_levelup";
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
		return CMD_USER_LEVELUP_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	UserLevelUpResp resp;
};
*/
class CClientOpenBook: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "open book.need bookid";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
			return false;
		req.set_book_id(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_OPEN_BOOK_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_OPEN_BOOK_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	OpenBookReq req;
	OpenBookResp resp;
};


class CClientBookLevelUp: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "book levelup.need bookid";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 3 && argc != 5)
			return false;
		req.set_book_id(atoi(argv[0]));
		ItemRsync *i = req.add_item_list();
		i->set_item_id(atoi(argv[1]));
		i->set_item_num(atoi(argv[2]));
		if(argc == 5)
		{
			i = req.add_item_list();
			i->set_item_id(atoi(argv[3]));
			i->set_item_num(atoi(argv[4]));
		}
			
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_BOOK_LEVELUP_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_BOOK_LEVELUP_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	BookLevelUpReq req;
	BookLevelUpResp resp;
};

class CClientOpenLover: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "open lover.need loverid";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
			return false;
		req.set_lover_id(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_OPEN_LOVER_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_OPEN_LOVER_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	OpenLoverReq req;
	OpenLoverResp resp;
};


class CClientLoverLevelUp: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "lover levelup.need loverid";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
			return false;
		req.set_lover_id(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_LOVER_LEVELUP_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_LOVER_LEVELUP_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	LoverLevelUpReq req;
	LoverLevelUpResp resp;
};

class CClientUpdateTimestamp: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "update timestamp";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_UPDATE_TIMESTAMP_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_UPDATE_TIMESTAMP_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	UpdateTimeStampResp resp;
};

class CClientMoney2Gold: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "update money2gold";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_MONEY2GOLD_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_MONEY2GOLD_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	Money2GoldResp resp;
};

class CClientMoney2HP: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "update money2hp";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_MONEY2HP_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_MONEY2HP_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	Money2HPResp resp;
};


class CClientChouJiang: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "choujiang";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 2)
			return false;
		req.set_type(atoi(argv[0]));
		req.set_is_free(atoi(argv[1]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_CHOUJIANG_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_CHOUJIANG_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	ChouJiangReq req;
	ChouJiangResp resp;
};

class CClientSellItem: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "sell item";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 2)
			return false;
		ItemRsync item;
		item.set_item_id(atoi(argv[0]));
		item.set_item_num(atoi(argv[1]));
		req.mutable_item()->CopyFrom(item);
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_SELL_ITEM_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_SELL_ITEM_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	SellItemReq req;
	SellItemResp resp;
};

class CClientUseItem: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "use item:[itemid][itemnum]";
	}

	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 2)
			return false;
		Item item;
		item.set_id(atoi(argv[0]));
		item.set_num(atoi(argv[1]));
		req.mutable_item()->CopyFrom(item);
		retpReq = &req;
		return true;
	}

	virtual unsigned int req_cmd() 
	{
		return CMD_USE_ITEM_REQ;
	}

	virtual unsigned int resp_cmd()
	{
		return CMD_USE_ITEM_RESP;
	}

	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	UseItemReq req;
	UseItemResp resp;
};

class CClientTaskReflesh: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "task reflesh";
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
		return CMD_TASK_REFLEASH_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	TaskRefleshResp resp;
};

class CClientTakeTask: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "take task";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
			return false;
		req.set_task_id(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_TAKE_TASK_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_TAKE_TASK_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	TakeTaskReq req;
	TakeTaskResp resp;
};


class CClientGetTaskReward: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "get task reward";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
			return false;
		req.set_task_id(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GET_TASK_REWARD_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GET_TASK_REWARD_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GetTaskRewardReq req;
	GetTaskRewardResp resp;
};

class CClientGetChengjiuReward: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "get chengjiu reward";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
			return false;
		req.set_chengjiu_id(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GET_CHENGJIU_REWARD_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GET_CHENGJIU_REWARD_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GetChengjiuRewardReq req;
	GetChengjiuRewardResp resp;
};

class CClientGetDailyReward: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "get daily reward";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
			return false;
		req.set_daily_id(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GET_DAILY_REWARD_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GET_DAILY_REWARD_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GetDailyRewardReq req;
	GetDailyRewardResp resp;
};

class CClientGetTaskList: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "get task list";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
			return false;
		int t = atoi(argv[0]);
		req.set_task(t % 10);
		req.set_chengjiu((t / 10) % 10);
		req.set_daily((t / 100) % 10);
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GET_TASK_LIST_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GET_TASK_LIST_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GetTaskListReq req;
	GetTaskListResp resp;
};

class CClientUserAddMoneyCB: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "add money cb";
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
		return CMD_ADD_MONEY_CALLBACK;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	AddMoneyCallBack resp;
};

class CClientGetVipReward: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "get vip reward";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
			return false;
		req.set_vip_idx(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GET_VIP_REWARD_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GET_VIP_REWARD_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	VIPRewardReq req;
	VIPRewardResp resp;
};

class CClientSetCode: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "set code";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc == 2)
		{
			req.set_code_id(atoi(argv[0]));
			req.set_code_value(atoi(argv[1]));
		}
		else if (argc == 1)
		{
			req.set_code_id(1);
			req.set_code_value(atoi(argv[0]));
		}
		else
			return false;
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_CLIENT_CODE_SET_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_CLIENT_CODE_SET_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	ClientCodeSetReq req;
	ClientCodeSetResp resp;
};

class CClientGetExtdataAt5am: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "get extdata at 5am";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GET_EXTDATA_AT_5AM_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GET_EXTDATA_AT_5AM_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GetExtDataAt5amResp resp;
};

class CClientGetTiliReward: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "get tili reward";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
			return false;
		req.set_reward_id(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_TILI_REWARD_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_TILI_REWARD_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GetTiliRewardReq req;
	GetTiliRewardResp resp;
};

class CClientXYTransform: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "xy transform";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc == 0)
			return false;
		for(int i = 0; i < argc; i++)
		{
			Item *n = req.mutable_item_list()->Add();
			n->set_id(atoi(argv[i]));
			n->set_num(0);
		}
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_TRANSFORM_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_TRANSFORM_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	TransformReq req;
	TransformResp resp;
};


class CClientXYReflesh: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "xy reflesh";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc == 0)
			req.set_use_money(0);
		else if(argc == 1)
			req.set_use_money(atoi(argv[0]));
		else
			return false;
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_XY_REFLESH_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_XY_REFLESH_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	XYRefleshReq req;
	XYRefleshResp resp;
};


class CClientXYShopping: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "xy reflesh";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
			return false;
		req.set_item_idx(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_XY_SHOPPING_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_XY_SHOPPING_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	XYShoppingReq req;
	XYShoppingResp resp;
};

class CClientWXJY: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "wxjy";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
			return false;
		req.set_wxjy_idx(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_WXJY_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_WXJY_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	WXJYReq req;
	WXJYResp resp;
};

class CClientGetHuodongFlag: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "get huodong flag";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GET_HUODONG_FLAG_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GET_HUODONG_FLAG_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GetHuodongFlagResp resp;
};

class CClientNotify: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "notify";
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
		return CMD_NOTIFY_REFLESH_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	NotifyRefleshResp resp;
};

class CClientVIPShopping: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "vip shopping";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
			return false;
		req.set_item_idx(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_VIP_SHOPPING_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_VIP_SHOPPING_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	VIPShoppingReq req;
	VIPShoppingResp resp;
};

class CClientChoujiangHuodong: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "choujiang huodong";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{	
		retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_CHOUJIANG_HUODONG_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_CHOUJIANG_HUODONG_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	ChoujiangHuodongResp resp;
};

class CClientOpenChest: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "open chest";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 2)
			return false;
		ItemRsync item;
		item.set_item_id(atoi(argv[0]));
		item.set_item_num(atoi(argv[1]));
		req.mutable_item()->CopyFrom(item);
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_OPEN_CHEST_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_OPEN_CHEST_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	OpenChestReq req;
	OpenChestResp resp;
};

class CClientChat: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "chat channel,msg,recver, notfree";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc < 3)
			return false;
		ChatUserInfo recver;
		req.set_channel(atoi(argv[0]));
		req.set_msg(argv[1]);
		recver.set_uid(argv[2]);
		req.mutable_recver()->CopyFrom(recver);
		if(argc == 4)
			req.set_notfree(atoi(argv[3]));
			
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_CHAT_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_CHAT_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	ChatReq req;
	ChatResp resp;
};


class CClientChatMsg: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "chat msg";
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
		return CMD_CHAT_MSG;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	ChatMsg resp;
};

class CClientRefleshQy: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "reflesh qy";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_REFLESH_QIYU_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_REFLESH_QIYU_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	RefleshQiYuResp resp;
};

class CClientGetQy: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "get qy";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
			return false;
		req.set_guid(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GET_QIYU_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GET_QIYU_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GetQiYuReq req;
	GetQiYuResp resp;
};

class CClientGetChongzhiList: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "get chongzhi list";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GET_CHONGZHI_LIST_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GET_CHONGZHI_LIST_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GetChongzhiListResp resp;
};

class CClientGetTOPAct: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "get TOPAct";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GET_TOP_ACT_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GET_TOP_ACT_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GetTOPActResp resp;
};

class CClientQianNengUp: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "Qian Neng Up";
	}

	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if (argc == 2)
		{
			req.Clear();
			req.set_knight_guid(atoi(argv[0]));
			req.set_level(atoi(argv[1]));
			retpReq = &req;
			return true;			
		}
		else
		{
			return false;
		}		
	}

	virtual unsigned int req_cmd() 
	{
		return CMD_QIANNENG_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_QIANNENG_RESP;
	}

	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	QiannengReq req;
	QiannengResp resp;
};

#endif
