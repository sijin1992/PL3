#ifndef __MEM_ALLOC_H__
#define __MEM_ALLOC_H__

#include <iostream>

using namespace std;

#define MEM_ALLOC_ALIGN(size, boundary) (((size) + ((boundary) - 1)) & ~((boundary) - 1))

#define MEM_ALLOC_ALIGN_DEFAULT(size) MEM_ALLOC_ALIGN(size, 8)
/*
*�ο�apr alloctor
*/
class CMemAlloc
{
public:
	struct MEM_NODE {   
		MEM_NODE *next;            /**< next memnode */    
		unsigned int index;           /**< Ҫ�����Ǹ�index�� */    
		char          *first_avail;        
		unsigned int  size;           
		void debug(ostream& os)
		{
			os << "MEM_NODE{" << endl;
			os << "next:" << (size_t)next << "|index:" << index << "|first_avail:" << (size_t)first_avail << "|size:" << (unsigned int)size << endl;
			os << "} end MEM_NODE" << endl;
		}
	};

	
public:
	static const unsigned int ALLOC_STEP = 4; //�����Ŀ��Сin KB
	static const unsigned int MAX_INDEX = 20;   //�����Ĵ���
	static const unsigned int CACHE_LIMIT = 40960; //��໺������ڴ�, in KB
	static const unsigned int MEM_NODE_SIZE = MEM_ALLOC_ALIGN_DEFAULT(sizeof(MEM_NODE));
	static const unsigned int ALLOC_UNIT = 1024; // 1K
	
protected:
	/*��Ӧstatic��ֵ�ı���*/
	unsigned int m_alloc_step;
	unsigned int m_max_index;
	unsigned int m_cache_limit;
	/*Ŀǰ�����˶���*/
	unsigned int m_current_cache;
	
	/*
	* �����С��m_max_index;
	* ����Ԫ����MEM_NODE*����Ӧ��
	* slot  0: size m_min_alloc     
	* slot  2: size m_min_alloc + m_alloc_step   
	* slot  3: size m_min_alloc + 2*m_alloc_step
	* ...     
	* slot m_max_index-1: size m_min_alloc + (m_max_index-1)*m_alloc_step    
	*/
	MEM_NODE** m_free_slots; 

public:
	CMemAlloc();
	~CMemAlloc();
	CMemAlloc(unsigned int alloc_step, unsigned int max_index, unsigned int cache_limit);

	//������ʴ�С�Ľڵ�, mem_size=��Ҫ���ֽ���
	//���ط�NULL, MEM_NODE::first_avail ��ʾ���õĵ�ַ
	MEM_NODE* alloc(unsigned int mem_size /*in byte*/);

	//�ͷ�һ��node
	void free(MEM_NODE* node);

	/*
	* �ͷ����е�cache
	*/
	void free_cache();

	//debug
	void debug(ostream& out);
	
};

#endif

