#ifndef __MEM_BUFF_H__
#define __MEM_BUFF_H__

#include "mem_alloc.h"

class CMemBuff
{
public:
	//buff是连续内存，不循环使用
	CMemBuff(unsigned int size, CMemAlloc* palloc);

	CMemBuff();

	~CMemBuff();

	void init(unsigned int size, CMemAlloc* palloc);

	//改变size，数据做copy，size不能小于m_len 否则 -1 fail
	//默认size=0保持当前的size
	//return 0 ok，数据从buff头部开始
	int resize(unsigned int size=0);

	//跟resize类似，成倍增长，增长到limit为止，不能再增长时返回-1
	//return 0 ok
	int doubleExt(unsigned int limit);
	
	//数据开始地址
	inline char* data()
	{
		return m_data;
	}
	//数据长度
	inline unsigned int len()
	{
		return m_len;
	}

	inline unsigned int left()
	{
		if(m_inited)
			return (m_pnode->first_avail + m_pnode->size) - (m_data + m_len);
		else
			return 0;
	}

	inline bool inited()
	{
		return m_inited;
	}

	//数据开始位置后挪len个字节
	//返回实际移动的长度
	unsigned int mv_head(unsigned int len);

	//数据结束位置后挪len个字节
	//返回实际移动的长度
	unsigned int mv_tail(unsigned int len);
	
	//copy数据到dst，len输入期望读走的字节数
	//read之后data后挪实际copy字节数
	//return=实际copy的字节数
	unsigned int read(char* dst, unsigned int len);

	//从src写入，len是期望的字节数
	//return=实际写入字节数
	unsigned int write(const char* src, unsigned int len);

	//数据清空
	void clear();

	//释放内存，之后需要重新初始化才能用
	void destroy();

	void debug(ostream& os);
	
protected:
	CMemAlloc *m_palloc;
	CMemAlloc::MEM_NODE* m_pnode;
	char* m_data;
	unsigned int m_len;
	bool m_inited;
};

#endif

