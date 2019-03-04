#ifndef __DATA_CONTROL_H__
#define __DATA_CONTROL_H__

/*
* 任何对user data的修改都通过CDataControl来操作
*/

#include <vector>
#include "common/msg_define.h"
#include "log/log.h"
#include "data_cache/data_cache_api.h"

#include "proto/gateway.pb.h"
#include "common/user_distribute.h"
#include <iostream>
#include <sstream>
#include "online_cache.h"

#include <stdint.h>
#include "proto/CmdLogin.pb.h"
#include "proto/UserInfo.pb.h"
#include "proto/Item.pb.h"
#include "proto/Mail.pb.h"
//#include "proto/knight.pb.h"
#include "proto/AirShip.pb.h"

using namespace std;

extern int gDebugFlag;
extern unsigned int MSG_QUEUE_ID_LOGIC;
extern unsigned int MSG_QUEUE_ID_DB;
extern unsigned int FLAG_SVRSET;
//extern CFightBoxConf gFightBoxConf;
//extern CFightMain gFightMain;
//extern CUserDistribute gDistribute; 
extern int gInfoDetail;
//extern CTaskChainPool gTaskChainPool;
extern unsigned int MSG_QUEUE_ID_GATEWAY;
extern COnlineCache gOnlineCache;
//extern CConfhuodong gConfHuodong;

#define KEEP_OLD_EXPR_MODIFY 1
#define VAL_INT32_MAX 2100000000
#define MAX_SHOPLIMIT_BUY_TIMES 3
#define KAIXIN_PLATFORM_ID 10001

class CDataControlSlot
{
public:
	CDataControlSlot();

	inline int flag_to_bit(unsigned int flag)
	{
		for(int i=0; i<DATA_BLOCK_ARRAY_MAX; ++i)
		{
			if(flag == (unsigned int)(1<< i))
			{
				return i;
			}
		}

		return DATA_BLOCK_ARRAY_MAX;
	}

	inline void fill_get_from_flags(unsigned int flags, bool lock)
	{
		theSet.get_clear_obj();
		for(int i=0; i<DATA_BLOCK_ARRAY_MAX; ++i)
		{
			if(flags & (1<<i))
			{
				theSet.add_get_req(i, lock);
			}
		}
	}

	inline void set_unlock_flag()
	{
		for(int i=0; i<theSet.get_obj().blocks_size(); ++i)
		{
			DataBlock* pblock = theSet.get_obj().mutable_blocks(i);
			pblock->set_unlock(1);
		}
	}

	//封装好的操作
	int get_main_data(UserInfo& theUserProto);
	int set_main_data(UserInfo& theUserProto);
	int get_ship_list(ShipList& theUserProto);
	int set_ship_list(ShipList& theUserProto);
	int get_item_package(ItemList& theUserProto);
	int set_item_package(ItemList& theUserProto);
	int get_mail_list(MailList &theProto);
	int set_mail_list(MailList &theProto);

	// for lua modules
	int get_data_to_string(unsigned int flag, string &buf);
	int set_data_from_string(unsigned int flag, string &buf);

	//删除block的buff
	int clear_block(int flag);

	int create_new_data(USER_NAME &user_name, RegistReq* pregist/*, LoginResp& resp*/);

	int make_login_resp(USER_NAME &name, UserInfo& userinfo, ShipList &ship_list, ItemList &item_list, MailList &mail_list,
		LoginResp& resp, bool needUpdate=true, LoginReq* preq=NULL);

public:
	//int assign_monsters_to_formation(CurFormation* formation, BagMonsters* monsters);


public:	
	inline void get_now_day_hour(time_t nowtime, int& day, int& hour)
	{
		struct tm tm;
		localtime_r(&nowtime, &tm);
		//2011年了
		day = (tm.tm_year-110)*1000 + tm.tm_yday;
		hour = tm.tm_hour;
		//1分=1天
		//day =(((tm.tm_year-110)*1000 + tm.tm_yday)*24 + hour)*60+tm.tm_min;
	}
	//随便找个地方写了
	static inline void send_log_to_gateway(USER_NAME& user, QQLogReq& thereq, CToolkit* ptoolkit, int level=0)
	{
		char buff[32] = {0};
		if(thereq.logtype() == thereq.ONLINE_STAT)
		{
			snprintf(buff, sizeof(buff), "%d", gOnlineCache.onlineNum());
			thereq.add_names("user_num");
			thereq.add_values(buff);
		}
		else if(thereq.logtype() == thereq.PAYMENT)
		{
			//thereq.set_domain(2);
			thereq.set_userip(2334766602);
			thereq.set_userkey("23763CA2CE68DBF1D32748CCD098820A");
			//LOG(LOG_INFO, "%s|send_log_to_gateway pay log ", user.str());
		}
		else
		{
			unsigned int theIdx;
			ONLINE_CACHE_UNIT * punit=NULL;
			if(gOnlineCache.getOnlineRef(user, theIdx, punit)!=0)
			{
				LOG(LOG_ERROR, "%s|send_log_to_gateway not online", user.str());
				return;
			}
			
			//LOG(LOG_INFO, "%s|send_log_to_gateway online ok", user.str());
			if(punit == NULL)
			{
				LOG(LOG_ERROR, "%s|send_log_to_gateway punit==NULL", user.str());
				return;
			}
			
			//LOG(LOG_INFO, "%s|send_log_to_gateway online punit ok", user.str());
			//thereq.set_domain(punit->userdomain);
			thereq.set_userip(punit->userip);
			thereq.set_userkey(punit->userkey);
			
			if(thereq.logtype() == thereq.LOGOUT)
			{
				int onlinetime = time(NULL)-punit->loginTime;
				if(onlinetime > 0)
					snprintf(buff, sizeof(buff), "%d", onlinetime);
				else
					snprintf(buff, sizeof(buff), "%d", 1);
				thereq.add_names("onlinetime");
				thereq.add_values(buff);
			}
		}

		thereq.add_names("level");
		snprintf(buff, sizeof(buff), "%d", level);
		thereq.add_values(buff);

		//LOG(LOG_INFO, "%s|send_log_to_gateway before send", user.str());
		if(ptoolkit->send_protobuf_msg(gDebugFlag, thereq, CMD_GATEWAY_LOG_REPORT_REQ,
			user, MSG_QUEUE_ID_GATEWAY) !=0)
		{
			LOG(LOG_ERROR, "send_log_to_gateway send fail");
		}
		//LOG(LOG_INFO, "%s|send_log_to_gateway after send", user.str());
	}

public:
	USER_NAME user;
	CDataBlockSet theSet;
	int state;
	bool guest;
	unsigned int timerID;
	CToolkit* phosttoolkit;
	bool silent;
};

class CDataControlPool
{
public:
	//新建一个slot
	CDataControlSlot* new_slot(USER_NAME& user);
	//返回slot的指针，NULL=没有找到, retIdx 不为null就返回索引
	CDataControlSlot* get_slot(USER_NAME& user, int* retIdx = NULL);

	//使用索引返回指针，idx不合法返回NULL
	CDataControlSlot* get_slot(int idx);

	CDataControlSlot* get_slot_bytimer(unsigned int timerID);

	CDataControlPool()
	{
		m_phosttoolkit = NULL;
	}

	inline void attach_toolkit(CToolkit* ptoolkit)
	{
		m_phosttoolkit = ptoolkit;
	}

	~CDataControlPool();

public:
	vector<CDataControlSlot*> slots;
	CToolkit* m_phosttoolkit;
};

#endif

