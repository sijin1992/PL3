#pragma once

#include <map>
#include <string>
#include <iostream>
#include "struct/fixedsize_allocator.h"
#include <stdio.h>
using namespace std;

//datatype ex
#if 0 
#include "struct/hash_type.h"
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


#endif

template<typename DATATYPE>
class CIndexedMap
{
	public:
		class CIndexNode
		{
		public:
			int next;
			int datapointer;
		};

		class CIndexHashMap
		{
			public:
				typedef int HASHVAL_TYPE;
			public:
				CFixedsizeAllocator alloc;
				HASHVAL_TYPE* hashslots;
				int hashsize;
				bool inited;
				
			public:
				CIndexHashMap()
				{
					hashslots = NULL;
					inited = false;
					hashsize = 0;
				}

				~CIndexHashMap()
				{
				}

				static size_t mem_size(unsigned int nodenum)
				{
					CFixedsizeAllocator::CNodeInfo info;
					info.uiNum = nodenum;
					info.uiSize = sizeof(CIndexNode);
					MEMSIZE memSize = CFixedsizeAllocator::calculate_size(info);
					memSize += sizeof(HASHVAL_TYPE)*nodenum;
					return memSize;
				}
				
				int init(void* mem, MEMSIZE memsize, unsigned int nodenum)
				{
					MEMSIZE hashbytes = sizeof(HASHVAL_TYPE)*nodenum;
					if(memsize < hashbytes)
						return -1;
					
					hashsize = nodenum;
					hashslots = (HASHVAL_TYPE*)mem;
					memset((char*)hashslots, 0, hashbytes);
					
					CFixedsizeAllocator::CNodeInfo info;
					info.uiSize = sizeof(CIndexNode);
					info.uiNum = nodenum;
					
					int ret = alloc.bind((char*)(mem)+hashbytes, memsize-hashbytes, info, true);
					if(ret != 0)
					{
						return ret;
					}

					inited = true;
					return 0;
				}

				inline CIndexNode* first(int hashval, int** ppnext=NULL)
				{
					int node = hashslots[hashval%hashsize];
					if(ppnext)
						*ppnext = &(hashslots[hashval%hashsize]);
					if(node == 0)
						return NULL;
					return (CIndexNode*)alloc.get_blockdata(node-1);
				}

				inline CIndexNode* next(CIndexNode* cur, int** ppnext=NULL)
				{
					if(ppnext)
						*ppnext = &(cur->next);
					if(cur->next == 0)
						return NULL;
					return (CIndexNode*)alloc.get_blockdata(cur->next-1);
				}

				inline int insert(int hashval, int datapointer)
				{
					int nodepointer;
					int ret = alloc.alloc(nodepointer);
					if(ret != 0)
					{
						return ret;
					}
					
					CIndexNode* pnode = (CIndexNode*)alloc.get_blockdata(nodepointer);
					pnode->datapointer = datapointer;
					pnode->next = hashslots[hashval%hashsize];
					hashslots[hashval%hashsize] = nodepointer+1;

					return 0;
				}

				inline void free(int* pnext, CIndexNode* pnode)
				{
					*pnext = pnode->next;
					alloc.free((void*)pnode);
				}
				
		};

	public:

		typedef map<string, CIndexHashMap*> INDEXMAP;

		CIndexedMap()
		{
			m_inited = false;
			m_errmsg[0] = 0;
		}

		~CIndexedMap()
		{
			typename INDEXMAP::iterator it;
			for(it=m_idxnames.begin(); it!=m_idxnames.end(); ++it)
			{
				delete it->second;
			}

			m_idxnames.clear();
		}

		
		static MEMSIZE mem_size(unsigned int nodenum)
		{
			CFixedsizeAllocator::CNodeInfo info;
			info.uiNum = nodenum;
			info.uiSize = sizeof(DATATYPE);
			return CFixedsizeAllocator::calculate_size(info);
		}

		int init(void* mem, MEMSIZE memSize, unsigned int nodenum)
		{
			CFixedsizeAllocator::CNodeInfo info;
			info.uiNum = nodenum;
			info.uiSize = sizeof(DATATYPE);
			int ret = m_dataAlloc.bind(mem, memSize, info, true);
			if(ret != 0)
			{
				snprintf(m_errmsg, sizeof(m_errmsg), "m_dataAlloc.bind=%d", ret);
				return -1;
			}
			m_inited = true;
			return 0;
		}

		//添加一个索引，idxname必须唯一
		int addindex(const char* idxname, void* mem, MEMSIZE memsize, unsigned int nodenum)
		{
			if(!m_inited)
			{
				snprintf(m_errmsg, sizeof(m_errmsg), "not inited");
				return -1;
			}
			
			CIndexHashMap* newidx = new CIndexHashMap;
			int ret = newidx->init(mem, memsize, nodenum);
			if(ret !=0)
			{
				snprintf(m_errmsg, sizeof(m_errmsg), "CIndexedMap init=%d", ret);
				return -1;
			}
			m_idxnames.insert(make_pair(idxname, newidx));
			return 0;
		}

		//根据某个索引删除节点，其他索引也会相应修改
		//idxname 必须已经由addindex设置
		//注意返回值为0=没有节点1=成功
		template<typename KEYTYPE>
		int delnode(const char* idxname, const KEYTYPE& key, DATATYPE& data)
		{
			if(!m_inited)
			{
				snprintf(m_errmsg, sizeof(m_errmsg), "not inited");
				return -1;
			}
			
			CIndexHashMap* pidx = checkidx(idxname);
			if(!pidx)
				return -1;

			unsigned int hashval;
			if(DATATYPE::gethash(idxname, key, hashval)!=0)
				return -1;
			
			int* pnext;
			CIndexNode* pidxnode = pidx->first(hashval, &pnext);
			bool hasdata = false;
			DATATYPE* pdata = NULL;
			while(pidxnode)
			{
				pdata =  getdata(pidxnode);

				if(pdata->comparekey(idxname, key) == 0)
				{
					pidx->free(pnext, pidxnode);
					data = *pdata;
					hasdata = true;
					break;
				}
				pidxnode = pidx->next(pidxnode, &pnext);
			}

			if(hasdata) //has data
			{
				//free other idx
				typename INDEXMAP::iterator it;
				for(it=m_idxnames.begin(); it!=m_idxnames.end(); ++it)
				{
					if(it->first != idxname)
						del_other_idx(it->second, it->first, pdata);
				}
				//free data
				m_dataAlloc.free(pdata);

				return 1;
			}

			return 0;
		}

		//根据某个索引取得节点
		//idxname 必须已经由addindex设置
		//注意返回值为0=没有节点1=成功
		template<typename KEYTYPE>
		int getnode(const char* idxname, const KEYTYPE& key, DATATYPE& data)
		{
			if(!m_inited)
			{
				snprintf(m_errmsg, sizeof(m_errmsg), "not inited");
				return -1;
			}

			CIndexHashMap* pidx = checkidx(idxname);
			if(!pidx)
				return -1;

			unsigned int hashval;
			if(DATATYPE::gethash(idxname, key, hashval)!=0)
				return -1;

			CIndexNode* pidxnode = pidx->first(hashval);
			bool found =false;
			while(pidxnode)
			{
				DATATYPE* pdata = getdata(pidxnode);

				if(pdata->comparekey(idxname, key) == 0)
				{
					data = *pdata;
					found = true;
					break;
				}
				pidxnode = pidx->next(pidxnode);
			}

			if(found)
				return 1;
			
			return 0;
		}

		//同时更新所有addindex置入的索引，要求至少有一个index
		//这里不会去检测data的各个key是否重复
		//有必要的话，外部自己调用所有key的getnode去确认
		int insertnode(const DATATYPE& data)
		{
			if(!m_inited)
			{
				snprintf(m_errmsg, sizeof(m_errmsg), "not inited");
				return -1;
			}

			int datapointer =0;
			int ret = m_dataAlloc.alloc(datapointer);
			if(ret != 0)
			{
				snprintf(m_errmsg, sizeof(m_errmsg), "m_dataAlloc.alloc=%d", ret);
				return -1;
			}

			DATATYPE* pdata = getdata(datapointer);
			*pdata = data;

			typename INDEXMAP::iterator it;
			for(it=m_idxnames.begin(); it!=m_idxnames.end(); ++it)
			{
				unsigned int hashval;
				if(pdata->gethash(it->first, hashval)!=0)
					return -1;

				if(it->second->insert(hashval, datapointer)!=0)
				{
					snprintf(m_errmsg, sizeof(m_errmsg), "index(%s).alloc=%d", it->first.c_str(), ret);
					//roll back
					typename INDEXMAP::iterator it2;
					for(it2=m_idxnames.begin(); it2 != it; ++it2)
						del_other_idx(it2->second, it2->first, pdata);

					m_dataAlloc.free(datapointer);

					return -1;
				}
			}

						
			return 0;
		}

		inline const char* errmsg()
		{
			return m_errmsg;
		}

	protected:
		inline DATATYPE* getdata(CIndexNode* pidxnode)
		{
			return (DATATYPE*)m_dataAlloc.get_blockdata(pidxnode->datapointer);
		}

		inline DATATYPE* getdata(int datapointer)
		{
			return (DATATYPE*)m_dataAlloc.get_blockdata(datapointer);
		}
		
		inline CIndexHashMap* checkidx(const char* idxname)
		{
			typename INDEXMAP::iterator it = m_idxnames.find(idxname);
			if(it == m_idxnames.end())
			{
				snprintf(m_errmsg, sizeof(m_errmsg), "idxname(%s) not found", idxname);
				return NULL;
			}

			return it->second;
		}

		int del_other_idx(CIndexHashMap* pidx, const string& idxname, const DATATYPE* padata)
		{
			unsigned int hashval;
			if(padata->gethash(idxname, hashval)!=0)
				return -1;
			
			int* pnext;
			CIndexNode* pidxnode = pidx->first(hashval, &pnext);
			while(pidxnode)
			{
				DATATYPE* pdata = (DATATYPE*)getdata(pidxnode);
				if(pdata == padata)
				{
					pidx->free(pnext, pidxnode);
					break;
				}
				pidxnode = pidx->next(pidxnode, &pnext);
			}
		
			return 0;
		}

	protected:
		INDEXMAP m_idxnames;
		CFixedsizeAllocator m_dataAlloc;
		bool m_inited;
		char m_errmsg[256];
};

