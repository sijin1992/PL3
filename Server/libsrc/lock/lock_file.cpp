
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <errno.h>

#include <stdio.h>

#include "lock_file.h"


CLockFile::CLockFile(void)
{
	m_fd = -1;
	m_errmsg[0] = 0;
}

CLockFile::~CLockFile(void)
{
	if (m_fd >= 0)
	{
		close(m_fd);
		m_fd = -1;
	}
}

int CLockFile::init(const char *filename)
{
	m_fd = open(filename, O_RDWR|O_CREAT, 0644);
	if ( m_fd < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "open %d %s", errno, strerror(errno));
		return -1;
	}

	return 0;
}

int CLockFile::lock_file(int lockType, int offset, int size, bool block )
{
	if(m_fd < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "not inited");
		return -1;
	}
	
	int ret = 0;
	struct flock lstFlock;
	memset(&lstFlock, 0, sizeof(lstFlock));

	if (FILE_LOCK_READ == lockType)
	{
		lstFlock.l_type = F_RDLCK;
	}
	else
	{
		lstFlock.l_type = F_WRLCK;
	}

	lstFlock.l_whence = SEEK_SET;
	lstFlock.l_start = offset;
	lstFlock.l_len = size;

	if (block)
	{
	    while (true)
	    {
	        ret = fcntl (m_fd, F_SETLKW, &lstFlock);
	        if (ret != 0)
	        {
	            if (errno == EINTR)
	            {
	                continue;
	            }
	            else
	            {
					snprintf(m_errmsg, sizeof(m_errmsg), "fcntl %d %s", errno, strerror(errno));
	                break;
	            }
	        }
	        else
	        {
	            break;
	        }
	    }
	}
	else
	{
		ret = fcntl (m_fd, F_SETLK, &lstFlock);
	}

	if(ret != 0)
		return -1;
		
	return 0;
}

int CLockFile::unlock_file(int offset, int size)
{
	if(m_fd < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "not inited");
		return -1;
	}
	
	int ret = 0;
	struct flock lstFlock;
	memset (&lstFlock, 0, sizeof(lstFlock));

	lstFlock.l_type = F_UNLCK;
	lstFlock.l_whence = SEEK_SET;
	lstFlock.l_start = offset;
	lstFlock.l_len = size;

    while (true)
    {
        ret = fcntl (m_fd, F_SETLKW, &lstFlock);
        if (ret != 0)
        {
            if (errno == EINTR)
            {
                continue;
            }
            else
            {
				snprintf(m_errmsg, sizeof(m_errmsg), "fcntl %d %s", errno, strerror(errno));
                break;
            }
        }
        else
        {
            break;
        }
    }
    
    if ( ret != 0)
    {
        return -1;
    }

	return 0;
}
