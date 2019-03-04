#include "obj_pool.h"
#include <stdio.h>
CObjPools gObjPools;

CObjPools::CObjPools()
{
	m_maxID = 0;
	m_errmsg[0] = 0;
}

CObjPools::~CObjPools()
{
	HANDLE innerHandle;
	for(int i=0; i<m_maxID; ++i)
	{
		innerHandle.poolID = i;
		pool_clear(innerHandle);
	}
}

int CObjPools::pool_init(CObjPools::HANDLE& handle, const string& className, unsigned int objSize, unsigned int poolObjNum)
{
	unsigned int size = alloc_size(objSize, poolObjNum);
	CMemAlloc::MEM_NODE* p = m_alloc.alloc(size);
	if(p==NULL)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "m_alloc.alloc(%u) fail", size);
		return -1;
	}

	init_mem_node(p, objSize, poolObjNum);
	
	m_memNodes.push_back(p);
	handle.className = className;
	handle.poolID = m_maxID++;

	return 0;
}

void CObjPools::pool_clear(const CObjPools::HANDLE& handle)
{
	if(handle.poolID < 0 || handle.poolID >= m_maxID)
	{
		return;
	}

	CMemAlloc::MEM_NODE* del = NULL;
	CMemAlloc::MEM_NODE* p = m_memNodes[handle.poolID];
	while(p)
	{
		del = p;
		p = get_pool_head(p)->nextMemNode;
		m_alloc.free(del);
	}

	m_memNodes[handle.poolID] = NULL;
}

void* CObjPools::pool_alloc(const CObjPools::HANDLE& handle)
{
	if(handle.poolID < 0 || handle.poolID >= m_maxID)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "poolID(%d) ,max(%d) not valid", handle.poolID, m_maxID);
		return NULL;
	}
	
	CMemAlloc::MEM_NODE* pnode = m_memNodes[handle.poolID];

	if(pnode == NULL)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "poolID(%d) has been cleared", handle.poolID);
		return NULL;
	}

	POOL_HEAD* first = get_pool_head(pnode);

	while(pnode)
	{
		POOL_HEAD* head = get_pool_head(pnode);
		if(head->usedNum == head->poolObjNum)
		{
			//full, see next
			pnode = head->nextMemNode;
		}
		else
		{
			return alloc_obj_innode(pnode);
		}
	}

	//都满的,新开一个node
	pnode = m_alloc.alloc(alloc_size(first->poolObjSize, first->poolObjNum));
	init_mem_node(pnode, first->poolObjSize, first->poolObjNum);
	//把这个node加到vector链首
	get_pool_head(pnode)->nextMemNode = m_memNodes[handle.poolID];
	m_memNodes[handle.poolID] = pnode;

	return alloc_obj_innode(pnode);
	
}

void CObjPools::pool_free(const CObjPools::HANDLE& handle, void* p)
{
	if(handle.poolID < 0 || handle.poolID >= m_maxID)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "poolID(%d) ,max(%d) not valid", handle.poolID, m_maxID);
	}
	
	CMemAlloc::MEM_NODE** ppnode = &(m_memNodes[handle.poolID]);
	bool bFirstMemNode = true;

	while(*ppnode)
	{
		bool bfreed = false;
		CMemAlloc::MEM_NODE* pnode = *ppnode;
		POOL_HEAD* head = get_pool_head(pnode);
		int* pnext = &(head->useIdx);
		while(*pnext >= 0)
		{
			OBJ_HEAD* pobjHead = get_obj_head(pnode, *pnext,  head->poolObjSize);
			void* pobj = get_obj(pnode, *pnext,  head->poolObjSize);
			if(pobj == p)
			{
				//本来就不在使用中，啥都不做
				if(pobjHead->use == 0)
					return;
				
				pobjHead->use = 0;
				if(head->usedNum > 0)
					head->usedNum--;

				//从used链拿下
				int theIdx = *pnext;
				*pnext  = pobjHead->next;
				//加到free首
				pobjHead->next = head->freeIdx;
				head->freeIdx = theIdx;
				bfreed = true;
				break;
			}
			pnext  = &(pobjHead->next);
		}

		if(bfreed)
		{
			if(head->usedNum > 0 || head->useIdx != -1) //这两个条件应该是同时满足的
			{
				//非空MEMNODE
			}
			else
			{
				//空MEMNODE
				if(!bFirstMemNode)
				{
					//指向自己的指针要指向next去
					*ppnode = head->nextMemNode;
					m_alloc.free(pnode);
				}
			}

			return;
		}
		
		ppnode = &(head->nextMemNode);
		bFirstMemNode = false;
	}
	
}

void CObjPools::init_mem_node(CMemAlloc::MEM_NODE* pnode, unsigned int objSize, unsigned int poolObjNum)
{
	POOL_HEAD* p = get_pool_head(pnode);
	p->poolObjNum = poolObjNum;
	p->nextMemNode = NULL;
	p->poolObjSize = objSize;
	p->freeIdx = 0;
	p->useIdx = -1;
	p->usedNum = 0;
	for(unsigned int i=0; i<poolObjNum; ++i)
	{
		OBJ_HEAD* pobjHead = get_obj_head(pnode, i, objSize);
		pobjHead->use = 0;
		if(i==poolObjNum-1)
			pobjHead->next = -1;
		else
			pobjHead->next = i+1;
	}
}

void* CObjPools::alloc_obj_innode(CMemAlloc::MEM_NODE* pnode )
{
	POOL_HEAD* head = get_pool_head(pnode);
	if(head->freeIdx < 0)
	{
		//应该不会出现
		snprintf(m_errmsg, sizeof(m_errmsg), "usednum(%u) ,max(%u) but freelist empty", head->usedNum, head->poolObjNum);
		return NULL;
	}


	int idx = head->freeIdx;
	OBJ_HEAD* pobjHead = get_obj_head(pnode, idx,  head->poolObjSize);
	void* retaddr = get_obj(pnode, idx,  head->poolObjSize);

	if(pobjHead->use != 0)
	{
		//应该不会出现
		snprintf(m_errmsg, sizeof(m_errmsg), "in freelist use=%d", pobjHead->use);
		return NULL;
	}
	else
	{
		pobjHead->use = 1;
	}


	//从free链首拿下
	head->freeIdx = pobjHead->next;
	//加到use链首
	pobjHead->next = head->useIdx;
	head->useIdx = idx;
	//增加使用数
	++(head->usedNum);
	pobjHead->use = 1;
	
	return retaddr;
}

void CObjPools::debug(ostream& os)
{
	for(int i=0; i<m_maxID; ++i)
	{
		CMemAlloc::MEM_NODE* p = m_memNodes[i];
		if(p != NULL)
		{
			cout << "slot[" << i << "]:" << endl;
			while(p)
			{
				POOL_HEAD*  head = get_pool_head(p);
				head->debug(cout);
				int free = head->freeIdx;
				int use = head->useIdx;
				cout << "free";
				while(free >= 0)
				{
					OBJ_HEAD* pobjHead = get_obj_head(p, free,  head->poolObjSize);
					cout << "->[" << free << "](used=" << pobjHead->use << ")";
					free = pobjHead->next;
				}
				cout << endl << "use";
				while(use >= 0)
				{
					OBJ_HEAD* pobjHead = get_obj_head(p, use,  head->poolObjSize);
					cout << "->[" << use << "](used=" << pobjHead->use << ")";
					use = pobjHead->next;
				}
				cout << endl;
				p = head->nextMemNode;
			}
		}
	}
}

