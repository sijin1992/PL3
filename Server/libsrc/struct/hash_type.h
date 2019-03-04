#pragma once

#include <string>
using namespace std;

inline unsigned int steal_stl_hash_string(const char* __s, unsigned int max=32)
{
	unsigned int __h = 0;
	for (unsigned int i=0 ; *__s && i<max; ++__s,++i)
	__h = 5 * __h + *__s;
	return __h;
}

template<typename TKEY>
struct HashType
{
};

template<> 
struct HashType<int>
{
	unsigned int do_hash(const int key) {return key;}
};

template<> 
struct HashType<unsigned int>
{
	unsigned int do_hash(const unsigned int key) {return key;}
};

template<> 
struct HashType<long int>
{
	unsigned int do_hash(const long int key) {return key;}
};

template<> 
struct HashType<unsigned long int>
{
	unsigned int do_hash(const unsigned long int key) {return key;}
};

template<> 
struct HashType<long long int>
{
	unsigned int do_hash(const long long int key) {return key;}
};

template<> 
struct HashType<unsigned long long int>
{
	unsigned int do_hash(const unsigned long long int key) {return key;}
};

//×Ö·û´®µÄ
template<> 
struct HashType<const char*>
{
	unsigned int do_hash(const char* key) {return steal_stl_hash_string(key);}
};

template<> 
struct HashType<char*>
{
	unsigned int do_hash(const char* key) {return steal_stl_hash_string(key);}
};

template<> 
struct HashType<string>
{
	unsigned int do_hash(const string& key) {return steal_stl_hash_string(key.c_str(), key.length());}
};


