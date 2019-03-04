#include "mem_alloc.h"
#include "trace_new.h"
#include <iostream>
#include <string.h>
#include <stdio.h>


CMemAlloc::CMemAlloc()
{
	m_alloc_step = ALLOC_STEP;
	m_max_index = MAX_INDEX;
	m_cache_limit = CACHE_LIMIT;
	m_free_slots = TRACE_NEW_ARRAY(MEM_NODE*,m_max_index);
	memset(m_free_slots, 0x0, sizeof(MEM_NODE*)*(m_max_index));

	m_current_cache = 0;
}

CMemAlloc::~CMemAlloc()
{
	free_cache();

	if(m_free_slots)
	{
		TRACE_DEL_ARRAY(m_free_slots);
		m_free_slots = NULL;
	}
}

CMemAlloc::CMemAlloc(unsigned int alloc_step, unsigned int max_index, unsigned int cache_limit)
{
	m_alloc_step = alloc_step;
	m_max_index = max_index;
	m_cache_limit = cache_limit;
	m_free_slots = TRACE_NEW_ARRAY(MEM_NODE*,m_max_index);
	memset(m_free_slots, 0x0, sizeof(MEM_NODE*)*m_max_index);
	m_current_cache = 0;
}

void CMemAlloc::free_cache()
{
	if(!m_free_slots)
		return;

	MEM_NODE* it;
	char* del;
	for(unsigned int i=0; i<m_max_index; ++i)
	{
		it = m_free_slots[i];
		m_free_slots[i] = NULL;
		while(it != NULL)
		{
			del = (char*)it;
			it = it->next;
			TRACE_DEL_ARRAY(del);
		}
	}
}

CMemAlloc::MEM_NODE* CMemAlloc::alloc(unsigned int size /*in byte*/)
{
	if(!m_free_slots)
		return NULL;
	//按m_min_alloc和m_alloc_step
	unsigned int real_size = MEM_ALLOC_ALIGN(size+MEM_NODE_SIZE, m_alloc_step*1024);
	unsigned int slot_idx = real_size/(m_alloc_step*1024) - 1;
	MEM_NODE* node = NULL;

	if(slot_idx >= m_max_index)
	{
		//超大的不缓存，直接new去
	}
	else
	{
		if((node = m_free_slots[slot_idx]) !=NULL)
		{
			if(m_current_cache >=  (node->index+1)*m_alloc_step) //应该是必然的
				m_current_cache -=  (node->index+1)*m_alloc_step;
			m_free_slots[slot_idx] = node->next;
		}
		
	}

	//没有缓存就new
	if(!node)
	{
		char* p = TRACE_NEW_ARRAY(char,real_size);
		node = (MEM_NODE*)p;
	}

	//格式化
	if(node)
	{
		node->next = NULL;
		node->index = slot_idx;    
		node->first_avail = (char *)node + MEM_NODE_SIZE;    
		node->size = size;
	}

	return node;
}

void CMemAlloc::free(CMemAlloc::MEM_NODE* node)
{
	if(!m_free_slots)
		return;
		
	if((m_current_cache+ (node->index+1)*m_alloc_step) > m_cache_limit || node->index >= m_max_index)
	{
		//超出限制，free掉
		TRACE_DEL_ARRAY((char*)node);
		return;
	}

	//缓存下
	node->next = m_free_slots[node->index];
	m_free_slots[node->index] = node;
	m_current_cache += (node->index+1)*m_alloc_step;
}

void CMemAlloc::debug(ostream& out)
{
	out << "CMemAlloc:" << endl;
	out << "m_alloc_step=" << m_alloc_step << endl;
	out << "m_max_index=" << m_max_index << endl;
	out << "m_cache_limit=" << m_cache_limit << endl;
	out << "m_current_cache=" << m_current_cache << endl;
	
	if(!m_free_slots)
		return;
	MEM_NODE* it;
	for(unsigned int i=0; i<m_max_index; ++i)
	{
		it = m_free_slots[i];
		out << "slots[" << i << "] =>" << endl;
		while(it != NULL)
		{
			it->debug(out);
			it = it->next;
		}
	}
}


