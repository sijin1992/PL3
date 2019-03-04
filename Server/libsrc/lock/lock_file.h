#ifndef __LOCK_FILE_H__
#define __LOCK_FILE_H__

#include "lock.h"
class CLockFile:public CLock
{
public:
	const static int FILE_LOCK_READ = 1;
	const static int FILE_LOCK_WRITE = 2;

	CLockFile();
	~CLockFile();

	//打开文件初始化 0=ok, -1=fail
	int init(const char * filename);
	//用现成的fd
	inline void init(int fd)
	{
		m_fd = fd;
	}

	//模版方法，提供阻塞mutex操作
	inline void lock()
	{
		lock_file(FILE_LOCK_WRITE, 0, 1);
	}
	
	inline void unlock()
	{
		unlock_file(0, 1);
	}


	//lockType 见定义FILE_LOCK_READ or FILE_LOCK_WRITE
	//0=ok -1=fail block是否阻塞，默认true. offset 和 size 你懂得
	int lock_file(int lockType, int offset, int size, bool block = true);

    //return 0-成功 其他-失败
	int unlock_file(int offset, int size);

	inline const char* errmsg()
	{
		return m_errmsg;
	}

private:
	int m_fd;
	char m_errmsg[256];
};

#endif

