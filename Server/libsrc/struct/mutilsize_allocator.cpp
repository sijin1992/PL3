#include "mutilsize_allocator.h"


class CRecoverMapVisitor: public CFixedsizeAllocator::CNodeVisitor
{
	public:
		CRecoverMapVisitor(CMutilsizeAllocator* pmaster)
		{
			m_pmaster = pmaster;
		}
		
		int visit(void * p, int idx, unsigned int nodeSize)
		{
			int ret = m_pmaster->recover_block_alloc(p);
			if(ret != 0)
			{
				return RET_BREAK;
			}
			
			return RET_CONTINUE;
		}
	protected:
		CMutilsizeAllocator* m_pmaster;
};

CMutilsizeAllocator::CMutilsizeAllocator()
{
	m_binded = false;
	m_errmsg[0] = 0;
	m_blocksize = 0;
}

CMutilsizeAllocator::~CMutilsizeAllocator()
{
	BLOCK_MAP::iterator it;
	FSA_LIST_NODE* del;
	for(it = m_blockMap.begin(); it!=m_blockMap.end(); ++it)
	{
		FSA_LIST_NODE* p = it->second;
		while(p!=NULL)
		{
			del = p;
			p = p->next;
			delete del;
		}
		it->second = NULL;
	}
}


int CMutilsizeAllocator::bind(void* pMemStart, MEMSIZE memSize, unsigned int blockSize, bool format)
{
	if(m_binded)
		return 0;
	
	CFixedsizeAllocator::CNodeInfo oInfo(CFixedsizeAllocator::calculate_num(memSize, blockSize), blockSize);
	
	int ret = m_topFSA.bind(pMemStart, memSize, oInfo, format);
	if(ret != CFixedsizeAllocator::SUCCESS)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "m_topFSA.bind %d", ret);
		return -1;
	}

	m_blocksize = blockSize;

	//�ָ�map
	CRecoverMapVisitor visitor(this);
	ret = m_topFSA.for_each_usednode(&visitor);
	if(ret != CFixedsizeAllocator::SUCCESS)
	{
		return -1;
	}
	
	m_binded = true;
	return 0;
}

int CMutilsizeAllocator::for_each_usednode(CFixedsizeAllocator::CNodeVisitor* pvisitor)
{
	if(!m_binded)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "CMutilsizeAllocator not binded");
		return -1;
	}

	//ֱ�Ӵ�map�б���
	BLOCK_MAP::iterator it;
	for(it = m_blockMap.begin(); it!=m_blockMap.end(); ++it)
	{
		FSA_LIST_NODE* p = it->second;
		while(p != NULL)
		{
			int ret = p->blockFSA.for_each_usednode(pvisitor);
			if(ret != CFixedsizeAllocator::SUCCESS)
			{
				return -1;
			}				
			p = p->next;
		}
	}
	return 0;
}

int CMutilsizeAllocator::alloc(int& idx, unsigned int size)
{
	void* p;
	int ret = alloc(p, size);
	if(ret != 0)
		return ret;
	idx = m_topFSA.to_idx(p);
	return 0;
}

int CMutilsizeAllocator::alloc(void*& pointer, unsigned int size)
{
	if(!m_binded)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "CMutilsizeAllocator not binded");
		return -1;
	}

	int ret = 0;
	BLOCK_MAP::iterator it = m_blockMap.find(size);
	if(it != m_blockMap.end())
	{
		FSA_LIST_NODE* p = it->second;
		while(p != NULL)
		{
			if( !(p->blockFSA.full()) )
			{
				ret = p->blockFSA.alloc(pointer);
				if(ret != CFixedsizeAllocator::SUCCESS)
				{
					snprintf(m_errmsg, sizeof(m_errmsg), "blockFSA.alloc %d", ret);
					return -1;
				}
		
				return 0;
			}
			p = p->next;
		}
	}

	//��Ҫ�µ�block
	void* newblock;
	ret = m_topFSA.alloc(newblock);
	if(ret != CFixedsizeAllocator::SUCCESS)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "m_topFSA.alloc %d", ret);
		return -1;
	}


	FSA_LIST_NODE* listNode = new FSA_LIST_NODE;
	if(listNode == NULL)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "new listNode fail");
		return -1;
	}
	
	listNode->next = NULL;
	listNode->pblockHead = (CMutilsizeAllocator::BLOCK_HEAD*)newblock;
	
	unsigned int bindsize = m_blocksize - sizeof(BLOCK_HEAD);
	char* bindmem = (char*)newblock + sizeof(BLOCK_HEAD);

	listNode->pblockHead->nodeInfo.set(CFixedsizeAllocator::calculate_num(bindsize, size), size);

	ret = listNode->blockFSA.bind(bindmem, bindsize, listNode->pblockHead->nodeInfo, true);
	if(ret != CFixedsizeAllocator::SUCCESS)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "listNode->blockFSA.bind %d", ret);
		return -1;
	}

	unsigned int theSize = listNode->pblockHead->nodeInfo.uiSize;

	if(it == m_blockMap.end())
	{
		m_blockMap.insert(make_pair(theSize, listNode));
	}
	else
	{
		listNode->next = it->second;
		it->second = listNode;
	}

	//����ռ�
	ret = listNode->blockFSA.alloc(pointer);
	if(ret != CFixedsizeAllocator::SUCCESS)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "listNode->blockFSA.alloc %d", ret);
		return -1;
	}

	return 0;	
}

int CMutilsizeAllocator::free(int idx, unsigned int size)
{
	void* pointer = m_topFSA.get_blockdata(idx);
	return free(pointer, size);
}

int CMutilsizeAllocator::free(void* pointer, unsigned int size)
{
	if(!m_binded)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "CMutilsizeAllocator not binded");
		return -1;
	}

	int ret = 0;
	BLOCK_MAP::iterator it = m_blockMap.find(size);
	if(it == m_blockMap.end())
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "free size=%u not found", size);
		return -1;
	}

	FSA_LIST_NODE* p = it->second;
	FSA_LIST_NODE* plast = NULL;
	while(p!=NULL)
	{
		//���Դ���������ϵ�ÿ��allocɾ��
		ret = p->blockFSA.free(pointer);
		if(ret == CFixedsizeAllocator::SUCCESS ||
			ret == CFixedsizeAllocator::E_DATAP_FREED)
		{
			if(p->blockFSA.empty()) //�ͷ�����alloc
			{
				m_topFSA.free(p->pblockHead); //Ӧ��û���
				if(plast == NULL)
				{
					//�ǵ�һ���ڵ�
					it->second = p->next;
				}
				else
				{
					plast->next = p->next;
				}
				delete p;
				//������������֮�󲻴�map��erase it
				//���ǿ��ǵ�Ӧ�ó���ֻ��������size���෴��ʹ�á�
				//������ǣ�������ƶ��ǲ����ʵġ�����������������
			}
			return 0;
		}
		plast = p;
		p = p->next;
	}

	snprintf(m_errmsg, sizeof(m_errmsg), "free address not found");
	return -1;
}


void CMutilsizeAllocator::debug(ostream& output)
{
	if(!m_binded)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "CMutilsizeAllocator not binded");
		return ;
	}
	BLOCK_MAP::iterator it;
	output << "CMutilsizeAllocator{" << endl;
	output << "m_binded|" << m_binded << endl;
	output << "m_blocksize|" << m_blocksize << endl;
	output << "topAlloc nodenum=" << m_topFSA.get_nodeinfo().uiNum << ", bindmem(" << (size_t)(m_topFSA.binded_mem_addr()) << "," << m_topFSA.binded_mem_size() << ")" << endl;
	for(it = m_blockMap.begin(); it!=m_blockMap.end(); ++it)
	{
		output << "block(size=" << it->first << "):	";
		FSA_LIST_NODE* p = it->second;
		while(p != NULL)
		{
			output << "nodenum=" << p->pblockHead->nodeInfo.uiNum << "," << "bindmem(" << (size_t)(p->blockFSA.binded_mem_addr())
				<< "," << p->blockFSA.binded_mem_size() << ")->"; 
			p = p->next;
		}
		output << endl;
	}
	output << "} end CMutilsizeAllocator" << endl;
}

int CMutilsizeAllocator::recover_block_alloc(void* blockmem)
{
	FSA_LIST_NODE* listNode = new FSA_LIST_NODE;
	if(listNode == NULL)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "new listNode fail");
		return -1;
	}
	
	listNode->next = NULL;
	listNode->pblockHead = (CMutilsizeAllocator::BLOCK_HEAD*)blockmem;
	
	unsigned int bindsize = m_blocksize - sizeof(BLOCK_HEAD);
	char* bindmem = (char*)blockmem + sizeof(BLOCK_HEAD);

	int ret = listNode->blockFSA.bind(bindmem, bindsize, listNode->pblockHead->nodeInfo, false);
	if(ret != CFixedsizeAllocator::SUCCESS)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "listNode->blockFSA.bind %d", ret);
		return -1;
	}

	unsigned int theSize = listNode->pblockHead->nodeInfo.uiSize;

	BLOCK_MAP::iterator it = m_blockMap.find(theSize);
	if(it == m_blockMap.end())
	{
		m_blockMap.insert(make_pair(theSize, listNode));
	}
	else
	{
		listNode->next = it->second;
		it->second = listNode;
	}

	return 0;
}


