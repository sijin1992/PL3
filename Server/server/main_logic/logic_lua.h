#ifndef __LOGIC_LUA_H__
#define __LOGIC_LUA_H__

#include "logic/driver.h"
#include "user_data_base.h"

#include "lua_cmd_handle.h"
#include "logic_task_manager.h"

#include "usergroup.h"
class CLogicLUA;
class CLogicLUAGroupHookImp: public CLogicUserGroupHook
{
	public:
		CLogicLUA* pobj;
	public:
		virtual ~CLogicLUAGroupHookImp(){}	
		int hook_on_state(int retcode, int state, GroupMainData* pdata);
};

class CLogicLUA:public CUserDataBase
{
public:
	virtual void on_init();	
	virtual int on_active_sub(CLogicMsg& msg);
	//对象销毁前调用一次
	virtual void on_finish();
	virtual CLogicProcessor* create();
	int on_get_data_sub(USER_NAME & user, CDataControlSlot* dataControl);
	int on_set_data_sub(USER_NAME & user,CDataControlSlot * dataControl);

public:
	int send_resp();

public:
	int get_group(string groupid, bool lock);
	int set_group(string data, string groupid, bool create);
	int unlock_group(bool nocallback = false);

public:
	int hook_get_ok(GroupMainData* p);
	int hook_get_nodata(GroupMainData* p);
	int hook_lockget_ok(GroupMainData* p);
	int hook_set_ok();
	int hook_unlock_ok();
	int hook_create_ok(GroupMainData* pdata);
	
private:
	inline int check_and_refresh_online_info()
	{
		// 检测和刷新在线信息
		ONLINE_CACHE_UNIT* punit;
		if(gOnlineCache.getOnlineUnit(m_saveUser, punit)!= 0)
		{
			return -1;
		}
		else if(punit == NULL)
		{
			return -1;
		}
		return 0;
	}
	

private:
	inline int run()
	{
		int ret = m_task_manager.run();
		if(ret < 0)
			return send_resp();
		else if(ret == TM_YIELD)
			return RET_YIELD;
		else
			return send_resp();
	}
	

protected:
	char* m_dumpMsgBuff;
	int m_dumpMsgLen;
private:
	bool m_locked;
	unsigned int m_queue_id;
private:
	LUA_handle *m_lua_handle;
	string m_req;
	string m_resp_fail;
	string m_resp;
	LogicTaskManager m_task_manager;

	string m_lockedgroup;
	CLogicLUAGroupHookImp m_hook;
	CLogicUserGroupHelper m_helper;
};


#endif 

