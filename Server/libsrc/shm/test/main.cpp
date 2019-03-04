#include "../shm_wrap.h"
#include "../mmap_wrap.h"
#include <iostream>
#include <string.h>
#include <string>
#include <stdlib.h>
#include <time.h>

using namespace std;

int main(int argc, char** argv)
{
	if(argc < 2)
	{
		cout << argv[0] << " [shm|mmap]" << endl;
		return 0;
	}

	string cmd = argv[1];
	if(cmd == "shm")
	{
		CShmWrapper shm;
		cout << "shm.get(0x12340, 100)=" << shm.get(0x12340, 100) << endl;
		shm.debug(cout);
		cout << "shm.get(0x12340, 200)=" << shm.get(0x12340, 200);
		cout << " real size=" << shm.get_shm_size() <<endl;
		shm.debug(cout);
		if(argc > 1)
		{
			cout << "remove()=" << CShmWrapper::remove(shm.get_shm_id()) << endl;
			shm.debug(cout);
		}
	}
	else if(cmd == "mmap")
	{
		if(argc < 5)
		{
			cout << argv[0] << " mmap [0=private,1=shared] [filepath] [filesize]" << endl;
			return 0;
		}

		CMmapWrap obj;
		int isnew = 0;
		int flag;
		if(atoi(argv[2]) != 0)
		{
			flag = MAP_SHARED;
		}
		else
		{
			flag = MAP_PRIVATE;
		}
		
		if(obj.map(argv[3], atoi(argv[4]), isnew, PROT_READ | PROT_WRITE, flag)!=0)
		{
			cout << "map fail: " << obj.errmsg() << endl;
		}
		else
		{
			cout << "mmap isnew=" << isnew << endl;
			cout << "mmap content is:" << endl;
			char* mem = obj.get_mem();
			int memsize = obj.get_size();
			string content;
			content.assign(mem, memsize);
			cout << content << endl;

			srand(time(NULL));
			int randnum = rand();
			sprintf(mem, "%d", randnum);

			cout << "write randnum=" << randnum << endl;
		}
	}
	
	return 0;
}

