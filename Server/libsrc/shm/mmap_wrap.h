#ifndef __MMAP_WRAP_H__
#define __MMAP_WRAP_H__

#include <sys/mman.h>
class CMmapWrap
{
public:
	CMmapWrap();
	~CMmapWrap();
	int map(const char* filepath, size_t filesize, int& isnew, int proc=PROT_READ|PROT_WRITE, int flag=MAP_SHARED);
	int unmap();
	inline int get_fd()
	{
		return m_fd;
	}

	inline const char* errmsg()
	{
		return m_errmsg;
	}

	inline char* get_mem()
	{
		return m_mem;
	}

	inline size_t get_size()
	{
		return m_size;
	}

protected:
	int m_fd;
	size_t m_size;
	char* m_mem;
	char m_errmsg[256];
};

#endif
