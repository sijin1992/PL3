#define DEBUG
#include "../hash_map.h"
#include "../../shm/shm_wrap.h"
#include <iostream>
#include <string.h>
using namespace std;

class CMyVisitor:public CHashMapVisitor<int, int>
{
	public:
		int call(const TYPE_KEY& key, TYPE_VAL& val ,int callTimes)
		{
			cout << "at[" << callTimes << "]" << endl;
			cout << "key=" << key << "&val=" << val << endl;
			return 0;
		}
};

int main(int argc, char** argv)
{
	int num = 5;
	unsigned int size = CHashMap<int,int>::mem_size(num, num/2);
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
	CHashMap<int,int> hashmap(mem, size, num, num/2);
	if(!hashmap.valid())
	{
		cout << "hashmap not valid (" << hashmap.m_err.errcode << "," <<
			hashmap.m_err.errstrmsg << ")" << endl;
		return 0;
	}

	cout << "init--------------------------------" << endl;
	hashmap.debug(cout);

	cout << "insert--------------------------------" << endl;

	int saveIdx;
	for(int i=0; i<num+1; ++i)
	{
		int ret = hashmap.set_node(i,i+1);
		if(ret < 0)
		{
			cout << "set_node[" <<i << "] hashmap set_node " << hashmap.m_err.errstrmsg << endl;
			break;
		}
		cout << "set_node[" << i <<"] = " << ret << endl;
	}
	hashmap.debug(cout);
	

	cout << "delete--------------------------------" << endl;
	int idxs[4] = {0,num/2,num-1,num};
	int data;
	for(int j=3;j>=0;--j)
	{
		data = -1;
		int ret = hashmap.del_node(idxs[j], &data);
		if(ret < 0)
		{
			cout << "del key[" << idxs[j] << "] (" << hashmap.m_err.errcode << "," <<
				hashmap.m_err.errstrmsg << ")" << endl;
		}
		else
		{
			cout << "del key[" << idxs[j] << "]=" << ret << " data=" << data << endl;
		}
	}
	hashmap.debug(cout);


	cout << "for each--------------------------------" << endl;
	CMyVisitor vistor;
	hashmap.for_each_node(&vistor);
	

	cout << "get_node--------------------------------" << endl;
	for(int k=0; k<num+1; ++k)
	{
		int data = -1;
		int ret = hashmap.get_node(k, data);
		if(ret < 0)
		{
			cout << "get key[" << k << "] (" << hashmap.m_err.errcode << "," <<
				hashmap.m_err.errstrmsg << ")" << endl;
		}
		else
		{
			cout << "get key[" << k << "]=" << ret << " data=" << data << endl;
		}
	}
	hashmap.debug(cout);
	
	return 0;
}

