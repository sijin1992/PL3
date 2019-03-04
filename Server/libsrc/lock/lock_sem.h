#ifndef __LOCK_SEM_H__
#define __LOCK_SEM_H__

#include "lock.h"
class CLockSem:public CLock
{
public:
    CLockSem();
	~CLockSem();

	//timeout������ź�����ʱ�䳬��timeout�������
	int init(int key, int timeout=100);


	//ģ�淽�����ṩ����mutex����
	inline void lock()
	{
		lock_sem();
	}
	
	inline void unlock()
	{
		unlock_sem();
	}


	int lock_sem();
	int unlock_sem();
	int get_sem();

	inline const char* errmsg()
	{
	    return m_errmsg;
	}

private:
	int m_semKey;
	int m_semID;
	char m_errmsg[256];
};
#endif

