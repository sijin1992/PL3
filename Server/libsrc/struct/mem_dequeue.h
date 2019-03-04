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

	//�ڴ����ĳ���
	unsigned int               size_of_mem;
	//deque�ĳ���
	unsigned int               size_of_deque;
	//�ؼ��ڲ�ָ��,����������Ż�
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
	//�ж��Ƿ�Ϊ���ļ��
	static const unsigned int JUDGE_FULL_INTERVAL = 8;
	static const int ERR_NOT_INITED = -1;
	static const int ERR_DEQUE_MIN_SIZE = -2;
	static const int ERR_MEM_NOT_ENOUGH = -3;
	static const int ERR_MEM_NOT_VALID = -4;
	static const int ERR_DEQUE_FULL = -5;
	static const int ERR_DEQUE_EMPTY = -6;
	static const int ERR_DIRTY_DATA = -7;
	static const int ERR_LARGE_DATA = -8; //���ݱ�Ŀ�껺���

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
       //ͷָ��
	CDequeHead* m_phead;
	//��������ͷָ��,�������
	char* m_pdata;
	//�������������������
	CLock*  m_plock;
	bool m_inited;

protected:

	//��Щ��������һЩ���ղ���,����������
	//�õ������ؼ�ָ��Ŀ���
	//�����������һ��,32λ����ϵͳ�е�32λ����������ԭ�Ӳ���
	void snap_getpoint(unsigned int &pstart,unsigned int &pend)
	{
		pstart = m_phead->deque_begin;
		pend = m_phead->deque_end;
	}
	//����
	inline void deque_lock()
	{
		if(m_plock)
		 	m_plock->lock();
	}
	//����
	inline void deque_unlock()
	{
		if(m_plock)
			m_plock->unlock();
	}

	//ѭ��д
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

	//���pbegin==NULL,��ʾֱ�Ӱ���m_phead->deque_begin����
	//����ʹ��pbeginȥ��һ��������������һ����λ��
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
	
	//���ݲ�����ʼ��
	//brestore = true�������ݣ�=false���¸�ʽ��
	// 0=ok <0 fail
	int initialize(char *pmem, unsigned int memSize, unsigned int dequeSize, bool brestore = false)
	{
		if(m_inited)
		{
			return 0;
		}

		unsigned int needMemSize = getallocsize(dequeSize);
		
		//������ڼ������
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
			//��ֹؼ������Ƿ�һ��
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

	//push_back����
	//return 0=ok <0����
	int push(const char *pdata, unsigned int data_size)
	{
		if(!m_inited)
		{
			return ERR_NOT_INITED;
		}

		//�������д
		if(data_size == 0 || pdata==NULL)
		{
			return ERR_DIRTY_DATA;
		}
		
		//����
		deque_lock();

		//��Ҫdata_size��д�룬��д��data
		BLOCK_HEAD blockHead(data_size);
		unsigned int need_size = data_size + sizeof(blockHead);
	    
		//�����еĿռ��Ƿ���
		if(freesize() < need_size )
		{
			deque_unlock();
			return ERR_DEQUE_FULL;
		}

		//Ϊ�˵����̶���������д���Բ�������ôm_phead->deque_endֻ��һ���Ըı�
		unsigned int saveEnd = m_phead->deque_end;
		deque_write((const char*)&blockHead, sizeof(blockHead),&saveEnd);
		deque_write(pdata, data_size,  &saveEnd);
		m_phead->deque_end = saveEnd;

		deque_unlock();
		return 0;
	}

	//pop����,data_size!=0 pdata���ⲿ�����buff�������ڲ�newһ��buff����
	//ppop_size����ʵ�ʵĴ�С
	//psavebegin == NULL, ֱ��ȡ�ˣ����������ݣ���һ��ͷ������psavebegin��
	//discard��Ӧ�÷����ﵫ�Ǵ���������ظ�������ί���ˣ�Ϊtrueʱ����copy����ppop_size��Ȼ����
	//return 0=ok, <0����
	int pop_core(char *&pdata, unsigned int data_size, unsigned int * ppop_size, unsigned int *psavebegin, bool discard = false)
	{
		if(!m_inited)
		{
			return ERR_NOT_INITED;
		}
		//����
		deque_lock();

		//���ǵ����̶�ͬʱ������д����ôused_sizeֻ��ͬʱ��󲻻�С�����������������û����
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
		
		*pthebegin = m_phead->deque_begin; //�ȶ�head
		
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
			//head�ɶ�������body��һ�������Բ��ı�ʵ�ʵ�begin��ʹ��savebegin
			deque_read((char*)&blockHead, sizeof(blockHead), pthebegin);

			//У���Ƿ���Ч
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
						//����
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
				//��data
				deque_read(pdata, blockHead.size, pthebegin);
				//����data
				if(bMoveHead)
					m_phead->deque_begin = *pthebegin;
			}	
			
			*ppop_size = blockHead.size;
			deque_unlock();
			return 0;
		}
	}

	//����copy��pdata�У����Ӷ�����ɾ��
	int pop(char *pdata, unsigned int data_size, unsigned int * ppop_size)
	{
		return pop_core(pdata, data_size, ppop_size, NULL);
	}

	//�ڴ���new�����ģ�������Ҫdelete[]
	int pop(char *&pdata, unsigned int * ppop_size)
	{
		return pop_core(pdata, 0, ppop_size, NULL);
	}

	//����copy��pdata�У���û��ɾ��
	//begin!=NULLʱ���ܷ����¸�block�Ŀ�ʼƫ��
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

	//Σ�յĽӿڣ���ò���!!!
	//begin����Ϊpeer�ɹ�ʱ���ص�pbegin�������ǵ����̶���ʱ���ã������в�������
	void remove(unsigned int begin)
	{
		deque_lock();
		if(begin < m_phead->size_of_deque)
		{
			//ֻ�����򵥵ļ��
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

	//�������ʱ������Ҫclear
	int clear()
	{
		if(!m_inited)
		{
			return ERR_NOT_INITED;
		}
		//����
		deque_lock();

		m_phead->deque_begin = 0;
		m_phead->deque_end = 0;
		
		deque_unlock();

		return 0;
	}

	//read ��write�ǲ��ְ��ģ���dequeue�������á����ܺ�pop��push����!!!
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


	//�õ�FREE�ռ�Ŀ���
	unsigned int freesize()
	{
		//ȡ����
		unsigned int pstart,pend,szfree;
		snap_getpoint(pstart, pend);

		//����ߴ�
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

		//��Ҫ��FREE����Ӧ�ü�ȥԤ�����ֳ��ȣ���֤��β�������
		szfree -= JUDGE_FULL_INTERVAL;
		return szfree;
	}

	inline unsigned int usedsize()
	{
		return m_phead->size_of_deque - freesize() - JUDGE_FULL_INTERVAL;
	}

	//�õ��Ƿ����Ŀ���
	bool empty()
	{
		return freesize() == m_phead->size_of_deque - JUDGE_FULL_INTERVAL;
	}

	//�õ��Ƿ�յĿ���
	bool full()
	{
		return freesize() == 0;
	}
};

#endif

