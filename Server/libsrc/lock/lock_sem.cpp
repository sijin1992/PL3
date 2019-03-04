#include <stdio.h>
#include <sys/sem.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "lock_sem.h"

union semun {
    int val;
    struct semid_ds *buf;
    unsigned short  *array;
};

CLockSem::CLockSem()
{
    m_semKey = -1;
    m_semID = -1;
	m_errmsg[0] = 0;
}

CLockSem::~CLockSem()
{
}

int CLockSem::init(int key, int timeout)
{
    m_semKey = key;
    m_semID = semget(m_semKey, 1, 0666 | IPC_CREAT );
    if (m_semID == -1)
    {
		snprintf(m_errmsg, sizeof(m_errmsg), "semget(%d) %d %s", m_semKey, errno, strerror(errno));
        return -1;
    }

    semun arg;
    semid_ds stSemDs;
    arg.buf = &stSemDs;

    int ret = semctl(m_semID, 0, IPC_STAT, arg);
    if (ret == -1)
    {
		snprintf(m_errmsg, sizeof(m_errmsg), "semctl(%d,IPC_STAT) %d %s", m_semID, errno, strerror(errno));
        return -1;
    }

    if ((stSemDs.sem_otime == 0) || ((stSemDs.sem_otime > 0) && (time(NULL) - stSemDs.sem_otime > timeout)))
    {
        semun arg;
        arg.val = 1;
        ret = semctl(m_semID, 0, SETVAL, arg);
        if (ret == -1)
        {
			snprintf(m_errmsg, sizeof(m_errmsg), "semctl(%d,SETVAL) %d %s", m_semID, errno, strerror(errno));
			return -1;
        }
    }

    return 0;
}

int CLockSem::lock_sem()
{
	if(m_semID < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "not inited");
		return -1;
	}
	
    struct sembuf stSemBuf;
    memset(&stSemBuf, 0x0, sizeof(stSemBuf));

    stSemBuf.sem_num = 0;
    stSemBuf.sem_flg = SEM_UNDO;
    stSemBuf.sem_op = -1;

	    while (true)
	    {
	        int ret = -1;
	        ret = semop(m_semID, &stSemBuf, 1);
	        if (ret != 0)
	        {
	            if (errno== EINTR)
	            {
	                continue;
	            }

				snprintf(m_errmsg, sizeof(m_errmsg), "semop(%d,SEM_UNDO -1) %d %s", m_semID, errno, strerror(errno));
	            return -1;
	        }
	        else
	        {
	            break;
	        }
	    }

    return 0;
}

int CLockSem::unlock_sem()
{
    struct sembuf stSemBuf;
    memset(&stSemBuf, 0x0, sizeof(stSemBuf));

    stSemBuf.sem_num = 0;
    stSemBuf.sem_flg = SEM_UNDO;
    stSemBuf.sem_op = 1;

    while (1)
    {
        int iRetValue = -1;
        iRetValue = semop(m_semID, &stSemBuf, 1);
        if (iRetValue != 0)
        {
            if (errno== EINTR)
            {
                continue;
            }

			snprintf(m_errmsg, sizeof(m_errmsg), "semop(%d,SEM_UNDO 1) %d %s", m_semID, errno, strerror(errno));
            return -1;
        }
        else
        {
            break;
        }
    }

    return 0;
}

int CLockSem::get_sem()
{
    semun arg;
    semid_ds stSemDs;
    arg.buf = &stSemDs;
    int ret = semctl(m_semID, 0, GETVAL, arg);
    if (ret == -1)
    {
		snprintf(m_errmsg, sizeof(m_errmsg), "semctl(%d,GETVAL 1) %d %s", m_semID, errno, strerror(errno));
        return -1;
    }

    return ret;
}

