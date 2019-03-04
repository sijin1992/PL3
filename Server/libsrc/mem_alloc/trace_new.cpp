#include "trace_new.h"

#ifdef new
#undef new
#endif

CTraceNew* CTraceNew::pinstance = NULL;
void* CTraceNew::ptr = NULL;

void CTraceNew::insert(void* paddr,  int unit_size, int line, const char* file)
{
	CInfo info;
	info.paddr = paddr;
	info.unit_size = unit_size;
	info.line = line;
	info.file = file;
	infoMap[paddr] = info;
}

void CTraceNew::remove(void* paddr)
{
	infoMap.erase(paddr);
}

void CTraceNew::show(ostream& output)
{
	map<void*, CInfo>::iterator it;
	for(it = infoMap.begin(); it!=infoMap.end(); ++it)
	{
		output << (it->second);
	}
}
		
CTraceNew* CTraceNew::Instance()
{
	if(!pinstance)
	{
		pinstance = new CTraceNew;
	}
	
	return pinstance;
}
		

CTraceNew::CTraceNew()
{
}

ostream& operator<<(ostream& output, CTraceNew::CInfo& info)
{
	output << "addr=" << hex << (size_t)info.paddr << dec << ", size=" << info.unit_size 
		<< ", file=" << info.file << ", line=" << info.line << endl;
	return output;
}

#ifdef _DEBUG_ 

void * operator new(size_t size, const char *file, int line)
{ 
	void *ptr = (void *)malloc(size); 
	CTraceNew::Instance()->insert(ptr, size, line, file); 
	return ptr; 
}

void operator delete(void *p)
{ 
	CTraceNew::Instance()->remove(p);
	free(p); 
}

void * operator new[](size_t size, const char *file, int line)
{ 
	void *ptr = (void *)malloc(size); 
	CTraceNew::Instance()->insert(ptr, size, line, file); 
	return ptr; 
}

void operator delete[](void *p)
{ 
	CTraceNew::Instance()->remove(p);
	free(p); 
}

#endif


