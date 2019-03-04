#ifndef __CLIENT_KNIGHT_H__
#define __CLIENT_KNIGHT_H__

#include "client_interface.h"
//#include "proto/cmd_fighting.pb.h"
#include <sstream>

#include "proto/cmd_knight.pb.h"

class CClientGetKnight: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "get knight";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		retpReq = NULL;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GET_KNIGHT_BAG_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GET_KNIGHT_BAG_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	UserInfo userinfo;
	GetKnightBagResp resp;
};

class CClientKnightLevUp: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "knight level up";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 3)
		{
			return false;
		}

		req.set_tag_guid(atoi(argv[0]));
		Item *item = req.add_src_list();
		item->set_id(atoi(argv[1]));
		item->set_num(atoi(argv[2]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_KNIGHT_LEVELUP_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_KNIGHT_LEVELUP_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	UserInfo userinfo;
	KnightLevelUpReq req;
	KnightLevelUpResp resp;
};

class CClientKnightEvolutionUp: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "knight evolution up";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
		{
			return false;
		}
		
		req.set_tag_guid(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_KNIGHT_EVOLUTION_UP_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_KNIGHT_EVOLUTION_UP_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	UserInfo userinfo;
	KnightEvolutionUpReq req;
	KnightEvolutionUpResp resp;
};

class CClientGongEquip: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "gong equip";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 2)
		{
			return false;
		}
		
		req.set_guid(atoi(argv[0]));
		req.set_gong_idx(atoi(argv[1]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GONG_EQUIP_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GONG_EQUIP_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	UserInfo userinfo;
	GongEquipReq req;
	GongEquipResp resp;
};

class CClientGongMerge: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "gong merge";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
		{
			return false;
		}
		
		req.set_guid(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GONG_MERGE_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GONG_MERGE_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	UserInfo userinfo;
	GongMergeReq req;
	GongMergeResp resp;
};

class CClientGongMix: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "gong mix";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
		{
			return false;
		}
		
		req.set_tag_item(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_GONG_MIX_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_GONG_MIX_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	UserInfo userinfo;
	GongMixReq req;
	GongMixResp resp;
};

class CClientKnightEnlist: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "knight enlist";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
		{
			return false;
		}
		
		req.set_knight_id(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_KNIGHT_ENLIST_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_KNIGHT_ENLIST_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	UserInfo userinfo;
	KnightEnlistReq req;
	KnightEnlistResp resp;
};

class CClientMJEquip: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "mj equip";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 4)
		{
			return false;
		}
		
		req.set_guid(atoi(argv[0]));
		req.set_from(atoi(argv[1]));
		req.set_to(atoi(argv[2]));
		req.set_miji_id(atoi(argv[3]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_MIJI_EQUIP_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_MIJI_EQUIP_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	EquipMiJiReq req;
	EquipMiJiResp resp;
};

class CClientMJLevelup: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "mj levelup";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 5)
		{
			return false;
		}
		
		req.set_guid(atoi(argv[0]));
		req.set_from(atoi(argv[1]));
		req.set_miji_id(atoi(argv[2]));
		Item t;
		t.set_id(atoi(argv[3]));
		t.set_num(1);
		t.set_guid(atoi(argv[4]));
		MiJi *mj = t.mutable_mj_data();
		mj->set_id(atoi(argv[3]));
		mj->set_level(1);
		mj->set_exp(0);
		Item *p = req.add_item_list();
		p->CopyFrom(t);
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_MIJI_LEVELUP_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_MIJI_LEVELUP_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	MiJiLevelupReq req;
	MiJiLevelupResp resp;
};

class CClientMJMix: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "mj mix";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 1)
		{
			return false;
		}
		
		req.set_tag_item(atoi(argv[0]));
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_MIJI_MIX_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_MIJI_MIX_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	GongMixReq req;
	GongMixResp resp;
};

class CClientMJJinjie: public CClientInterface
{
public:
	virtual void help(ostream& out)
	{
		out << "mj jinjie";
	}
	
	virtual bool req_msg(int argc, char** argv, Message*& retpReq)
	{
		req.Clear();
		if(argc != 5)
		{
			return false;
		}
		
		req.set_guid(atoi(argv[0]));
		req.set_from(atoi(argv[1]));
		req.set_miji_id(atoi(argv[2]));
		Item t;
		t.set_id(atoi(argv[3]));
		t.set_num(1);
		t.set_guid(atoi(argv[4]));
		MiJi *mj = t.mutable_mj_data();
		mj->set_id(atoi(argv[3]));
		mj->set_level(1);
		mj->set_exp(0);
		mj->set_guid(atoi(argv[4]));
		Item *p = req.add_item_list();
		p->CopyFrom(t);
		retpReq = &req;
		return true;
	}
	
	virtual unsigned int req_cmd() 
	{
		return CMD_MIJI_JINJIE_REQ;
	}
	
	virtual unsigned int resp_cmd()
	{
		return CMD_MIJI_JINJIE_RESP;
	}
	
	virtual Message* resp_msg()
	{
		return &resp;
	}

protected:
	MiJiJinjieReq req;
	MiJiJinjieResp resp;
};

#endif

