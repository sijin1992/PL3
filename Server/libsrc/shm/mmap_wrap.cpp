#include "mmap_wrap.h"
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <stdio.h>

CMmapWrap::CMmapWrap()
{
	m_fd = -1;
	m_errmsg[0] = 0;
	m_size = 0;
	m_mem = NULL;
}


int CMmapWrap::map(const char* filepath, size_t filesize, int& isnew, int proc, int flag)
{
	if(filepath == NULL || filesize==0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "param error");
		return -1;
	}

	int fileopenmode = 0;
	if(proc & PROT_READ)
	{
		if(proc & PROT_WRITE)
		{
			fileopenmode = O_RDWR;
		}
		else
		{
			fileopenmode = O_RDONLY;
		}
	}
	else
	{
		if(proc & PROT_WRITE)
		{
			fileopenmode = O_WRONLY;
		}
	}

	fileopenmode |= O_CREAT;

	m_fd = open(filepath, fileopenmode, 0666);
	if(m_fd < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "open(%s) error %d, %s", filepath, errno, strerror(errno));
		return -1;
	}

	struct stat stStat;
	if(fstat(m_fd, &stStat)!=0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "fstat error %d, %s", errno, strerror(errno));
		return -1;
	}

	if(stStat.st_size == filesize)
	{
		isnew = 0;
	}
	else
	{
		if(ftruncate(m_fd, filesize)!=0)
		{
			snprintf(m_errmsg, sizeof(m_errmsg), "ftruncate error %d, %s", errno, strerror(errno));
			return -1;
		}
		isnew = 1;
	}

	m_mem = (char*)mmap(NULL, filesize, proc, flag, m_fd, 0);
	if(MAP_FAILED == (void *)m_mem)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "mmap(size=%lu) error %d, %s", filesize, errno, strerror(errno));
		return -1;
	}

	m_size = filesize;

	return 0;
}

int CMmapWrap::unmap()
{
	if(m_mem)
	{
		munmap(m_mem, m_size);
		m_mem=NULL;
		m_size=0;
	}
	
	if(m_fd>=0)
	{
		close(m_fd);
		m_fd=-1;
	}
	
	return 0;
}

CMmapWrap::~CMmapWrap()
{
	unmap();
}


