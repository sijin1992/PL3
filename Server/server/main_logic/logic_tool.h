//to-do: 替换__MAIN_LOGIC_TOOL_H__为自己的宏
//to-do: 替换toolprotocol为自己的proto文件名
//to-do: 替换CLogicTool为自己的类名字
//to-do: 替换ModifyDataResp为应答的proto对象


#ifndef __MAIN_LOGIC_TOOL_H__
#define __MAIN_LOGIC_TOOL_H__

#include "logic/driver.h"
#include "user_data_base.h"

class CLogicTool:public CUserDataBase
{
public:
	virtual void on_init();
	
	virtual int on_active_sub(CLogicMsg& msg);

	
	//对象销毁前调用一次
	virtual void on_finish();
	
	virtual CLogicProcessor* create();

	int on_get_data_sub(USER_NAME & user, CDataControlSlot* dataControl);
	int on_set_data_sub(USER_NAME & user,CDataControlSlot * dataControl);

protected:
	int send_fail_resp(CLogicMsg& msg);

	//int caculate_allbuidingbonus();

	int check_password(const string& password);

protected:
	char* m_dumpMsgBuff;
	int m_dumpMsgLen;
	//UserData m_theUserProto;
	//BagList m_theBagProto;
	//ModifyDataResp m_resp;
};


#endif 

