#include "mem_buff.h"
#include <string.h>


CMemBuff::CMemBuff(unsigned int size, CMemAlloc* palloc )
{
	m_inited = false;
	init(size, palloc);
}

void CMemBuff::init(unsigned int size, CMemAlloc* palloc)
{
	if(m_inited || palloc==NULL)
		return;
		
	m_palloc = palloc;
	m_pnode = m_palloc->alloc(size);
	m_data = m_pnode->first_avail;
	m_len = 0;
	m_inited = true;
}


CMemBuff::CMemBuff()
{
	m_len = 0;
	m_data = NULL;
	m_inited = false;
}

CMemBuff::~CMemBuff()
{
	destroy();
}

int CMemBuff::resize(unsigned int size)
{
	if(!m_inited || (size !=0 && size < m_len) )
	{
		return -1;
	}

	if(size == 0)
	{
		size = m_pnode->size;
	}

	CMemAlloc::MEM_NODE* pnew = m_palloc->alloc(size);
	char* data = pnew->first_avail;
	if(m_len > 0)
		memcpy(data, m_data, m_len);

	m_palloc->free(m_pnode);		
	m_data = data;
	m_pnode = pnew;

	return 0;
}

int CMemBuff::doubleExt(unsigned int limit)
{
	if(!m_inited || m_pnode->size >= limit)
	{
		return -1;
	}

	unsigned int new_size = m_pnode->size*2;
	if(new_size > limit)
		new_size = limit;

	CMemAlloc::MEM_NODE* pnew = m_palloc->alloc(new_size);
	char* data = pnew->first_avail;
	if(m_len > 0)
		memcpy(data, m_data, m_len);

	m_palloc->free(m_pnode);		
	m_data = data;
	m_pnode = pnew;
	return 0;
}

unsigned int CMemBuff::mv_head(unsigned int len)
{
	if(!m_inited )
		return 0;
		
	if(len > m_len)
		len = m_len;

	m_data += len;
	m_len -= len;

	return len;
}

unsigned int CMemBuff::mv_tail(unsigned int len)
{
	if(!m_inited )
		return 0;

	unsigned int left = (m_pnode->first_avail + m_pnode->size) - (m_data + m_len);
	if(len > left)
		len = left;

	m_len += len;

	return len;
}


unsigned int CMemBuff::read(char* dst, unsigned int len)
{
	if(!m_inited )
		return 0;

	if(len > m_len)
		len = m_len;

	if(len)
		memcpy(dst, m_data, len);

	m_data += len;
	m_len -= len;

	return len;
}

unsigned int CMemBuff::write(const char* src, unsigned int len)
{
	if(!m_inited )
		return 0;

	unsigned int left = (m_pnode->first_avail + m_pnode->size) - (m_data + m_len);
	if(len > left)
		len = left;
		
	if(len)
		memcpy(m_data, src, len);

	m_len += len;

	return len;
}

void CMemBuff::debug(ostream& os)
{
	if(!m_inited )
	{
		os << "not inited";
		return;
	}
	
	os << "CMemBuff{" << endl;
	if(m_inited)
	{
		os << "start=" << (size_t)(m_pnode->first_avail) << ",data=" << (size_t)m_data << ",len=" << m_len << endl;
		os << "size=" << m_pnode->size << endl;
	}
	else
	{
		os << "not inited" << endl;
	}
	os << "}" << endl;
}


void CMemBuff::clear()
{
	if(m_inited)
	{
		m_data = m_pnode->first_avail;
		m_len = 0;
	}
}

void CMemBuff::destroy()
{
	if(m_inited)
	{
		m_palloc->free(m_pnode);
		m_inited = false;
	}
}


