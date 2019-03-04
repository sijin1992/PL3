#ifndef __MAIN_LOGIC_HEART_BEAT_H__
#define __MAIN_LOGIC_HEART_BEAT_H__

#include "logic/driver.h"
#include "proto/heartBeatResp.pb.h"


class CLogicHeartBeat: public CLogicProcessor
{
public:
	virtual void on_init();
	
	//��msg�����ʱ�򼤻����
	virtual int on_active(CLogicMsg& msg);
	
	//��������ǰ����һ��
	virtual void on_finish();

	virtual CLogicProcessor* create();
};

#endif

