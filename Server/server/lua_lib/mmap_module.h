#ifndef __MMAP_MODULE_H__
#define __MMAP_MODULE_H__

#include <sys/mman.h>
#include <stdint.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

struct mmap_struct
{
	void *mem;
	int fd;
	int isnew;
};

int open_mmap(const char* file, size_t size, struct mmap_struct *ret)
{
	if (ret == NULL)
		return -1;

	int fileopenmode;
	fileopenmode = O_RDWR | O_CREAT;

	int fd = open(file, fileopenmode, 0666);
	if(fd < 0)
	{
		return -1;
	}

	struct stat stStat;
	if(fstat(fd, &stStat)!=0)
	{
		close(fd);
		return -1;
	}

	if(stStat.st_size == size)
	{
		ret->isnew = 0;
	}
	else
	{
		if(ftruncate(fd, (int32_t)size)!=0)
		{
			close(fd);
			return -1;
		}
		ret->isnew = 1;
	}
	ret->fd = fd;

	void *mem = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
	if(MAP_FAILED == (void *)mem)
	{
		close(fd);
		return -1;
	}
	ret->mem = mem;
	return 0;
}

int close_mmap(void *mem, size_t size, int fd)
{
	if(mem)
	{
		munmap(mem, size);
	}
	if(fd >= 0)
	{
		close(fd);
	}	
	return 0;
}

#endif // __MMAP_MODULE_H__
