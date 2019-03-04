#ifndef __USER_DATA_BASE_H__
#define __USER_DATA_BASE_H__

#include "logic/driver.h"
#include "data_control.h"
#include "data_cache/data_cache_api.h"
#include "online_cache.h"
#include "binary/binary_util.h"
#include "common/user_distribute.h"
//#include "proto/dbmodify.pb.h"
//#include "proto/groupbattle.pb.h"

//该类封装了获取和设置userdata的操作
//任何需要操纵userdata的类都需要使用
extern unsigned int MSG_QUEUE_ID_DB;
extern int gDebugFlag;
extern CUserDistribute gDistribute; 

//带user的日志
#define LOG_USER(loglevel,format,args...) LOG(loglevel, "%s|"format, m_saveUser.str(), ##args)

class CUserDataBase:public CLogicProcessor
{
public:
	static const int TIMEOUT_FLAG_GET = 1;
	static const int TIMEOUT_FLAG_SET = 2;
	//状态维护
	enum ALL_CONTROL_STATE
	{
		CONTROL_STATE_START = 0,
		CONTROL_STATE_WAIT_GET,
		CONTROL_STATE_WAIT_LOCKGET,
		CONTROL_STATE_GET_OK,
		CONTROL_STATE_LOCKGET_OK,
		CONTROL_STATE_WAIT_SET,
		CONTROL_STATE_WAIT_UNLOCKSET,
		CONTROL_STATE_WAIT_UNLOCK,
		CONTROL_STATE_WAIT_CREATE
	};	
public:

	CUserDataBase();
	
	virtual void on_init();
	virtual int on_active(CLogicMsg& msg);
	//对象销毁前调用一次
	virtual void on_finish();


protected:
	//data消息处理函数
	int on_get_resp(CLogicMsg& msg, unsigned int cmd);
	int on_set_resp(CLogicMsg& msg, unsigned int cmd);
	int on_db_timeout(CLogicMsg& msg);

public:
	//API for sub class use
	inline int loginget_user_data(USER_NAME& user, unsigned int flags)
	{
		return get_user_data_inner(user, flags, true, true, false);
	}

	//guest = true, 不使用tmpcache
	inline int get_user_data(USER_NAME& user, unsigned int flags, bool guest = false)
	{
		return get_user_data_inner(user, flags, false, false, guest);
	}
	
	//guest = true, 不使用tmpcache
	inline int lockget_user_data(USER_NAME& user, unsigned int flags, bool guest = false)
	{
		return get_user_data_inner(user, flags, true, false, guest);
	}

	//guest = true, 不使用tmpcache
	//noresp = true, 不用回包, 仅在guest下有效
	inline int set_user_data(USER_NAME& user, bool guest = false, bool noresp = false)
	{
		return set_user_data_inner(user, false, false, NULL, guest, noresp);
	}
	
	//guest = true, 不使用tmpcache
	//noresp = true, 不用回包, 仅在guest下有效
	inline int unlockset_user_data(USER_NAME& user, bool guest = false, bool noresp = false)
	{
		return set_user_data_inner(user, true, false, NULL, guest, noresp);
	}
	
	//guest = true, 不使用tmpcache
	//noresp = true, 不用回包, 仅在guest下有效
	inline int unlock_user_data(USER_NAME& user, bool guest = false, bool noresp = false)
	{
		return set_user_data_inner(user, true, true, NULL, guest, noresp);
	}
	
	inline int create_user_data(USER_NAME& user, RegistReq& createInfo, LoginResp& resp)
	{
		presp = &resp;
		return set_user_data_inner(user, false, false, &createInfo, false, false);
	}

protected:
	inline int send_proto_to_db(USER_NAME& user, Message& protoobj, unsigned int cmd)
	{
		unsigned int desSvrID;
		if(gDistribute.get_svr(user, desSvrID)!=0)
		{
			return -1;
		}

		if(m_ptoolkit->send_protobuf_msg(gDebugFlag, protoobj,
			cmd, user, MSG_QUEUE_ID_DB,  desSvrID ) != 0)
			return -1;

		return 0;
	}

protected:
	//给子类处理消息，子类切勿覆盖on_active，而是要使用这个
	virtual int on_active_sub(CLogicMsg& msg) = 0;
	virtual int on_get_data_sub(USER_NAME& user, CDataControlSlot* dataControl){return RET_DONE;}
	virtual int on_set_data_sub(USER_NAME& user, CDataControlSlot* dataControl){return RET_DONE;}

private:
	int get_user_data_inner(USER_NAME& user, unsigned int flags, bool lock, bool login, bool guest);
	int set_user_data_inner(USER_NAME& user, bool unlock, bool nodata, RegistReq* pCreateInfo, bool guest, bool noresp);
	
protected:
	CDataControlPool m_pool; 
	CDataCacheTmp m_tmpcache;
	LoginResp* presp;
	USER_NAME m_saveUser;
	int m_saveCmd;
	int m_saveLevel;
};

#define PARSE_USER_INFO(userInfo) \
	const ExtData &extData = userInfo.ext_data();\
	int level = userInfo.lead().level(); /*主角等级*/ \
	int stagelv = userInfo.lead().star(); /*主角星级*/\
	int exp = userInfo.lead().exp();	/*主角经验*/ \
	int vipLevel = userInfo.vip_lev(); /*vip等级*/ \
	int vipScore = userInfo.vip_score(); /*vip积分*/ \
	int totalDep = extData.total_money(); /*总充值*/ \
	int totalRMB = extData.total_rmb(); /*总付费*/ \
	int gold = userInfo.gold(); /*银币*/ \
	int money = userInfo.money(); /*总元宝*/ \
	int php = userInfo.tili(); /*体力*/ \
	int state = (userInfo.has_blocked() && userInfo.blocked().type() != 0) ? 1 : 0; /*状态*/ \
	int maxpower = userInfo.ext_data().max_power().max_power(); /*最大战斗力*/ \
	int maxrank = userInfo.pvp().highest_rank(); /*历史最高排名*/\
	const char *menpai = userInfo.group_data().groupid().c_str(); /*帮派ID*/\
	const char *acc = userInfo.account().c_str(); /*账号*/ \
	const char *ip = userInfo.ip().c_str();	/*ip*/ \
	const char *mmc = userInfo.mcc().c_str();	/*mmc*/ \
	const char *qudao = "unknown-qd";	/*渠道*/ \
	const char *nick = "unknown-nick"; /*昵称*/ \
	char buff[128] = {0};\
	if( userInfo.mcc().empty() ) mmc = "unknown-mmc"; \
	if( userInfo.account().empty() ) acc = "unknown-acc"; \
	if( !userInfo.nickname().empty() )\
		{\
		nick = userInfo.nickname().c_str();\
	}\
	if(userInfo.has_platform()){\
		snprintf(buff, sizeof(buff), "%d", userInfo.platform());\
		qudao = buff;\
	}
	
	
#define SNAP_USER(username) \
	LOG_STAT_USER(username, nick, qudao, level, exp, vipLevel, vipScore, totalDep, totalRMB, gold, money, php, maxpower, state, stagelv, maxrank, menpai)


//背包快照(用户ID，凯旋令，龙纹令，武魂，门派威望，门派奖章)
#define PARSE_BAG_LIST(userInfo, bagList) \
	int kxl = userInfo.pvp().pvp_gold(); /*凯旋令*/ \
	int lwl = userInfo.pve().pve2().pve2_gold(); /*龙纹令*/\
	int wh = userInfo.xyshop().ghost();	/*武魂*/ \
	int mpww = userInfo.group_data().sw(); /*门派威望*/\
	int mpjz = userInfo.group_data().paizi(); /*门派奖章*/

#define SNAP_BAG(uid) \
	LOG_STAT_DATA(uid, STAT_BAG, "%d|%d|%d|%d|%d", kxl, lwl, wh, mpww, mpjz);




#endif

