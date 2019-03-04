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
	
	//有msg到达的时候激活对象
	virtual int on_active(CLogicMsg& msg);

	
	//对象销毁前调用一次
	virtual void on_finish();
	
	virtual CLogicProcessor* create();

	//nothing=0 客户端
	//nothing=1 断网
	//nothing=2 重复登录，dbsvr发送过来的
	//nothing=3 check online 超时
	//nothing=4 无法分配定时器
	void do_logout(USER_NAME& user, int nothing, CLogicMsg* pmsgfromdb);
};

#endif

