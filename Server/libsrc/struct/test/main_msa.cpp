#define DEBUG
#include "../mutilsize_allocator.h"
#include "../../shm/shm_wrap.h"
#include <iostream>
#include <string.h>
using namespace std;

class CMyVisitor: public CFixedsizeAllocator::CNodeVisitor
{
	public:
		CMyVisitor():count(0),po(&cout) {}
		virtual int visit(void* p, MEMSIZE offset, unsigned int size) 
		{
			++count;
			(*po) << "visit offset(" << offset << ")" << endl;
			return RET_CONTINUE;
		}

		void set_output(ostream *p)
		{
			po = p;
		}
		
		int count;
		ostream* po;
};

int main(int argc, char** argv)
{
	unsigned int size = 300;
	unsigned int blocksize = 100;
#if 0
	char* mem = new char[size];
#else
	CShmWrapper shm;
	int ret = shm.get(0x1002, size);
	if(ret == CShmWrapper::ERROR)
	{
		cout << "init" << shm.errmsg() << endl;
		return 0;
	}
	
	char* mem = (char*)(shm.get_mem());
	if(size != shm.get_shm_size())
	{
		cout << "size not right" << endl;
		return 0;
	}
#endif

	CMutilsizeAllocator msa;

cout << "init------------------------------------------" << endl;
	if(ret == CShmWrapper::SHM_EXIST)
	{
		cout << "use exitst shm" << endl;
		ret = msa.bind(mem, size, blocksize, false);
	}
	else
	{
		cout << "use new shm" << endl;
		ret = msa.bind(mem, size, blocksize, true);
	}

	if(ret != 0)
	{
		cout << "init " << msa.errmsg() << endl;
		return 0;
	}

	msa.debug(cout);

cout << "alloc------------------------------------------" << endl;

	char* savePointer[5] = {0};
	for(int i=0; i<5; ++i)
	{
		void* p = NULL;
		ret = msa.alloc(p, 10);
		if(ret != 0)
		{
			cout << "at[" << i << "]" << " alloc " << msa.errmsg() << endl;
			break;
		}

		cout << "at[" << i << "]" << " alloced at " << (unsigned long)p << endl;

		savePointer[i] = (char*)p;
	}
	msa.debug(cout);

cout << "free------------------------------------------" << endl;
	for(int j =0; j<5; ++j)
	{
		if(savePointer[j] != NULL)
		{
			ret = msa.free(savePointer[j], 10);
			if(ret != 0)
			{
				cout << "at[" << j << "]" << "free " << msa.errmsg() << endl;
				break;
			}
			cout << "at[" << j << "]" << " free at " << (unsigned long)savePointer[j] << endl;
		}
	}
	msa.debug(cout);
	
	return 0;
}

