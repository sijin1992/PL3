#ifndef __LOCK_SEM_H__
#define __LOCK_SEM_H__

#include "lock.h"
class CLockSem:public CLock
{
public:
    CLockSem();
	~CLockSem();

	//timeout，如果信号量锁时间超过timeout秒就重用
	int init(int key, int timeout=100);


	//模版方法，提供阻塞mutex操作
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

