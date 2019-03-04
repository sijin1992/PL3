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

	//���ļ���ʼ�� 0=ok, -1=fail
	int init(const char * filename);
	//���ֳɵ�fd
	inline void init(int fd)
	{
		m_fd = fd;
	}

	//ģ�淽�����ṩ����mutex����
	inline void lock()
	{
		lock_file(FILE_LOCK_WRITE, 0, 1);
	}
	
	inline void unlock()
	{
		unlock_file(0, 1);
	}


	//lockType ������FILE_LOCK_READ or FILE_LOCK_WRITE
	//0=ok -1=fail block�Ƿ�������Ĭ��true. offset �� size �㶮��
	int lock_file(int lockType, int offset, int size, bool block = true);

    //return 0-�ɹ� ����-ʧ��
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

