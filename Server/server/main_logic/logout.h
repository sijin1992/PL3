#ifndef __MAIN_LOGIC_LOGOUT_H__
#define __MAIN_LOGIC_LOGOUT_H__

#include "logic/driver.h"
//#include "logic_randbattle.h"
#include "proto/logoutReq.pb.h"
#include "proto/logoutResp.pb.h"

//extern UNIT *gRandBattleUnit;
//extern HEAD *gRandBattleHead;

class CLogicLogout:public CLogicProcessor
{
public:
	virtual void on_init();
	
	//��msg�����ʱ�򼤻����
	virtual int on_active(CLogicMsg& msg);

	
	//��������ǰ����һ��
	virtual void on_finish();
	
	virtual CLogicProcessor* create();

	//nothing=0 �ͻ���
	//nothing=1 ����
	//nothing=2 �ظ���¼��dbsvr���͹�����
	//nothing=3 check online ��ʱ
	//nothing=4 �޷����䶨ʱ��
	void do_logout(USER_NAME& user, int nothing, CLogicMsg* pmsgfromdb);
};

#endif

