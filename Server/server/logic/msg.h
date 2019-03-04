#ifndef __LOGIC_MSG_H__
#define __LOGIC_MSG_H__

#include "mem_alloc/mem_alloc.h"
#include <string.h>
#include <iostream>
using namespace std;

class CLogicMsg
{
public:
	const static int MSG_BUFF_DEFAULT_SIZE = 10*1024;
	const static unsigned int QUEUE_ID_FOR_TIMER = 0;
public:
	struct MSG_HEAD
	{
		unsigned int cmdID; //消息命令id
		unsigned int srcServerID; //来源server
		unsigned int desServerID; //目的server 
		unsigned int srcHandleID; //来源处理者
		unsigned int desHandleID; //目的处理者
		unsigned int queueID;  //从那个queue来的, 定时器QUEUE_ID_FOR_TIMER
		unsigned int bodySize; //负载的信息长度
		char reserve[36];  //待扩展
		void debug(ostream& os);
	};

public:
	//使用外部固定分配的内存buff
	CLogicMsg(char* buff, unsigned int buffsize, bool needDel=false);

	int replace_buffer(char* buff, unsigned int buffsize, bool needDel=false);

	//使用内存分配器，注意外部的分配器的生命期，最好是全局的
	CLogicMsg(CMemAlloc* palloc, unsigned int size=MSG_BUFF_DEFAULT_SIZE);

	~CLogicMsg();

	inline bool valid()
	{
		return (m_buff != NULL) && (m_buffsize>=sizeof(MSG_HEAD) && (m_buffsize>=sizeof(MSG_HEAD)+head()->bodySize) );
	}

	inline MSG_HEAD* head()
	{
		return (MSG_HEAD*)m_buff;
	}

	inline char* body()
	{
		return sizeof(MSG_HEAD)+m_buff;
	}

	inline unsigned int body_buff_len()
	{
		return  m_buffsize - sizeof(MSG_HEAD);
	}

	inline char* buff()
	{
		return m_buff;
	}

	inline unsigned int buff_len()
	{
		return m_buffsize;
	}

	inline bool verify_size(unsigned int packetlen)
	{
		return packetlen == data_len();
	}

	inline unsigned int data_len()
	{
		return head()->bodySize + sizeof(MSG_HEAD);
	}

	inline unsigned int dump(char*& retBuff)
	{
		if(!m_buff)
		{
			retBuff = NULL;
			return 0;
		}
		
		unsigned int len = data_len();
		retBuff = new char[len];
		if(retBuff)
		{
			memcpy(retBuff, m_buff, len);
			return len;
		}
		else
			return 0;
	}

protected:
	inline void free_buff()
	{
		if(m_palloc && m_pmemnode)
		{
			m_palloc->free(m_pmemnode);
			m_pmemnode = NULL;
		}
		else
		{
			if(m_buff && m_needDel)
			{
				delete[] m_buff;
			}
		}
		
		m_buff = NULL;
		m_buffsize = 0;
	}
	
protected:
	char* m_buff;
	unsigned int m_buffsize;
	CMemAlloc* m_palloc;
	CMemAlloc::MEM_NODE* m_pmemnode;
	bool m_needDel;
};

#endif

