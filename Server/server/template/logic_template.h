//to-do: 替换__MAIN_LOGIC_TEMPLATE_H__为自己的宏
//to-do: 替换TemplateProtocol为自己的proto文件名
//to-do: 替换CLogicTemplate为自己的类名字
//to-do: 替换ProtoTemplateResp为应答的proto对象


#ifndef __MAIN_LOGIC_TEMPLATE_H__
#define __MAIN_LOGIC_TEMPLATE_H__

#include "logic/driver.h"
#include "user_data_base.h"
#include "proto/TemplateProtocol.pb.h"

class CLogicTemplate:public CUserDataBase
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
	int send_resp(CLogicMsg& msg, bool fail = true);

protected:
	USER_NAME m_saveUser;
	int m_saveCmd;
	char* m_dumpMsgBuff;
	int m_dumpMsgLen;
	UserData m_theUserProto;
	ProtoTemplateResp m_resp;
	bool m_locked;
};


#endif 

