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
	
	//���attach�ˣ���detach
	virtual ~CShmWrapper();

	/*
	* shmget + attach
	* return SHM_EXIST���Ѿ����ڣ� SUCCESS���¹����ڴ棩 ERROR������
	* �Ѿ����ڵ�shm������get_shm_size��ȡʵ�ʵĴ�С
	*/
	int get(key_t tKey,size_t iSize,int iMode = 0666);
	
	//����size
	inline size_t get_shm_size()
	{
		return m_iShmSize;
	}
	//����id�� -1��ʾû��shmget��
	inline int get_shm_id()
	{
		return m_iShmId;
	}

	//����ϵͳ��shmctl RMID�������Ȼ��attach�еĽ��̣�ʵ���ǻ����Է��ʸ�id�ġ�
	//��ȥgetshm��ͬ��key��õ���ͬidŶ
	static int remove_id(int iShmId);

	static int remove(key_t shmKey, int iMode = 0644);
	
	//����attach�����ڴ�
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
	char m_errmsg[256];		//������Ϣ
};

#endif


