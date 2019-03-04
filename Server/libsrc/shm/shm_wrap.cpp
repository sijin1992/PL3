#include <errno.h>
#include <stdio.h>
#include <string.h>
#include "shm_wrap.h"

CShmWrapper::CShmWrapper():m_tShmKey(0), m_iShmSize(0), m_iShmId(-1), m_pvMem(NULL)
{
	m_errmsg[0] = 0;
}

CShmWrapper::~CShmWrapper()
{
	//detach
	if(m_pvMem)
		shmdt(m_pvMem);
	m_pvMem = NULL;
}


//iSize当shm已经存在时，m_iShmSize是实际大小
int CShmWrapper::get(key_t tKey, size_t iSize, int iMode)
{
	m_tShmKey = tKey;
	m_iShmSize = iSize;
	int ret = 0;
	bool bexist = false;

    //create share mem
	if ((m_iShmId = shmget(m_tShmKey, m_iShmSize, IPC_CREAT| IPC_EXCL | iMode)) < 0) //try to create
	{
		if (errno!= EEXIST)
		{
			snprintf(m_errmsg, sizeof(m_errmsg), "shmget(IPC_CREAT|IPC_EXCL, key=0x%x, size=%ld) %d(%s)", m_tShmKey, m_iShmSize, errno, strerror(errno));
			return ERROR;
		}
	        //exist,get
		if ((m_iShmId = shmget(m_tShmKey, 0, iMode)) < 0)
		{
			snprintf(m_errmsg, sizeof(m_errmsg), "shmget(key=0x%x, size=%ld) %d(%s)", m_tShmKey, m_iShmSize, errno, strerror(errno));
			return ERROR;
		}

		struct shmid_ds stDs;
		ret = shmctl(m_iShmId,IPC_STAT,&stDs);
		if(ret != 0)
		{
			snprintf(m_errmsg, sizeof(m_errmsg), "shmctl(IPC_STAT, key=0x%x, size=%ld) %d(%s)", m_tShmKey, m_iShmSize, errno, strerror(errno));
			return ERROR;
		}
		
		m_iShmSize = stDs.shm_segsz;
		bexist = true; 
	}

	if ((m_pvMem = shmat(m_iShmId, NULL, 0)) == (void *)-1)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "shmat(%d) %d(%s)", m_iShmId, errno, strerror(errno));
		return ERROR;	
	}

	if(bexist)
		return SHM_EXIST;
	else
		return SUCCESS;
}

int CShmWrapper::remove_id(int iShmID)
{
	if (shmctl(iShmID, IPC_RMID, NULL) < 0)
	{
		//snprintf(m_errmsg, sizeof(m_errmsg), "shmctl(IPC_RMID) %d(%s)",  errno, strerror(errno));
		return ERROR;
	}
	else
		return SUCCESS;
}

int CShmWrapper::remove(key_t shmKey, int iMode)
{
	int shmID = shmget(shmKey, 0, iMode);
	if(shmID < 0)
	{
		if(errno != ENOENT)
		{
			//snprintf(m_errmsg, sizeof(m_errmsg), "shmget() %d(%s)", errno, strerror(errno));
			return ERROR;
		}
		else
		{
			return SUCCESS;
		}
	}

	return remove_id(shmID);
}


void CShmWrapper::debug(ostream& os)
{
	os << "CShmWrapper{" << endl;
	os << "m_tShmKey|" << m_tShmKey << endl;
	os << "m_iShmSize|" << m_iShmSize << endl;
	os << "m_iShmId|" << m_iShmId << endl;
	os << "m_pvMem|" << (size_t)m_pvMem << endl;
	os << "} end CShmWrapper" << endl;
}

