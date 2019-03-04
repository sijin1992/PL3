#ifndef __MAIN_LOGIC_LOGIN_H__
#define __MAIN_LOGIC_LOGIN_H__

#include "logic/driver.h"
#include "user_data_base.h"

#include "proto/CmdLogin.pb.h"

//暂时做成全部验证通过的
class CLogicLogin:public CUserDataBase
{
public:
	virtual void on_init();
	
	//有msg到达的时候激活对象
	virtual int on_active_sub(CLogicMsg& msg);

	
	//对象销毁前调用一次
	virtual void on_finish();
	
	virtual CLogicProcessor* create();

	virtual int on_get_data_sub(USER_NAME& user, CDataControlSlot* dataControl);
	virtual int on_set_data_sub(USER_NAME& user, CDataControlSlot* dataControl);

protected:
	unsigned int m_saveReqQueue;
	LoginReq m_req;
};

#endif

