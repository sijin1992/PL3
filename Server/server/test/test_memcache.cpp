#include "my_memcached.hpp"
#include <iostream>
using namespace std;
using namespace memcache;

CMyMemcache gmem;

void replace_test(const string& key, char* value, int vallen, bool expect)
{
	cout << "call replace(key=" << key << ") = ";
	vector<char> v;
	v.assign(value, value+vallen);
	bool ret = gmem.replace(key,v);
	cout << ret << " and expect=" << expect << endl;
	if(!ret)
	{
		if(expect)
			cout << "UNEXPECTED|should be true..." << endl;
		string errmsg;
		cout <<  "lastretcode=" << gmem.lastretcode() << " " << gmem.lastretstr()<< ",error=";
		cout << errmsg << endl;
	}
	else
	{
		if(!expect)
			cout << "UNEXPECTED|should be false..." << endl;
	}
}

void del_test(const string& key, bool expect)
{
	cout << "call delete(key=" << key << ") = ";
	bool ret = gmem.remove(key);
	cout << ret << " and expect=" << expect << endl;
	if(!ret)
	{
		if(expect)
			cout << "UNEXPECTED|should be true..." << endl;
		string errmsg;
		cout <<  "lastretcode=" << gmem.lastretcode() << " " << gmem.lastretstr()<< ",error=";
		cout << errmsg << endl;
	}
	else
	{
		if(!expect)
			cout << "UNEXPECTED|should be false..." << endl;
	}
}


void add_test(const string& key, char* value, int vallen, bool expect)
{
	cout << "call add(key=" << key << ") = ";
	vector<char> v;
	v.assign(value, value+vallen);
	bool ret = gmem.add(key,v);
	cout << ret << " and expect=" << expect << endl;
	if(!ret)
	{
		if(expect)
			cout << "UNEXPECTED|should be true..." << endl;
		string errmsg;
		cout <<  "lastretcode=" << gmem.lastretcode() << " " << gmem.lastretstr()<< ",error=";
		cout << errmsg << endl;
	}
	else
	{
		if(!expect)
			cout << "UNEXPECTED|should be false..." << endl;
	}
}

void get_test(const string& key, char* valueexpect, int vlenexpect, bool expect)
{
	cout << "call get(key=" << key << ") = ";
	vector<char> v;
	vector<char> v_ret;
	v.assign(valueexpect, valueexpect+vlenexpect);
	bool ret = gmem.get(key, v_ret);
	cout << ret << " and expect=" << expect << endl;
	if(!ret)
	{
		if(expect)
			cout << "UNEXPECTED|should be true..." << endl;
		string errmsg;
		cout <<  "lastretcode=" << gmem.lastretcode() << " " << gmem.lastretstr()<< ",error=";
		cout << errmsg << endl;

	}
	else
	{
		if(!expect)
			cout << "UNEXPECTED|should be false..." << endl;
			
		bool valequel = (v.size() == v_ret.size()) && (memcpy((char*)&(v[0]), (char*)&(v_ret[0]), v.size()));
		if(valequel)
		{
			cout << "value ok" << endl;
		}
		else
			cout << "unexpect val[" << &(v_ret[0]) << "]" << endl;
	}
}

void set_test(const string& key, char* value, int vallen, unsigned int flags, bool expect)
{
	cout << "call set(key=" << key << ") = ";
	vector<char> v;
	v.assign(value, value+vallen);
	bool ret = gmem.set(key,v, 0, flags);
	cout << ret << " and expect=" << expect << endl;
	if(!ret)
	{
		if(expect)
			cout << "UNEXPECTED|should be true..." << endl;
		string errmsg;
		cout <<  "lastretcode=" << gmem.lastretcode() << " " << gmem.lastretstr()<< ",error=";
		cout << errmsg << endl;
	}
	else
	{
		if(!expect)
			cout << "UNEXPECTED|should be false..." << endl;
	}
}



void mget_test(vector<string>& thekeys)
{
	if(!gmem.mget(thekeys))
	{
		cout <<  "lastretcode=" << gmem.lastretcode() << " " << gmem.lastretstr() << endl;
	}
	else
	{
		string key;
		vector<char> vals;
		uint32_t flags;
		uint64_t cas;
		for(unsigned int i=0; i<thekeys.size(); ++i)
		{
			memcached_return_t ret = gmem.fetch(key, vals, flags, cas);
			if(!memcached_success(ret))
			{
				cout <<  "lastretcode=" << ret << " " << gmem.getError(ret) << endl;
			}
			else
			{
				cout << "fteched " << key << ",  val=" << &vals[0] << ", flags=" << flags << ", cas=" << cas << endl;
			}
		}
	}
}

void cas_test(const  string & key, char* value, int vallen, unsigned long long cas_arg, bool expect)
{
	cout << "call cas(key=" << key << ") = ";
	vector<char> v;
	v.assign(value, value+vallen);
	bool ret = gmem.cas(key, v, cas_arg);
	cout << ret << " and expect=" << expect << endl;
	if(!ret)
	{
		if(expect)
			cout << "UNEXPECTED|should be true..." << endl;
		string errmsg;
		cout <<  "lastretcode=" << gmem.lastretcode() << " " << gmem.lastretstr()<< ",error=";
		cout << errmsg << endl;
	}
	else
	{
		if(!expect)
			cout << "UNEXPECTED|should be false..." << endl;
	}
	
}

int main(int argc, char** argv)
{
	if(argc < 3)
	{
		cout << argv[0] << " memconfigstr cmd" << endl;
		return 0;
	}

	if(!gmem.configure(argv[1]))
	{
		string errmsg;
		cout << "error=" << gmem.error(errmsg);
		cout << "config(" << argv[1] << ") fail " << errmsg << endl;
		return -1;
	}

	string cmd = argv[2];
	string key="mars";
	string key2="zaya";
	string key3="not exsit";
	char value1[] = {"1231434123413412341664521234134512341251451"};
	char value2[] = {"asfascxvadsfwerqwasdfqaerfqwtrggasdfgertgqwqrsdfawerqwrewefasdfawefq"};

	if(cmd == "testcase")
	{
		//delete ,总有一个是错的
		del_test(key, true);
		del_test(key, false);
		
		//get 
		get_test(key, value1,  sizeof(value1), false);

		//replace
		replace_test(key,value2, sizeof(value2), false);
		
		//先add
		add_test(key, value1,  sizeof(value1),true);

		//add ag
		add_test(key, value1,  sizeof(value1),false);

		//get 
		get_test(key, value1,  sizeof(value1), true);
		
		//replace
		replace_test(key,value2, sizeof(value2), true);

		//get 
		get_test(key, value2,  sizeof(value2), true);

		//set
		set_test(key2, value1, sizeof(value1), 11112222, true);

		//mget for one
		vector<string> thekeys;
		thekeys.push_back(key);
		mget_test(thekeys);

		//mget for two
		thekeys.push_back(key2);
		mget_test(thekeys);

		//mget for three
		thekeys.push_back(key3);
		mget_test(thekeys);

		//cas
		cas_test(key, value1, sizeof(value1), 1234567ll, false);
	}
	
	return 0;
}

