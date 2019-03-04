#include "msg.h"

void CLogicMsg::MSG_HEAD::debug(ostream & os)
{
	os << "CLogicMsg.MSG_HEAD{" << endl;
	os << "cmdID|" << cmdID << endl;
	os << "srcServerID|" << srcServerID << endl;
	os << "desServerID|" << desServerID << endl;
	os << "srcHandleID|" << srcHandleID << endl;
	os << "desHandleID|" << desHandleID << endl;
	os << "queueID|" << queueID << endl;
	os << "bodySize|" << bodySize << endl;
	os << "}end CLogicMsg.MSG_HEAD" << endl;
}

CLogicMsg::CLogicMsg(char* buff, unsigned int buffsize, bool needDel)
{
	m_palloc = NULL;
	m_pmemnode = NULL;
	m_buff = buff;
	m_buffsize = buffsize;
	m_needDel = needDel;
}

int CLogicMsg::replace_buffer(char* buff, unsigned int buffsize, bool needDel)
{
	if(buffsize >= sizeof(MSG_HEAD))
	{
		free_buff();
		m_buff = buff;
		m_buffsize = buffsize;
		m_needDel = needDel;
		return 0;
	}

	return -1;
}

//使用内存分配器，注意外部的分配器的生命期，最好是全局的
CLogicMsg::CLogicMsg(CMemAlloc* palloc, unsigned int size)
{
	m_buff = NULL;
	m_buffsize = size;
	m_palloc = palloc;
	if(palloc == NULL)
	{
		return;
	}
	
	m_pmemnode = m_palloc->alloc(m_buffsize);
	if(m_pmemnode == NULL)
	{
		return;
	}

	m_buff = m_pmemnode->first_avail;
	m_needDel = false;

	memset(m_buff, 0, sizeof(MSG_HEAD));
}

CLogicMsg::~CLogicMsg()
{
	free_buff();
}

