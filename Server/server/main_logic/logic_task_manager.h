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
	size_t m_step;					// ��ǰ����
	size_t m_args_num;
	size_t m_received_num;			// �Ѿ�ȡ�õĲ���
	CUserDataBase *m_data_handle;	// 
	LUA_handle *m_lua;				// ִ�������lua_handle
	TaskArgs *m_args;
	std::string *m_req;				// �ͻ��˵�����
	std::string *m_resp_fail;		// �������ʧ�ܾͷ��������
	std::string *m_resp;			// �������ɹ��ͷ��������
	bool m_is_valid;
	int m_act_resp;					// �����ص���Ϣ��0 = �ɹ���1 = ʧ�ܣ�-1 = ������
	int m_cmd;
	int m_ext_cmd1;					// ���صĶ�����Ϣ
	std::string m_ext_resp1;
	int m_ext_cmd2;					// ���صĶ�����Ϣ
	std::string m_ext_resp2;

	
public:
	LogicTaskManager();
	~LogicTaskManager();
	void init(CUserDataBase *data_handle, LUA_handle *lua, USER_NAME &name,
		std::string *req, std::string *resp_fail, std::string *resp, int cmd);		// ��ʼ��
	inline bool is_valid() {return m_is_valid;}
	int run();
	int on_get_data(CDataControlSlot *data_slot);				// �ڻ�ȡ�����ݺ�,�����������,�Զ���䲢�ж���һ������
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

	// ����һ��ָ����lua����
	int call_lf(const char*);

private:
	int get_feature_order();
	int prepare_data();			// ��lua�е�֪,��һ������ȡ������
	int do_next();												// ������һ�������ڲ����Զ��жϵ�ǰ״̬������
	
	int set_next_data();
	int do_logic();					// ����������ݺ�, ����ʵ���߼�
	// ��dataslot�л�ȡһ������
	int get_sub_data(std::string **buf, int flag, CDataControlSlot *data_slot);
	// ��dataslot��������ȡ��������
	int fill_data_to(TaskArgs *arg, CDataControlSlot *data_slot);
};

#endif // __LOGIC_TASK_MANAGER_H__

