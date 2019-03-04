#ifndef __MAIN_LOGIC_LOGIN_H__
#define __MAIN_LOGIC_LOGIN_H__

#include "logic/driver.h"
#include "user_data_base.h"

#include "proto/CmdLogin.pb.h"

//��ʱ����ȫ����֤ͨ����
class CLogicLogin:public CUserDataBase
{
public:
	virtual void on_init();
	
	//��msg�����ʱ�򼤻����
	virtual int on_active_sub(CLogicMsg& msg);

	
	//��������ǰ����һ��
	virtual void on_finish();
	
	virtual CLogicProcessor* create();

	virtual int on_get_data_sub(USER_NAME& user, CDataControlSlot* dataControl);
	virtual int on_set_data_sub(USER_NAME& user, CDataControlSlot* dataControl);

protected:
	unsigned int m_saveReqQueue;
	LoginReq m_req;
};

#endif

