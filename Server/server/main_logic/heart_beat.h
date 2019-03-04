#ifndef __MAIN_LOGIC_HEART_BEAT_H__
#define __MAIN_LOGIC_HEART_BEAT_H__

#include "logic/driver.h"
#include "proto/heartBeatResp.pb.h"


class CLogicHeartBeat: public CLogicProcessor
{
public:
	virtual void on_init();
	
	//有msg到达的时候激活对象
	virtual int on_active(CLogicMsg& msg);
	
	//对象销毁前调用一次
	virtual void on_finish();

	virtual CLogicProcessor* create();
};

#endif

