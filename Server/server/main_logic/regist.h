#ifndef __MAIN_REGIST_LOGIN_H__
#define __MAIN_REGIST_LOGIN_H__

#include "logic/driver.h"
#include "user_data_base.h"

#include "proto/CmdLogin.pb.h"

class CLogicRegist:public CUserDataBase
{
public:
	virtual void on_init();
	
	//��msg�����ʱ�򼤻����
	virtual int on_active_sub(CLogicMsg& msg);

	
	//��������ǰ����һ��
	virtual void on_finish();
	
	virtual CLogicProcessor* create();

	int on_set_data_sub(USER_NAME& user, CDataControlSlot* dataControl);

	int send_fail_resp(int code = 0);
protected:
	unsigned int m_saveReqQueue;
	//RegistReq m_req;
	RegistReq m_req;
	LoginResp m_resp;
};

#endif

