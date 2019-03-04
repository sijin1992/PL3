#ifndef __MUTILSIZE_ALLOCATOR_H__
#define __MUTILSIZE_ALLOCATOR_H__

#include "fixedsize_allocator.h"
#include <map>
#include <stdio.h>
using namespace std;

/*
使用fixedsize_allocator两层联级实现非固定长度分配
mem-> first level fsa (blockSize)
			|-> block1 -> second level fas(size1) -> block3 -> second level fas(size1)
			|-> block2 -> second level fas(size2)
size1 使用的多，分配两个block
size2 只有一个block
此结构有限制
blocksize 大小足够大，必须大于所有可能分配的size+信息头

*/
class CRecoverMapVisitor;

class CMutilsizeAllocator
{
	protected:
		struct BLOCK_HEAD
		{
			CFixedsizeAllocator::CNodeInfo nodeInfo;
		};
	
		struct FSA_LIST_NODE
		{
			CFixedsizeAllocator blockFSA;
			BLOCK_HEAD* pblockHead;
			FSA_LIST_NODE* next;
		};
	
		typedef map<unsigned int, FSA_LIST_NODE*> BLOCK_MAP;

public:
	CMutilsizeAllocator();
	~CMutilsizeAllocator();

	/*
	* @summary: 绑定到内存 
	* @param:pMemStart: 绑定的内存地址
	* @param:memSize: 绑定的内存长度
	* @param:blockSize: 每个block中使用固定长度分配，见文件首的说明
	* @param:format: 是否要格式化，=true，数据全部清空。
	*/
	int bind(void* pMemStart, MEMSIZE  memSize, unsigned int blockSize, bool format = false);


	/*
	* @summary: 申请一个节点
	* @param:pointer: 返回地址
	*/
	int alloc(void*& pointer, unsigned int size);
	int alloc(int& idx, unsigned int size);


	/*
	* @summary: 释放一个节点
	* @param:pointer: 释放的地址
	*  size必须是alloc时的size
	*/
	int free(void* pointer, unsigned int size);
	int free(int idx, unsigned int size);

	/*
	* @summary: 输出
	*/
	void debug(ostream& output);

	/*
	* 遍历每个alloc
	*/
	int for_each_usednode(CFixedsizeAllocator::CNodeVisitor* pvisitor);

	inline char* errmsg()
	{
		return m_errmsg;
	}

	friend class CRecoverMapVisitor;

protected:
	
	int recover_block_alloc(void* blockmem);

protected:
	BLOCK_MAP m_blockMap;
	CFixedsizeAllocator m_topFSA;
	bool m_binded;
	char m_errmsg[256];
	unsigned int m_blocksize;
};

#endif

