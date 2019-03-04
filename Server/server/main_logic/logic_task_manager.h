#ifndef __LOGIC_TASK_MANAGER_H__
#define __LOGIC_TASK_MANAGER_H__

#include <string>

#include "lua_cmd_handle.h"
#include "common/msg_define.h"
#include "user_data_base.h"
#include "data_control.h"
#include "proto/UserInfo.pb.h"
#include "proto/Group.pb.h"

enum
{
	TA_USER_DATA = 1,
	TA_GROUP_DATA = 10,
};

enum
{
	TA_MAIN_DATA = 0,
	TA_SHIP_LIST = 1,
	TA_PACKAGE_DATA = 2,
	TA_MAIL_LIST = 3,
	TA_MAX = 4,
};

enum
{
	TM_NEXT = 0,
	TM_YIELD = 1,
	TM_DONE = 2,
	TM_UNKNOW = -1,
};

struct TaskArgs
{
	int data_type;
	int data_flag;
	bool lock;
	bool save;
	USER_NAME name;
	std::string *data[TA_MAX];
	CDataControlSlot *slot;
	bool create;
	bool try_data;
	//*::google::protobuf::Message user_info;
public:
	TaskArgs()
	{
		memset(data, 0, sizeof(data));
		lock = false;
		save = false;
		data_type = 0;
		data_flag = 0;
		create = false;
	}

	~TaskArgs()
	{
		for (int i = 0; i < TA_MAX; ++i)
			if(data[i] != NULL)
				delete data[i];
	}
	
};




class LogicTaskManager
{
public:
	USER_NAME m_name;
	size_t m_step;					// 当前步骤
	size_t m_args_num;
	size_t m_received_num;			// 已经取得的参数
	CUserDataBase *m_data_handle;	// 
	LUA_handle *m_lua;				// 执行任务的lua_handle
	TaskArgs *m_args;
	std::string *m_req;				// 客户端的请求
	std::string *m_resp_fail;		// 如果处理失败就发这个返回
	std::string *m_resp;			// 如果处理成功就发这个返回
	bool m_is_valid;
	int m_act_resp;					// 待返回的消息。0 = 成功，1 = 失败，-1 = 不发送
	int m_cmd;
	int m_ext_cmd1;					// 返回的额外消息
	std::string m_ext_resp1;
	int m_ext_cmd2;					// 返回的额外消息
	std::string m_ext_resp2;

	
public:
	LogicTaskManager();
	~LogicTaskManager();
	void init(CUserDataBase *data_handle, LUA_handle *lua, USER_NAME &name,
		std::string *req, std::string *resp_fail, std::string *resp, int cmd);		// 初始化
	inline bool is_valid() {return m_is_valid;}
	int run();
	int on_get_data(CDataControlSlot *data_slot);				// 在获取到数据后,调用这个函数,自动填充并判断下一步任务
	int on_set_data(CDataControlSlot * data_slot);
	void clear();
	inline int act_resp() {return m_act_resp;}
	inline int ext_cmd1() {return m_ext_cmd1;}
	inline std::string *ext_resp1(){return &m_ext_resp1;}
	inline int ext_cmd2() {return m_ext_cmd2;}
	inline std::string *ext_resp2(){return &m_ext_resp2;}
public:
	int hook_get_ok(GroupMainData* p);
	int hook_get_nodata(GroupMainData* p);
	int hook_lockget_ok(GroupMainData* p);
	int hook_set_ok();
	int hook_unlock_ok();
	int hook_create_ok(GroupMainData* pdata);

	int on_get_group_data(GroupMainData *group_data);
	int on_set_group_data();

	// 调用一个指定的lua函数
	int call_lf(const char*);

private:
	int get_feature_order();
	int prepare_data();			// 从lua中得知,下一个待获取的数据
	int do_next();												// 进行下一步处理。内部会自动判断当前状态并处理
	
	int set_next_data();
	int do_logic();					// 获得所有数据后, 处理实际逻辑
	// 从dataslot中获取一个数据
	int get_sub_data(std::string **buf, int flag, CDataControlSlot *data_slot);
	// 从dataslot中批量获取所有数据
	int fill_data_to(TaskArgs *arg, CDataControlSlot *data_slot);
};

#endif // __LOGIC_TASK_MANAGER_H__

