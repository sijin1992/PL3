//to-do: 替换CLogicYYY为自己的类名
//to-do: 替换LOGICYYY为自己的类名大写
//to-do: 替换YYYReq为请求的pb文件名
//to-do: 替换YYYResp为应答的pb文件名
//to-do: 修改有注释的部分


#ifndef __SERVERYYY_LOGICYYY_H__
#define __SERVERYYY_LOGICYYY_H__

#include "logic/driver.h"
/*
#include "proto/YYYReq.pb.h"
#include "proto/YYYResp.pb.h"
*/

extern int gDebug;

class CLogicYYY:public CLogicProcessor
{
public:
	virtual void on_init();

	virtual int on_active(CLogicMsg& msg);

	
	//对象销毁前调用一次
	virtual void on_finish();
	
	virtual CLogicProcessor* create();

protected:
	
};


#endif 

