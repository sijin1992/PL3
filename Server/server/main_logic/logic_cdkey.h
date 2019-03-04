#ifndef __MAIN_LOGIC_CDKEY_H__
#define __MAIN_LOGIC_CDKEY_H__

#include "logic/driver.h"
#include "user_data_base.h"
//#include "proto/cmd_huodong.pb.h"
#include "lua_manager.h"


class CLogicCDKEY:public CUserDataBase
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
	int send_resp(int code = 0);

protected:
	char* m_dumpMsgBuff;
	int m_dumpMsgLen;
	UserInfo m_main_data;

	CDataControlSlot* m_dataControl;
	
	bool m_userlocked;
	int m_status;

	//CDKEY_Resp m_resp;
};


#endif 

