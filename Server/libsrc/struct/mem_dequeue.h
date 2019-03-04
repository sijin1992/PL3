#ifndef __MEM_DEQUEUE_H__
#define __MEM_DEQUEUE_H__

#include <iostream>
#include <string.h>
#include "../lock/lock.h"
#include <stdio.h>

using namespace std;

class CDequeHead
{
public:

	//内存区的长度
	unsigned int               size_of_mem;
	//deque的长度
	unsigned int               size_of_deque;
	//关键内部指针,避免编译器优化
	volatile unsigned int      deque_begin;
	volatile unsigned int      deque_end;
	
	CDequeHead():
	size_of_mem(0),
	size_of_deque(0),
	deque_begin(0),
	deque_end(0)
	{
	}

      ~CDequeHead()
      {
      }

	void debug(ostream& os)
	{
		os << "CDequeHead{" << endl;
		os << "size_of_mem|" << size_of_mem << endl;
		os << "size_of_deque|" << size_of_deque << endl;
		os << "deque_begin|" << deque_begin << endl;
		os << "deque_end|" << deque_end << endl;
		os << "} end CDequeHead" << endl;
	}
};


class CDeque
{
	
public:
	#define CDEQUE_MAGIC  "D!E@Q#U$E%0"
	//判断是非为满的间隔
	static const unsigned int JUDGE_FULL_INTERVAL = 8;
	static const int ERR_NOT_INITED = -1;
	static const int ERR_DEQUE_MIN_SIZE = -2;
	static const int ERR_MEM_NOT_ENOUGH = -3;
	static const int ERR_MEM_NOT_VALID = -4;
	static const int ERR_DEQUE_FULL = -5;
	static const int ERR_DEQUE_EMPTY = -6;
	static const int ERR_DIRTY_DATA = -7;
	static const int ERR_LARGE_DATA = -8; //数据比目标缓存大

public:
	struct BLOCK_HEAD
	{
		char magic[32];
		unsigned int size;
		BLOCK_HEAD(unsigned int s)
		{
			snprintf(magic, sizeof(magic), "%s", CDEQUE_MAGIC);
			size = s;
		}

		int is_valid()
		{
			if(strncmp(magic, CDEQUE_MAGIC, sizeof(magic)-1)==0)
			{
				return 1;
			}

			return 0;
		}
	};
	
protected:
       //头指针
	CDequeHead* m_phead;
	//数据区的头指针,方便计算
	char* m_pdata;
	//这个锁是用来锁操作的
	CLock*  m_plock;
	bool m_inited;

protected:

	//这些操作都是一些快照操作,不加锁进行
	//得到两个关键指针的快照
	//这个操作基于一点,32位操作系统中的32位整数操作是原子操作
	void snap_getpoint(unsigned int &pstart,unsigned int &pend)
	{
		pstart = m_phead->deque_begin;
		pend = m_phead->deque_end;
	}
	//锁定
	inline void deque_lock()
	{
		if(m_plock)
		 	m_plock->lock();
	}
	//解锁
	inline void deque_unlock()
	{
		if(m_plock)
			m_plock->unlock();
	}

	//循环写
	void deque_write(const char* pdata, unsigned int data_len, unsigned int* pend)
	{
		unsigned int end = 0;
		end = *pend;
		
		unsigned int left = m_phead->size_of_deque - end;
		if(left < data_len)
		{
			memcpy(m_pdata+end, pdata, left);
			memcpy(m_pdata, pdata+left, data_len - left);
		}
		else
		{
			memcpy(m_pdata+end, pdata, data_len);
		}

		end = (end+data_len)%m_phead->size_of_deque;
		
		*pend = end;
	}

	//如果pbegin==NULL,表示直接按照m_phead->deque_begin来读
	//否则使用pbegin去读一个包，并返回下一个包位置
	void deque_read(char* pdata, unsigned int data_len, unsigned int *pbegin)
	{
		unsigned int begin = 0;
		begin = *pbegin;
		
		unsigned int left = m_phead->size_of_deque - begin;
		if(left < data_len)
		{
			memcpy(pdata, m_pdata+begin, left);
			memcpy(pdata+left, m_pdata, data_len - left);
		}
		else
		{
			memcpy(pdata, m_pdata+begin, data_len);
		}

		begin = (begin+data_len)%m_phead->size_of_deque;

		*pbegin = begin;
	}

public:
	void debug(ostream& os, bool beshort = false)
	{
		m_phead->debug(os);
		os << "used=" << usedsize() << endl;
		os << "free=" << freesize() << endl;
		if(!beshort)
		{
			for(unsigned int i=0; i<usedsize(); ++i)
			{
				cout << int(m_pdata[(m_phead->deque_begin+i)%m_phead->size_of_deque]) << " ";
			}
		}
		cout << endl;
	}
	
	//
	CDeque():m_phead(NULL), m_pdata(NULL), m_plock(NULL), m_inited(false)
	{}

	CDeque(CLock* plock):m_phead(NULL), m_pdata(NULL), m_plock(plock), m_inited(false)
	{}

	~CDeque() {}

	inline void set_lock(CLock* plock)
	{
		m_plock = plock;
	}
	
	static unsigned int getallocsize(const unsigned int dequeSize)
	{
		return  sizeof(CDequeHead) + dequeSize + JUDGE_FULL_INTERVAL ;
	}
	
	//根据参数初始化
	//brestore = true重用数据，=false重新格式化
	// 0=ok <0 fail
	int initialize(char *pmem, unsigned int memSize, unsigned int dequeSize, bool brestore = false)
	{
		if(m_inited)
		{
			return 0;
		}

		unsigned int needMemSize = getallocsize(dequeSize);
		
		//必须大于间隔长度
		if(dequeSize < JUDGE_FULL_INTERVAL)
		{
			return ERR_DEQUE_MIN_SIZE;
		}
		
		if (memSize <  needMemSize)
		{
			return ERR_MEM_NOT_ENOUGH;
		}

		//
		CDequeHead *phead = reinterpret_cast<CDequeHead *>(pmem);

		if (brestore == true)
		{
			//坚持关键数据是否一致
			if(phead->size_of_mem != needMemSize 
				|| phead->size_of_deque != dequeSize + JUDGE_FULL_INTERVAL
				|| phead->deque_begin >= phead->size_of_deque
				|| phead->deque_end >= phead->size_of_deque
			)
			{
				return ERR_MEM_NOT_VALID;
			}
		}
		else
		{
			phead->size_of_mem = needMemSize;
			phead->size_of_deque = dequeSize + JUDGE_FULL_INTERVAL;
			phead->deque_begin = 0;
			phead->deque_end = 0;
		}

		m_phead = phead;
		m_pdata = pmem + sizeof(CDequeHead);
		m_inited = true;

		return 0;
	}

	//push_back操作
	//return 0=ok <0错误
	int push(const char *pdata, unsigned int data_size)
	{
		if(!m_inited)
		{
			return ERR_NOT_INITED;
		}

		//不允许空写
		if(data_size == 0 || pdata==NULL)
		{
			return ERR_DIRTY_DATA;
		}
		
		//加锁
		deque_lock();

		//需要data_size先写入，再写入data
		BLOCK_HEAD blockHead(data_size);
		unsigned int need_size = data_size + sizeof(blockHead);
	    
		//检查队列的空间是否够用
		if(freesize() < need_size )
		{
			deque_unlock();
			return ERR_DEQUE_FULL;
		}

		//为了单进程读，单进程写可以不锁，那么m_phead->deque_end只能一次性改变
		unsigned int saveEnd = m_phead->deque_end;
		deque_write((const char*)&blockHead, sizeof(blockHead),&saveEnd);
		deque_write(pdata, data_size,  &saveEnd);
		m_phead->deque_end = saveEnd;

		deque_unlock();
		return 0;
	}

	//pop操作,data_size!=0 pdata是外部分配的buff，否则内部new一个buff返回
	//ppop_size返回实际的大小
	//psavebegin == NULL, 直接取了，否则复制数据，下一个头保存在psavebegin中
	//discard不应该放这里但是大多数代码重复，所以委屈了，为true时不做copy，但ppop_size仍然返回
	//return 0=ok, <0错误
	int pop_core(char *&pdata, unsigned int data_size, unsigned int * ppop_size, unsigned int *psavebegin, bool discard = false)
	{
		if(!m_inited)
		{
			return ERR_NOT_INITED;
		}
		//加锁
		deque_lock();

		//考虑单进程读同时单进程写，那么used_size只会同时变大不会小，这样的情况不加锁没问题
		unsigned int localSaveBegin = 0;
		unsigned int * pthebegin = NULL;
		bool bMoveHead = true;
		if(psavebegin == NULL)
		{
			pthebegin = &localSaveBegin;
		}
		else
		{
			pthebegin = psavebegin;
			bMoveHead = false;
		}
		
		*pthebegin = m_phead->deque_begin; //先读head
		
		BLOCK_HEAD blockHead(0);
		unsigned int used_size = usedsize();
		if(used_size == 0)
		{
			deque_unlock();
			return ERR_DEQUE_EMPTY;
		}
		else if(used_size <= sizeof(blockHead))
		{
			deque_unlock();
			return ERR_DIRTY_DATA;
		}
		else
		{
			//head可读，但是body不一定，所以不改变实际的begin，使用savebegin
			deque_read((char*)&blockHead, sizeof(blockHead), pthebegin);

			//校验是否有效
			if(blockHead.is_valid())
			{
			}
			else
			{
				deque_unlock();
				return ERR_DIRTY_DATA;
			}
			
			if(used_size-sizeof(blockHead) < blockHead.size)
			{
				deque_unlock();
				return ERR_DIRTY_DATA;
			}

			if(discard)
			{
				m_phead->deque_begin = (*pthebegin + blockHead.size)%m_phead->size_of_deque;
			}
			else
			{
				if(data_size > 0)
				{
					if(blockHead.size > data_size)
					{
						//悲剧
						deque_unlock();
						return ERR_LARGE_DATA;
					}
				}
				else
				{
					pdata = new char[blockHead.size];
					if(pdata == NULL)
					{
						deque_unlock();
						return ERR_LARGE_DATA;
					}
				}
				//读data
				deque_read(pdata, blockHead.size, pthebegin);
				//清理data
				if(bMoveHead)
					m_phead->deque_begin = *pthebegin;
			}	
			
			*ppop_size = blockHead.size;
			deque_unlock();
			return 0;
		}
	}

	//数据copy到pdata中，并从队列中删除
	int pop(char *pdata, unsigned int data_size, unsigned int * ppop_size)
	{
		return pop_core(pdata, data_size, ppop_size, NULL);
	}

	//内存是new出来的，调用者要delete[]
	int pop(char *&pdata, unsigned int * ppop_size)
	{
		return pop_core(pdata, 0, ppop_size, NULL);
	}

	//数据copy到pdata中，但没有删除
	//begin!=NULL时，能返回下个block的开始偏移
	int peer(char *pdata, unsigned int data_size, unsigned int * ppop_size, unsigned int * pbegin = NULL)
	{
		unsigned int savebegin;
		unsigned int *p;
		if(pbegin)
		{
			p = pbegin;
		}
		else
		{
			p = &savebegin;
		}
		return pop_core(pdata, data_size, ppop_size, p);
	}

	//危险的接口，最好不用!!!
	//begin必须为peer成功时返回的pbegin，并且是单进程读的时候用，否则有并发问题
	void remove(unsigned int begin)
	{
		deque_lock();
		if(begin < m_phead->size_of_deque)
		{
			//只能做简单的检查
			m_phead->deque_begin = begin;
		}
		deque_unlock();
	}

	int remove(unsigned int *premovedLen = NULL)
	{
		unsigned int ignoreLen;
		char* ignore;
		if(premovedLen == NULL)
			premovedLen = &ignoreLen;
		
		return pop_core(ignore, 0, premovedLen, NULL, true);
	}

	//当出错的时候，你需要clear
	int clear()
	{
		if(!m_inited)
		{
			return ERR_NOT_INITED;
		}
		//加锁
		deque_lock();

		m_phead->deque_begin = 0;
		m_phead->deque_end = 0;
		
		deque_unlock();

		return 0;
	}

	//read 和write是不分包的，把dequeue当流来用。不能和pop，push混用!!!
	int read(char *buff, unsigned int buffsize)
	{
		unsigned int copysize = usedsize();
		if(copysize > buffsize)
		{
			copysize = buffsize;
		}


		unsigned int theBegin = m_phead->deque_begin;
		deque_read(buff, copysize, &theBegin);
		m_phead->deque_begin = theBegin;

		return copysize;
	}

	int write(const char *buff, unsigned int buffsize)
	{
		unsigned int copysize = freesize();
		if(copysize > buffsize)
		{
			copysize = buffsize;
		}

		unsigned int theEnd = m_phead->deque_end;
		deque_write(buff, copysize, &theEnd);
		m_phead->deque_end = theEnd;

		return copysize;
	}


	//得到FREE空间的快照
	unsigned int freesize()
	{
		//取快照
		unsigned int pstart,pend,szfree;
		snap_getpoint(pstart, pend);

		//计算尺寸
		if(pstart == pend )
		{
		    szfree = m_phead->size_of_deque;
		}
		else if(pstart < pend)
		{
		    szfree = m_phead->size_of_deque - (pend - pstart) ;
		}
		else 
		{
		    szfree = pstart -pend ;
		}

		//重要：FREE长度应该减去预留部分长度，保证首尾不会相接
		szfree -= JUDGE_FULL_INTERVAL;
		return szfree;
	}

	inline unsigned int usedsize()
	{
		return m_phead->size_of_deque - freesize() - JUDGE_FULL_INTERVAL;
	}

	//得到是否满的快照
	bool empty()
	{
		return freesize() == m_phead->size_of_deque - JUDGE_FULL_INTERVAL;
	}

	//得到是否空的快照
	bool full()
	{
		return freesize() == 0;
	}
};

#endif

