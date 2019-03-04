#include "../mem_dequeue.h"
#include <iostream>
#include <string.h>
using namespace std;

void initbuff(char* buf, unsigned int size)
{
	for(unsigned int i=0; i<size; ++i)
	{
		buf[i] = i%128;
	}
	cout << endl;
}

int checkbuff(char* buf, unsigned int size)
{
	for(unsigned int i=0; i<size; ++i)
	{
		cout << int(buf[i]) << " ";
	}

	cout << endl;

	return 1;
}

int main(int argc, char** argv)
{
	unsigned int size = CDeque::getallocsize(100);
	char buff[100] = {0};
	char* mem = new char[size];
	CDeque deque;
	int ret = deque.initialize(mem, size, 100);
	if(ret != 0)
	{
		cout << "init=" << ret << endl;
		return 0;
	}

	cout << "start--------------------------------" << endl;
	deque.debug(cout);
	unsigned int next = 0;
	unsigned int poped = 0;

#if 0
	cout << "read write test--------------------------------"

	initbuff(buff, 100);
	//read write
	cout << "write(10)=" << deque.write(buff, 10) << endl;
	deque.debug(cout);

	cout << "write(100)=" << deque.write(buff, 100) << endl;
	deque.debug(cout);
	
	memset(buff, 0x0, 100);
	cout << "read(20)=" << deque.read(buff, 20) << endl;
	deque.debug(cout);
	checkbuff(buff, 100);

	memset(buff, 0x0, 100);
	cout << "read(100)=" << deque.read(buff, 100) << endl;
	deque.debug(cout);
	checkbuff(buff, 100);

	deque.clear();
	deque.debug(cout);
#endif

#if 0
	cout << "push pop peer test--------------------------------" << endl;
	initbuff(buff, 100);
	
	cout << "push(10)=" << deque.push(buff, 10) << endl;
	deque.debug(cout);

	cout << "push(100)=" << deque.push(buff, 100) << endl;
	deque.debug(cout);

	cout << "push(11)=" << deque.push(buff, 11) << endl;
	deque.debug(cout);
	
	cout << "push(12)=" << deque.push(buff, 12) << endl;
	deque.debug(cout);

	next = 0;
	poped = 0;
	cout << "peer(5)=" << deque.peer(buff, 5, &poped, &next);
	cout << " poped=" << poped << " next=" << next << endl;
	deque.debug(cout); 

	next = 0;
	poped = 0;
	memset(buff, 0x0, 100);
	cout << "peer(20)=" << deque.peer(buff, 20, &poped, &next);
	cout << " poped=" << poped << " next=" << next << endl;
	deque.debug(cout); 
	checkbuff(buff, 100);

	cout << "remove to " << next << endl;
	deque.remove(next);
	deque.debug(cout); 

	poped = 0;
	cout << "pop(5)=" << deque.pop(buff, 5, &poped);
	cout << " poped=" << poped << endl;
	deque.debug(cout); 

	poped = 0;
	memset(buff, 0x0, 100);
	cout << "pop(20)=" << deque.pop(buff, 20, &poped);
	cout << " poped=" << poped << endl;
	deque.debug(cout); 
	checkbuff(buff, 100);
	
	poped = 0;
	char* data = NULL;
	cout << "pop(new)=" << deque.pop(data, &poped);
	cout << " poped=" << poped << endl;
	deque.debug(cout); 
	checkbuff(data, poped);

	delete[] data;

	initbuff(buff, 100);
	cout << "push(10)=" << deque.push(buff, 10) << endl;
	deque.debug(cout); 
	poped = 0;
	cout << "remove=" << deque.remove(&poped);
	cout << " poped=" << poped << endl;
	deque.debug(cout); 
#endif

	cout << "recover test--------------------------------" << endl;
	initbuff(buff, 100);
	deque.clear();
	deque.push(buff, 10);
	CDeque deque2;
	cout << "init=" << deque2.initialize(mem, size, 100, true) << endl;
	deque2.debug(cout);
	
	cout << "wrong packet test --------------------------------" << endl;

	cout << "deque2.write(buff, 2)=" << deque2.write(buff, 2) << endl;
	deque.debug(cout);

	memset(buff, 0x0, 100);
	cout << "deque2.read(buff, 2)=" << deque2.read(buff, 2) << endl;
	deque.debug(cout);
	checkbuff(buff, 100);
	
	cout << "deque2.pop(buff, 10)=" << deque2.pop(buff, 10, &poped) << endl;
	deque2.debug(cout);
	
	return 0;
}

