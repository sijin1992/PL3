//to-do: �滻CLogicYYYΪ�Լ�������
//to-do: �滻LOGICYYYΪ�Լ���������д
//to-do: �滻YYYReqΪ�����pb�ļ���
//to-do: �滻YYYRespΪӦ���pb�ļ���
//to-do: �޸���ע�͵Ĳ���


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

	
	//��������ǰ����һ��
	virtual void on_finish();
	
	virtual CLogicProcessor* create();

protected:
	
};


#endif 

