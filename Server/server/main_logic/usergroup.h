#pragma once
#include "data_cache/data_cache_api.h"
#include "proto/datablock.pb.h"
#include "proto/Group.pb.h"
#include "proto/UserInfo.pb.h"
#include "common/msg_define.h"
#include "logic/driver.h"

#include <string>
#include <vector>

extern unsigned int FLAG_SVRSET;
extern unsigned int MSG_QUEUE_ID_DB; //准确的说是到tcplinker
extern int gDebugFlag;
	
using namespace std;

#define DEF_SEND_RESP_MSG(RespObj, ReqCmd, RespCmd ) \
if(m_saveCmd == ReqCmd) \
{ \
	if(code == -1) \
		RespObj.set_result(RespObj.FAIL); \
	else if(code == 0 && !RespObj.has_result()) \
		RespObj.set_result(RespObj.OK); \
	if(m_ptoolkit->send_protobuf_msg(gDebugFlag, RespObj, RespCmd, m_saveUser, m_ptoolkit->get_queue_id(msg)) != 0) \
	{ \
		LOG_USER(LOG_ERROR, "%s", "send "#RespCmd" fail"); \
	} \
}

class CLogicUserGroupHook
{
	public:
	//回调
	virtual ~CLogicUserGroupHook() {}
	virtual int hook_on_state(int retcode, int state, GroupMainData* pdata) = 0;
};


class CLogicUserGroupHelper
{
public:
	enum HOOK_RET{
		HOOK_RET_INNER_FAIL=-1,
		HOOK_RET_OK=0,
		HOOK_RET_NODATA=1,
		HOOK_RET_LOCKED=2,
		HOOK_RET_TIMEOUT=3
	};

	enum LOADING_STATE{
		STATE_INIT = 0,
		STATE_TRY_GET,
		STATE_TRY_LOCKGET,
		STATE_ON_GET,
		STATE_ON_LOCKGET,
		STATE_TRY_CREATE,
		STATE_ON_CREATE,
		STATE_TRY_SET,
		STATE_ON_SET,
		STATE_ON_UNLOCK
	};
	
	static const int CREATE_MONEY=20000000;
	
	CLogicUserGroupHelper();
	~CLogicUserGroupHelper();

	int on_resp(unsigned int cmd, CLogicMsg& msg);

	//入口
	int init(CLogicUserGroupHook* phook, CToolkit* ptoolkit, USER_NAME& loguser, string groupid, unsigned int handleid);
	int get(bool lock=false);
	inline GroupMainData* rawdata()
	{
		return &m_tmpdata;
	}

	//get or lockget 之后可以使用
	int set(bool create=false);
	int unlock(bool nocallback=true);

	//校验用
	inline string getGroupID()
	{
		return m_groupid.to_str();
	}

		
private:
	int on_get(CLogicMsg& msg);
	int on_set(CLogicMsg& msg);

private:
	CDataBlockSet m_set;
	USER_NAME m_groupid;
	USER_NAME m_loguser;
	unsigned int m_timerID;
	bool m_inited;
	CLogicUserGroupHook* m_phook;
	int m_state;
	CToolkit* m_ptoolkit;
	GroupMainData m_tmpdata;
	unsigned int m_handleid;
	int m_locked;
};

