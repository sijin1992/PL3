#ifndef __GLOBAL_LOGIC_LOGPROXY_H__
#define __GLOBAL_LOGIC_LOGPROXY_H__

#include "logic/driver.h"

extern int gDebugFlag;
class CLogicLogProxy: public CLogicProcessor
{
public:
	virtual void on_init();

	virtual int on_active(CLogicMsg& msg);
	
	//对象销毁前调用一次
	virtual void on_finish();
	
	virtual CLogicProcessor* create();

protected:
#define LOG_STR_BUFF_SIZE 1024 *10
	static char sBuff[LOG_STR_BUFF_SIZE];
	static const char *sDBName;
};


#endif 

