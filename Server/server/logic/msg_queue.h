#ifndef __LOGIC_MSG_QUEUE_H__
#define __LOGIC_MSG_QUEUE_H__

#include "../common/queue_pipe.h"
#include "msg.h"
#include "log/log.h"
#include "net/tcpwrap.h"
#include <string>
using namespace std;

//��֧�ֲ�������queue_pipe

class CMsgQueue
{
public:
	static const int EMPTY = 1;
	static const int OK = 0;
	static const int ERROR = -1;

	//���������ֵ
	virtual int get_msg(CLogicMsg& msg) = 0;
	virtual int send_msg(CLogicMsg& msg) = 0;
	virtual ~CMsgQueue() {}
	CMsgQueue():id(0) {}
public:
	unsigned int id;
};

class CMsgQueuePipe:public CMsgQueue
{
public:	
	CMsgQueuePipe(CDequePIPE& queue, int* pdebug=NULL):m_queue(queue),m_allowNew(false), m_pdebug(pdebug)
	{
	}

	//Σ�գ����Ʋ��þ��ڴ�й¶��
	inline void allow_msg_replacebuff()
	{
		m_allowNew = true;
	}

	int get_msg(CLogicMsg& msg);

	int send_msg(CLogicMsg& msg);

protected:
	CDequePIPE& m_queue;
	bool m_allowNew;
	int* m_pdebug;
};


#endif

