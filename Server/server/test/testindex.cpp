#include "../common/indexedmap.h"
#include "struct/hash_type.h"
#include <string.h>
#include <stdio.h>

struct CNameId
{
public: 
//不要出现动态分配的内存，比如string等等
	char name[20];
	int id;
	int id2;
	int val;

public:
	void clear()
	{
		id = 0;
		id2 = 0;
		val = 0;
		name[0] = 0;
	}

	int gethash(string idxname, unsigned int& hashval) const
	{
		if(idxname == "id" || idxname == "id2")
		{
			HashType<int> hash;
			hashval = hash.do_hash(id);
			return 0;
		}
		else if(idxname == "id2")
		{
			HashType<int> hash;
			hashval = hash.do_hash(id2);
			return 0;
		}
		else if(idxname == "name")
		{
			HashType<char*> hash;
			hashval = hash.do_hash(name);
			return 0;
		}

		return -1;
	}

	static int gethash(string idxname, const char* key, unsigned int& hashval)
	{
		if(idxname == "name")
		{
			HashType<const char*> hash;
			hashval = hash.do_hash(key);
			return 0;
		}

		return -1;
	}

	static int gethash(string idxname, int key, unsigned int& hashval)
	{
		if(idxname == "id" || idxname == "id2")
		{
			HashType<int> hash;
			hashval = hash.do_hash(key);
			return 0;
		}

		return -1;
	}
	
	int comparekey(string idxname, const char* key)
	{
		if(idxname == "name")
		{
			if(strcmp(key,name) ==0)
				return 0;
		}
		
		return -1;
	}

	int comparekey(string idxname, int key)
	{
		if(idxname == "id")
		{
			if(key == id)
				return 0;
		}
		else if(idxname == "id2")
		{
			if(key == id2)
				return 0;
		}

		return -1;
	}
	
};


int main(int argc, char** argv)
{
	CIndexedMap<CNameId> themap;

	unsigned int nodenum = 100;
	MEMSIZE memsize = CIndexedMap<CNameId>::mem_size(nodenum);
	MEMSIZE idxmemsize = CIndexedMap<CNameId>::CIndexHashMap::mem_size(nodenum);
	void* mem = new char[memsize];
	void* memidx1 = new char[idxmemsize];
	void* memidx2 = new char[idxmemsize];
	void* memidx3 = new char[idxmemsize];
	if(themap.init(mem, memsize, nodenum)!=0)
	{
		cout << "init fail" << endl;
		return -1;
	}

	if(themap.addindex("id", memidx1, idxmemsize, nodenum)!=0)
	{
		cout << "addindex fail" << endl;
		return -1;
	}
	
	if(themap.addindex("id2", memidx2, idxmemsize, nodenum)!=0)
	{
		cout << "addindex fail" << endl;
		return -1;
	}
	
	if(themap.addindex("name", memidx3, idxmemsize, nodenum)!=0)
	{
		cout << "addindex fail" << endl;
		return -1;
	}

	CNameId data1;
	data1.id = 1;
	data1.id2 = 2;
	snprintf(data1.name, sizeof(data1.name), "data1");
	data1.val = 123098;

	CNameId data2;
	string idxname;
	int intkey;

	idxname = "id";
	intkey = 1;
	data2.clear();
	int ret = themap.getnode(idxname.c_str(), intkey, data2);
	cout << "-------------------------------------------------------------------------" << endl;
	cout << "getnode(" << idxname << ", " << intkey << ")=" << ret << endl;
	
	ret = themap.insertnode(data1);
	cout << "-------------------------------------------------------------------------" << endl;
	cout << "insertnode=" << ret << endl;

	data2.clear();
	ret = themap.getnode(idxname.c_str(), intkey, data2);
	cout << "-------------------------------------------------------------------------" << endl;
	cout << "getnode(" << idxname << ", " << intkey << ")=" << ret << endl;
	if(ret == 1)
		cout << "val=" << data2.val << endl;
 
	intkey=2;
	ret = themap.getnode(idxname.c_str(), intkey, data2);
	cout << "-------------------------------------------------------------------------" << endl;
	cout << "getnode(" << idxname << ", " << intkey << ")=" << ret << endl;

	data2.clear();
	idxname = "id2";
	ret = themap.getnode(idxname.c_str(), intkey, data2);
	cout << "-------------------------------------------------------------------------" << endl;
	cout << "getnode(" << idxname << ", " << intkey << ")=" << ret << endl;
	if(ret == 1)
		cout << "val=" << data2.val << endl;

	data2.clear();
	idxname = "name";
	ret = themap.getnode(idxname.c_str(), "data1", data2);
	cout << "-------------------------------------------------------------------------" << endl;
	cout << "getnode(" << idxname << ", " << "data1" << ")=" << ret << endl;
	if(ret == 1)
		cout << "val=" << data2.val << endl;

	ret = themap.delnode(idxname.c_str(), "data1", data2);
	cout << "-------------------------------------------------------------------------" << endl;
	cout << "delnode(" << idxname << ", " << "data1" << ")=" << ret << endl;

	idxname = "id";
	intkey=1;
	ret = themap.getnode(idxname.c_str(), intkey, data2);
	cout << "-------------------------------------------------------------------------" << endl;
	cout << "getnode(" << idxname << ", " << intkey << ")=" << ret << endl;
	
	return 0;
}

