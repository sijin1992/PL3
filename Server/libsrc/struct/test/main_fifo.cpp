#define DEBUG
#include "../fifo_queue.h"
#include "../../shm/shm_wrap.h"
#include <iostream>
#include <string.h>
using namespace std;

class CMyVisitor:public CFIFOQueueVisitor<int>
{
	public:
		int call(const NODE_TYPE* pnode, int callTimes)
		{
			cout << "at[" << callTimes << "]" << endl;
			debugFIFONode(pnode, cout);//不能使用pnode->debug(os);编译错误
			return 0;
		}
};

int main(int argc, char** argv)
{
	int num = 3;
	unsigned int size = CFIFOQueue<int>::mem_size(num);
#if 0
	char* mem = new char[size];
#else
	CShmWrapper shm;
	int ret = shm.get(0x1001, size);
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
	CFIFOQueue<int> fifoq(mem, size);
	if(!fifoq.valid())
	{
		cout << "fifoq not valid" << endl;
		return 0;
	}

	cout << "init--------------------------------" << endl;
	fifoq.debug(cout);

	cout << "inqueue--------------------------------" << endl;

	int saveIdx;
	for(int i=0; i<num+1; ++i)
	{
		int ret = fifoq.inqueue(saveIdx, i+1);
		if(ret != 0)
		{
			cout << "at[" <<i << "] fifoq inqueue " << fifoq.m_err.errstrmsg << endl;
			break;
		}
		cout << "inqueued id=" << saveIdx << endl;
	}
	fifoq.debug(cout);
	
/*
	cout << "delete--------------------------------" << endl;
	int idxs[4] = {0,num/2,num-1,num};
	int data;
	for(int j=3;j>=0;--j)
	{
		cout << "del node " << idxs[j] << endl;
		int ret = fifoq.del(idxs[j],data);
		if(ret != 0)
		{
			cout << "del idx=" << idxs[j] << " " << fifoq.m_err.errstrmsg;
		}
	}
	fifoq.debug(cout);

	cout << "for each--------------------------------" << endl;
	CMyVisitor vistor;
	fifoq.for_each_node(&vistor);
	

	cout << "outqueue--------------------------------" << endl;
	for(int k=0; k<num+1; ++k)
	{
		int data;
		int ret = fifoq.outqueue(data);
		if(ret != 0)
		{
			cout << "at[" << k << "] fifoq outqueue " << fifoq.m_err.errstrmsg << endl;
			break;
		}
		cout << "out queue data=" << data << endl;
	}
	fifoq.debug(cout);
*/	
	return 0;
}

