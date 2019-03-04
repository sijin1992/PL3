/*
 * @file     fixedsize_allocator.cpp
 * @brief    webgame框架的固定大小内存分配器(建立在预分配的连续内存上)
 * @author   marszhang@tencent.com
 * @date     2010-11-15
 *
 * @note    	本来想复用"comm/mem_pool/fixedsize_mem_pool.h"，无奈是个模板，想使用它做复杂组合，
 * 			或者说是想存n种类型的数据时很讨厌，必须定义n种类的mem_pool，不爽。
 *			其实就只是用到了sizeof(DATATYPE)，不如把长度参数化，而不是类型参数化。
 *			至于如何解释数据，调用者来考虑，分配器不管你。
 *
 */


#include <stdlib.h>
#include <string.h>
#include <ostream>
#include "fixedsize_allocator.h"
#include "string.h"
#include <stdio.h>
	CFixedsizeAllocator::CNodeInfo::CNodeInfo(unsigned int num,unsigned int size)
	{
		set(num, size);
	}

	CFixedsizeAllocator::CNodeInfo::CNodeInfo()
	{
		set(0, 0);
	}

	bool CFixedsizeAllocator::CNodeInfo::EqualTo(CNodeInfo& other)
	{
		return (uiNum == other.uiNum) && (uiSize == other.uiSize);
	}



	CFixedsizeAllocator::CFixedsizeAllocator()
	{
		m_bBind = false;
	}


	/*
	* @summary: 计算所需空间
	*/
	MEMSIZE CFixedsizeAllocator::calculate_size(CFixedsizeAllocator::CNodeInfo oInfo)
	{
		return full_node_size(oInfo.uiSize)*oInfo.uiNum + sizeof(CHead);
	}

	/*
	* @summary: 计算所能容纳的节点
	*/
	MEMSIZE CFixedsizeAllocator::calculate_num(MEMSIZE  memSize, unsigned int nodeSize)
	{
		return (memSize - sizeof(CHead))/full_node_size(nodeSize);
	}

	/*
	* @summary: 绑定到内存 
	* @param:pMemStart: 绑定的内存地址
	* @param:memSize: 绑定的内存长度
	* @param:format: 是否要格式化，=true，数据全部清空。
	*/
	int CFixedsizeAllocator::bind(void* pMemStart, MEMSIZE  memSize, CFixedsizeAllocator::CNodeInfo oInfo, bool format)
	{
		if(m_bBind)
			return E_BINDED;


		MEMSIZE max = calculate_size(oInfo);
		if(!pMemStart || memSize < max)
		{
			return E_MEM_SIZE;
		}

		m_pMemstart = (char*)pMemStart;
		m_pHead = (CHead*)m_pMemstart;
		m_memSize = memSize;
		m_pNodestart = m_pMemstart + sizeof(CHead);

		if(format)
		{
			snprintf(m_pHead->magicID, sizeof(m_pHead->magicID), "%s", FIXEDSIZEALLOC_MAIGC);
			m_pHead->oNodeInfo = oInfo;
			m_pHead->freeStartIdx = -1; 
			m_pHead->used = 0;
			m_pHead->borderIdx = 0;
			m_pHead->blockSize = full_node_size(oInfo.uiSize); //写死的必须和calculate_size的算法一致
		}
		else
		{
			if(strncmp(m_pHead->magicID, FIXEDSIZEALLOC_MAIGC, sizeof(m_pHead->magicID)) != 0)
			{
				return E_MAGICID;
			}
			
			if(!oInfo.EqualTo(m_pHead->oNodeInfo) || m_pHead->blockSize!=full_node_size(oInfo.uiSize))
			{
				return E_NODE_INFO;
			}

		}

		m_bBind = true;

		return SUCCESS;

	}

	/*
	* @summary: 申请一个节点
	* @param:offset: 返回偏移
	*/
	int CFixedsizeAllocator::alloc(int& idx)
	{
		if(!m_bBind)
			return E_NOT_BIND;

		CBlockHead* phead;
		if(m_pHead->freeStartIdx == -1)
		{
			if(full())
			{
				return E_MEM_FULL;
			}
			//退一格
			idx = (m_pHead->borderIdx)++;
		}
		else
		{	
			idx = m_pHead->freeStartIdx;
			m_pHead->freeStartIdx = get_blockhead(idx)->nextFreeIdx;
		}

		phead = get_blockhead(idx);
		phead->usedFlag = 1;
		phead->nextFreeIdx = -1;
		++m_pHead->used;

		return SUCCESS;
	}

	/*
	* @summary: 申请一个节点
	* @param:pointer: 返回地址
	*/
	int CFixedsizeAllocator::alloc(void*& pointer)
	{
		if(!m_bBind)
			return E_NOT_BIND;

		int idx;
		int ret = alloc(idx);
		if(ret == SUCCESS)
			pointer = get_blockdata(idx);

		return ret;
	}

	/*
	* @summary: 释放一个节点
	* @param:pointer: 释放的偏移
	*/
	int CFixedsizeAllocator::free(int idx)
	{
		if(!m_bBind)
			return E_NOT_BIND;

		if(idx < 0 || idx >= m_pHead->borderIdx)
		{
			return E_DATAP_ERR;
		}

		CBlockHead* phead = get_blockhead(idx);
		if(phead->usedFlag == 0)
		{
			return E_DATAP_FREED;
		}

		phead->usedFlag = 0;
		phead->nextFreeIdx = m_pHead->freeStartIdx;
		m_pHead->freeStartIdx = idx;

		if(m_pHead->used > 0)
			--m_pHead->used; //这里按道理应该不会到0的

		return SUCCESS;
	}

	/*
	* @summary: 释放一个节点
	* @param:pointer: 释放的地址
	*/
	int CFixedsizeAllocator::free(void* pointer)
	{
		if(!m_bBind)
			return E_NOT_BIND;

		int idx = to_idx(pointer);
		if(idx < 0)
			return E_DATAP_ERR;

		return free(idx);
	}

	/*
	* @summary: 输出
	*/
	void CFixedsizeAllocator::dump(ostream& output, bool simple)
	{
		if(!m_bBind)
		{
			output << "not bind" << endl;
			return ;
		}
		
		output << "CFixedsizeAllocator{" << endl;
		output << "use mem begin at [" << hex << (MEMSIZE)m_pMemstart << dec << "] length[" << m_memSize << "]" << endl;
		output << "head [magicID:" << m_pHead->magicID << ", nodeInfo:{num:" << m_pHead->oNodeInfo.uiNum << ",size:"
			<< m_pHead->oNodeInfo.uiSize << "}, borderIdx:" << m_pHead->borderIdx << ", used:" 
			<< m_pHead->used << ", blocksize:" << m_pHead->blockSize << "]" << endl;
		if(!simple)
		{
			output << "freelist [" << endl;
			CBlockHead* p;
			int idx = m_pHead->freeStartIdx;
			while(idx != -1)
			{
				p = get_blockhead(idx);
				output << idx << "(" << p->usedFlag << ")" << endl;
				idx = p->nextFreeIdx;
			}
			output << "]" << endl;
		}
		output << "} end CFixedsizeAllocator" << endl;
	}

	CFixedsizeAllocator::CNodeVisitor::~CNodeVisitor()
	{
	}

	int CFixedsizeAllocator::for_each_usednode(CFixedsizeAllocator::CNodeVisitor* pvisitor)
	{
		if(!m_bBind)
		{
			return E_NOT_BIND;
		}


		CBlockHead* p = NULL;
		int it = 0;
		int ret = 0;
		while(it < m_pHead->borderIdx)
		{
			p = get_blockhead(it);
			if(p->usedFlag != 0)
			{
				ret = pvisitor->visit(get_blockdata(it), it, m_pHead->oNodeInfo.uiSize);
				if(ret & CFixedsizeAllocator::CNodeVisitor::RET_DEL)
				{
					free(it);
				}
				
				if(ret & CFixedsizeAllocator::CNodeVisitor::RET_CONTINUE)
				{
				}
				else
				{
					return E_BREAK;
				}
			}
			it += m_pHead->blockSize;
		}

		return SUCCESS;
	}

	/*
	* @summary:返回节点配置信息, 自己当心有没有初始化。
	*/
	CFixedsizeAllocator::CNodeInfo CFixedsizeAllocator::get_nodeinfo()
	{
		if(!m_bBind)
		{
			return CNodeInfo(0,0);
		}
		return m_pHead->oNodeInfo;
	}





