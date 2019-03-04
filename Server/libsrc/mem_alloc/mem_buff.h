#ifndef __MEM_BUFF_H__
#define __MEM_BUFF_H__

#include "mem_alloc.h"

class CMemBuff
{
public:
	//buff�������ڴ棬��ѭ��ʹ��
	CMemBuff(unsigned int size, CMemAlloc* palloc);

	CMemBuff();

	~CMemBuff();

	void init(unsigned int size, CMemAlloc* palloc);

	//�ı�size��������copy��size����С��m_len ���� -1 fail
	//Ĭ��size=0���ֵ�ǰ��size
	//return 0 ok�����ݴ�buffͷ����ʼ
	int resize(unsigned int size=0);

	//��resize���ƣ��ɱ�������������limitΪֹ������������ʱ����-1
	//return 0 ok
	int doubleExt(unsigned int limit);
	
	//���ݿ�ʼ��ַ
	inline char* data()
	{
		return m_data;
	}
	//���ݳ���
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

	//���ݿ�ʼλ�ú�Ųlen���ֽ�
	//����ʵ���ƶ��ĳ���
	unsigned int mv_head(unsigned int len);

	//���ݽ���λ�ú�Ųlen���ֽ�
	//����ʵ���ƶ��ĳ���
	unsigned int mv_tail(unsigned int len);
	
	//copy���ݵ�dst��len�����������ߵ��ֽ���
	//read֮��data��Ųʵ��copy�ֽ���
	//return=ʵ��copy���ֽ���
	unsigned int read(char* dst, unsigned int len);

	//��srcд�룬len���������ֽ���
	//return=ʵ��д���ֽ���
	unsigned int write(const char* src, unsigned int len);

	//�������
	void clear();

	//�ͷ��ڴ棬֮����Ҫ���³�ʼ��������
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

