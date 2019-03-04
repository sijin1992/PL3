#ifndef _SHM_WRAPPER_H_
#define _SHM_WRAPPER_H_

#include <sys/ipc.h>
#include <sys/shm.h>
#include <iostream>
using namespace std;

class CShmWrapper
{
public:
    const static int SHM_EXIST = 1;
    const static int SUCCESS = 0;
    const static int ERROR = -1;


public:
	CShmWrapper();
	
	//如果attach了，会detach
	virtual ~CShmWrapper();

	/*
	* shmget + attach
	* return SHM_EXIST（已经存在） SUCCESS（新共享内存） ERROR出错了
	* 已经存在的shm，调用get_shm_size获取实际的大小
	*/
	int get(key_t tKey,size_t iSize,int iMode = 0666);
	
	//返回size
	inline size_t get_shm_size()
	{
		return m_iShmSize;
	}
	//返回id， -1表示没有shmget过
	inline int get_shm_id()
	{
		return m_iShmId;
	}

	//调用系统的shmctl RMID，如果仍然有attach中的进程，实际是还可以访问该id的。
	//再去getshm相同的key会得到不同id哦
	static int remove_id(int iShmId);

	static int remove(key_t shmKey, int iMode = 0644);
	
	//返回attach过的内存
	inline void *get_mem()
	{
		return m_pvMem;
	}

	inline const char* errmsg()
	{
	return m_errmsg;
	}

	void debug(ostream& os);

protected:
	key_t m_tShmKey;	//share memory key
	size_t m_iShmSize;		//share memory size
	int m_iShmId;		//share memory id
	void* m_pvMem;		//point to share memory
	char m_errmsg[256];		//错误信息
};

#endif


