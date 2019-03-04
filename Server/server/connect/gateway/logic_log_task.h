#ifndef __LOGIC_LOG_TASK_H__
#define __LOGIC_LOG_TASK_H__

#include "logic/driver.h"
#include "proto/gateway.pb.h"
#include <sstream>
#include "log_adapter.h"

extern int gDebug;
extern unsigned int MSG_QUEUE_ID_LOGIC_TASK;
extern CQQLogAdapter gadapter;
extern int gCloseLog;

//��ʱ����ȫ����֤ͨ����
class CLogicQQLog:public CLogicProcessor
{
public:
	virtual void on_init()
	{
	}
	
	//��msg�����ʱ�򼤻����
	virtual int on_active(CLogicMsg& msg)
	{
		//������
		int cmd = m_ptoolkit->get_cmd(msg);
		if(gDebug)
			LOG(LOG_DEBUG,"recv cmd(0x%x) ", cmd);
		
		if(cmd == CMD_GATEWAY_LOG_REPORT_REQ)
		{
			QQLogReq req;
			USER_NAME user ;
			if(m_ptoolkit->parse_protobuf_msg(gDebug, msg,  user, req) !=0)
			{
				LOG(LOG_ERROR, "%s|parse_protobuf_msg QQLogReq fail", user.str());
				return RET_DONE;
			}

			if(!gCloseLog)
			{
				gadapter.log(user, req);
			}
		}
		else
			LOG(LOG_ERROR, "unexpect cmd=%u" ,m_ptoolkit->get_cmd(msg) );

		return RET_DONE;
	}

	
	//��������ǰ����һ��
	virtual void on_finish()
	{
	}
	
	virtual CLogicProcessor* create()
	{
		return new CLogicQQLog;
	}
};

#endif

