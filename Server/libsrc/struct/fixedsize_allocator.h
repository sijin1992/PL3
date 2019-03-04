/*
 * @file     fixedsize_allocator.h
 * @brief    webgame框架的固定大小内存分配器(建立在预分配的连续内存上)
 * @author   marszhang@tencent.com
 * @date     2010-11-15
 *
 * @note    	
 *
 */
#ifndef _FIXEDSIZE_ALLOCATOR_H_
#define _FIXEDSIZE_ALLOCATOR_H_

#include <stdlib.h>
#include <string.h>
#include <ostream>

using namespace std;

typedef size_t MEMSIZE;

class CFixedsizeAllocator
{
	public:
		#define FIXEDSIZEALLOC_MAIGC "CFixedsizeAllocator20110531"

	    const static int SUCCESS = 0;
	    const static int ERROR = -1;

	    const static int E_MAGICID = -100; //magicid不对
	    const static int E_NODE_INFO = -101; //传入的节点数不正确
	    const static int E_MEM_SIZE = -102; //外部分配的内存空间不够使用
	    const static int E_DATAP_ERR = -103;    //外部传入的数据指针非法
	    const static int E_MEM_FULL = -104; //空间用完了。
	    const static int E_DATAP_FREED = -105; //重复返还数据
	    const static int E_BINDED = -106; //重复绑定
	    const static int E_NOT_BIND = -107; //尚未绑定
	    const static int E_BREAK = -108; //被visitor中止


	#define FSA_BLOCK_NODE_OFFSET sizeof(CBlockHead)
	
	public:
		class CNodeInfo
		{
			public:
				unsigned int uiNum;
				unsigned int uiSize;
				CNodeInfo();
				CNodeInfo(unsigned int num,unsigned int size);
				inline void set(unsigned int num,unsigned int size)
				{
					uiNum = num;
					uiSize = size;
				}

				bool EqualTo(CNodeInfo& other);
		};

		//分配内存的基本单位的头信息
		class CBlockHead
		{
			public:
				int usedFlag; //是否使用中 0=非使用中, 反正要对齐，干脆给1个int
				int nextFreeIdx; //free链表
		};

		//分配器本身的信息也要落到内存上。
		class CHead
		{
			public:
				char magicID[32]; //做标识用
				CNodeInfo oNodeInfo;
				int freeStartIdx; //空闲链表开始偏移
				unsigned int used; //已经使用过的节点
				int borderIdx; //分界位置，偏移在此以及之后的节点未使用过。
				unsigned int blockSize;
				char reserve[72];
		};
		
	public:
		CFixedsizeAllocator();


		/*
		* @summary: 计算所需空间
		*/
		static MEMSIZE calculate_size(CNodeInfo oInfo);

		/*
		* @summary: 计算所能容纳的节点
		*/
		static MEMSIZE calculate_num(MEMSIZE memSize, unsigned int nodeSize);
	
		/*
		* @summary: 绑定到内存 
		* @param:pMemStart: 绑定的内存地址
		* @param:memSize: 绑定的内存长度
		* @param:magicID: 这个作为标识符，需要检查，以后可能有用。
		* @param:format: 是否要格式化，=true，数据全部清空。
		*/
		int bind(void* pMemStart, MEMSIZE  memSize,  CNodeInfo oInfo, bool format = false);

		/*
		* @summary: 申请一个节点
		* @param:offset: 返回偏移
		*/
		int alloc(int& idx);


		/*
		* @summary: 申请一个节点
		* @param:pointer: 返回地址
		*/
		int alloc(void*& pointer);


		/*
		* @summary: 释放一个节点
		* @param:pointer: 释放的偏移
		*/
		int free(int idx);


		/*
		* @summary: 释放一个节点
		* @param:pointer: 释放的地址
		*/
		int free(void* pointer);

		/*
		* @summary: 输出
		*/
		void dump(ostream& output, bool simple = false);

		/*
		* @summary:遍历
		*/
		class CNodeVisitor
		{
			public:
				static const int RET_CONTINUE=1;
				static const int RET_BREAK=2;
				static const int RET_DEL=4; //删除改节点
				/*
				*p和offset是同义词，一般使用指针访问
				*回调函数定义，返回RET_CONTINUE, RET_BREAK, RET_CONTINUE|RET_DEL, RET_BREAK|RET_DEL
				*/
				virtual int visit(void* p, int idx, unsigned int nodeSize) = 0;
				virtual ~CNodeVisitor();
		};

		int for_each_usednode(CNodeVisitor* pvisitor);


		/*
		* @summary:返回节点配置信息, 自己当心有没有初始化。
		*/
		CNodeInfo get_nodeinfo();

		inline bool empty()
		{
			return m_bBind && m_pHead->used == 0;
		}

		inline int free_num()
		{
			return m_bBind? m_pHead->oNodeInfo.uiNum - m_pHead->used : 0;
		}

		inline bool full()
		{
			return m_bBind && (m_pHead->used >= m_pHead->oNodeInfo.uiNum);
		}

		inline const char* binded_mem_addr()
		{
			return (const char*)m_pMemstart;
		}

		inline MEMSIZE binded_mem_size()
		{
			return m_memSize;
		}

		static MEMSIZE full_node_size(unsigned int nodeSize)
		{
			return nodeSize+FSA_BLOCK_NODE_OFFSET;
		}

		/*
		* @summary: 地址和节点互转，我只期望内部使用
		*/
		inline char* get_blockdata(int idx)
		{
			return m_pNodestart + idx*m_pHead->blockSize + FSA_BLOCK_NODE_OFFSET;
		}

		inline int to_idx(void* pointer)
		{
			char* p = (char*)pointer - FSA_BLOCK_NODE_OFFSET;
			if(p<m_pNodestart)
				return -1;
		
			int offset = p-m_pNodestart;
			if(offset % m_pHead->blockSize != 0)
				return -1;
		
			int idx = offset/m_pHead->blockSize;
			if(idx >= m_pHead->borderIdx)
				return -1;
			return idx;
		}
	
	protected:

		inline CBlockHead* get_blockhead(int idx)
		{
			return (CBlockHead*)(m_pNodestart + idx*m_pHead->blockSize);
		}

	protected:
		bool m_bBind; //是否已经绑定过。
		char* m_pMemstart; //内存开始地址。
		char* m_pNodestart; //node区开始位置
		MEMSIZE m_memSize; // 可用内存实际大小。
		CHead* m_pHead; //用来解释head结构，m_pHead = m_pMemStart
};

#endif

