#include "data_control.h"
#include <stdlib.h>

#include "neiceuser.h"

#include "time/time_util.h"
#include "logic_util.h"

#include "proto/UserInfo.pb.h"

//extern CWorldEvent gWorldEvent;
//unsigned int REGIST_WORLD_EVENT;
//RandBoxReward REGIST_LOGIN_REWARD;
bool gFang = false;
extern CHashedUserList gneiceuser;

bool gNoLimit=false;

#define TIME_THREE_HOUR 3*3600
//#define TIME_THREE_HOUR 500

CDataControlSlot::CDataControlSlot()
{
	state = 0;
	timerID = 0;
	guest = false;
	silent = false;
}


int CDataControlSlot::make_login_resp(USER_NAME &name, UserInfo& userinfo, ShipList &ship_list, ItemList &item_list, MailList & mail_list,
	LoginResp& resp,bool needUpdate, LoginReq* preq)
{
	int modified = 0;
	int unread_mail_num = 0;
	//HuodongList huodong_list;
	//时效计算
	if(needUpdate)
	{
		//普通登录
		modified = update_user(name, userinfo, ship_list, item_list, mail_list);
		if(modified == -1)
			return modified;
		if(preq)
		{
			userinfo.set_ip(preq->ip());
			userinfo.set_mcc(preq->mcc());
		}
		modified = 1;
	}
	else
	{
		//regist过来的，只读
	}

	//什么时候设置都一样的
	resp.set_result(resp.OK);
	resp.set_isinit(true);
	resp.mutable_user_info()->CopyFrom(userinfo);
	resp.mutable_ship_list()->CopyFrom(ship_list);
	resp.mutable_item_list()->CopyFrom(item_list);
	resp.set_nowtime(time(NULL));
	LoginExtData ext_data;
	ext_data.set_un_read_mail_num(unread_mail_num);
	resp.mutable_ext_data()->CopyFrom(ext_data);
	//resp.mutable_huodong_list()->CopyFrom(huodong_list);
	return modified;
}

#define GET_SET_DATA(name, type, flag)\
int CDataControlSlot::get_##name(type& theUserProto)\
{\
	DataBlock* theBlock;\
	if(theSet.get_block(flag_to_bit(flag), theBlock) != 0)\
	{\
		return -1;\
	}\
	if(!theBlock->has_buff())\
	{\
		LOG(LOG_ERROR, "no buff");\
		return -1;\
	}\
	if(!theUserProto.ParseFromString(theBlock->buff()))\
	{\
		LOG(LOG_ERROR, "theUserProto.ParseFromString fail" );\
		if(theUserProto.ParsePartialFromString(theBlock->buff()))\
		{\
			LOG(LOG_ERROR, "theUserProto.ParsePartialFromArray: %s",  theUserProto.DebugString().c_str());\
		}\
		else\
		{\
			LOG(LOG_ERROR, "theUserProto.ParsePartialFromArray fail");\
		}\
		return -1;\
	}\
	return 0;\
}\
int CDataControlSlot::set_##name(type& theUserProto)\
{\
	DataBlock* theBlock;\
	if(theSet.get_block(flag_to_bit(flag), theBlock) != 0)\
	{\
		return -1;\
	}\
	if(!theUserProto.SerializeToString(theBlock->mutable_buff()))\
	{\
		LOG(LOG_ERROR, "theUserProto.SerializeToString fail" );\
		return -1;\
	}\
	return 0;\
}

GET_SET_DATA(main_data, UserInfo, DATA_BLOCK_FLAG_MAIN);
GET_SET_DATA(ship_list, ShipList, DATA_BLOCK_FLAG_SHIP);
GET_SET_DATA(item_package, ItemList, DATA_BLOCK_FLAG_ITEMS);
GET_SET_DATA(mail_list, MailList, DATA_BLOCK_FLAG_MAIL);


int CDataControlSlot::get_data_to_string(unsigned int flag, string &buf)
{
	DataBlock* theBlock;
	if(theSet.get_block(flag_to_bit(flag), theBlock) != 0)
	{
		return -1;
	}

	if(!theBlock->has_buff())
	{
		LOG(LOG_ERROR, "no buff");
		return -1;
	}

	buf.assign(theBlock->buff());
	return 0;
}

int CDataControlSlot::set_data_from_string(unsigned int flag, string &buf)
{
	DataBlock* theBlock;
	if(theSet.get_block(flag_to_bit(flag), theBlock) != 0)
	{
		return -1;
	}

	theBlock->mutable_buff()->assign(buf);
	return 0;
}



int CDataControlSlot::clear_block(int flag)
{
	DataBlockSet& set = theSet.get_obj();
	int blockid = flag_to_bit(flag);

	int nowsize = set.blocks_size();
	for(int j=0; j<nowsize; ++j)
	{
		DataBlock* pblock = set.mutable_blocks(j);
		if(pblock->id() == blockid)
		{
			pblock->clear_buff();
			return 0;
		}
	}

	return -1;
}

int CDataControlSlot::create_new_data(USER_NAME &user_name, RegistReq* pregist/*, LoginResp& resp*/)
{
	theSet.make_set_req(flag_to_bit(DATA_BLOCK_FLAG_MAIN), false, NULL);
	theSet.add_set_req(flag_to_bit(DATA_BLOCK_FLAG_SHIP), false, NULL);
	theSet.add_set_req(flag_to_bit(DATA_BLOCK_FLAG_ITEMS), false, NULL);
	theSet.add_set_req(flag_to_bit(DATA_BLOCK_FLAG_MAIL), false, NULL);
	//dbcache占位，减少读db次数
	string emptystr="";
//	theSet.add_set_req(flag_to_bit(DATA_BLOCK_FLAG_FEEDS), false, &emptystr);
	UserInfo user_info;
	ShipList ship_list;
	ItemList item_list;
	MailList mail_list;

	//int ret = create_main_data(user_info, pregist->lead(), user_name, pregist->rolename(),
	//	knight_bag, item_list, mail_list, *pregist);
	int ret = create_user(user_name, *pregist, user_info, ship_list, item_list, mail_list);
	if(ret != 0)
		return ret;

	if(set_main_data(user_info) != 0)
	{
		return -1;
	}
	if(set_ship_list(ship_list) != 0)
	{
		return -1;
	}
	if(set_item_package(item_list) != 0)
	{
		return -1;
	}
	if(set_mail_list(mail_list) != 0)
	{
		return -1;
	}
	return 0;
}


//新建一个slot
CDataControlSlot* CDataControlPool::new_slot(USER_NAME& user)
{
	if(get_slot(user))
	{
		LOG(LOG_ERROR, "slot for(%s) exists", user.str());
		return NULL;
	}

	CDataControlSlot* pnew = new CDataControlSlot;
	if(!pnew)
	{
		LOG(LOG_ERROR, "new_slot = NULL");
		return NULL;
	}

	pnew->user = user;
	pnew->state = 0;
	pnew->timerID = 0;
	pnew->phosttoolkit = m_phosttoolkit;
	slots.push_back(pnew);

	return pnew;
}

CDataControlSlot* CDataControlPool::get_slot(USER_NAME& user, int* retIdx)
{
	for(unsigned int i=0; i<slots.size(); ++i)
	{
		if(slots[i]->user == user)
		{
			if(retIdx)
			{
				*retIdx = i;
			}
			return slots[i];
		}
	}

	return NULL;
}


CDataControlSlot* CDataControlPool::get_slot(int idx)
{
	if(idx >=0 && idx < (int)slots.size())
	{
		return slots[idx];
	}

	return NULL;
}

CDataControlSlot* CDataControlPool::get_slot_bytimer(unsigned int timerID)
{
	if(timerID == 0)
		return NULL;

	for(unsigned int i=0; i<slots.size(); ++i)
	{
		if(slots[i]->timerID == timerID)
		{
			return slots[i];
		}
	}

	return NULL;
}


CDataControlPool::~CDataControlPool()
{
	for(unsigned int i=0; i<slots.size(); ++i)
	{
		if(slots[i])
		{
			delete slots[i];
			slots[i] = NULL;
		}
	}
}
