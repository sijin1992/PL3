#include "../mem_alloc.h"
#include "../mem_buff.h"
#include "../trace_new.h"
#include <iostream>
#include <string.h>
using namespace std;

int main(int argc, char** argv)
{
	if(false)
	{
		CMemAlloc alloc;
		alloc.debug(cout);

		unsigned int size[] = {
		1000,
		2000,
		4000,
		8000,
		16000,
		50000,
		1000000
		};

		for(unsigned int i=0; i< sizeof(size)/sizeof(size[0]); ++i)
		{
			cout << "================size(" << size[i] << ")==================" << endl;
			CMemAlloc::MEM_NODE* node = alloc.alloc(size[i]);
			alloc.debug(cout);
			alloc.free(node);
			alloc.debug(cout);
		}

		cout << "free all" << endl;
		alloc.free_cache();
		alloc.debug(cout);

		CMemAlloc allocLimit(1,1,2);
		
		CMemAlloc::MEM_NODE* node1 = allocLimit.alloc(1);
		CMemAlloc::MEM_NODE* node2 = allocLimit.alloc(2);
		CMemAlloc::MEM_NODE* node3 = allocLimit.alloc(3);
		allocLimit.free(node1);
		allocLimit.free(node2);
		allocLimit.free(node3);
		allocLimit.debug(cout);
    }

	if(false)
    	{
    		CMemAlloc alloc;
    		CMemBuff buff(1000, &alloc);
    		char str[1024] = {0};
    		int len = buff.write(str, 100);
    		cout << "write " << len << endl;
    		buff.debug(cout);
    		len = buff.write(str, 100);
    		cout << "write " << len << endl;
    		buff.debug(cout);
    		len = buff.read(str, 50);
    		cout << "read " << len << endl;
    		buff.debug(cout);
    		len = buff.read(str, 200);
    		cout << "read " << len << endl;
    		buff.debug(cout);
    		len = buff.write(str, 1024);
    		cout << "write " << len << endl;
    		buff.debug(cout);

    		len = buff.resize(700);
    		cout << "resize 700 = " << len << endl;
    		len = buff.resize( 1000);
    		cout << "resize 1000 = " << len << endl;
    		buff.debug(cout);

      		len = buff.read(str, 300);
    		cout << "read " << len << endl;
    		buff.debug(cout);

      		len = buff.write(str, 300);
    		cout << "write " << len << endl;
    		buff.debug(cout);

    		len = buff.resize(2000);
    		cout << "resize 2000 = " << len << endl;
    		buff.debug(cout);

    		len = buff.mv_head(1000);
     		cout << "mv_head 1000 = " << len << endl;
    		buff.debug(cout);

   		len = buff.mv_tail(2000);
     		cout << "mv_head 2000 = " << len << endl;
    		buff.debug(cout);

    	}

    	if(true)
    	{
    		CMemAlloc alloc;
    		CMemBuff buff(1000, &alloc);
    		buff.debug(cout);

    		cout << "double=" << buff.doubleExt(3000) << endl;
    		buff.debug(cout);
    		
     		cout << "double=" << buff.doubleExt(3000) << endl;
    		buff.debug(cout);

    		buff.destroy();

    		cout << "resize=" << buff.resize(100) << endl;

    		buff.init(100,&alloc);
		cout << "init(100) left=" << buff.left() << endl;
		buff.debug(cout);
   	}
	CTraceNew::Instance()->show(cout);
	return 0;
}

