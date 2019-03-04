#ifndef __MUTILSIZE_ALLOCATOR_H__
#define __MUTILSIZE_ALLOCATOR_H__

#include "fixedsize_allocator.h"
#include <map>
#include <stdio.h>
using namespace std;

/*
ʹ��fixedsize_allocator��������ʵ�ַǹ̶����ȷ���
mem-> first level fsa (blockSize)
			|-> block1 -> second level fas(size1) -> block3 -> second level fas(size1)
			|-> block2 -> second level fas(size2)
size1 ʹ�õĶ࣬��������block
size2 ֻ��һ��block
�˽ṹ������
blocksize ��С�㹻�󣬱���������п��ܷ����size+��Ϣͷ

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
	* @summary: �󶨵��ڴ� 
	* @param:pMemStart: �󶨵��ڴ��ַ
	* @param:memSize: �󶨵��ڴ泤��
	* @param:blockSize: ÿ��block��ʹ�ù̶����ȷ��䣬���ļ��׵�˵��
	* @param:format: �Ƿ�Ҫ��ʽ����=true������ȫ����ա�
	*/
	int bind(void* pMemStart, MEMSIZE  memSize, unsigned int blockSize, bool format = false);


	/*
	* @summary: ����һ���ڵ�
	* @param:pointer: ���ص�ַ
	*/
	int alloc(void*& pointer, unsigned int size);
	int alloc(int& idx, unsigned int size);


	/*
	* @summary: �ͷ�һ���ڵ�
	* @param:pointer: �ͷŵĵ�ַ
	*  size������allocʱ��size
	*/
	int free(void* pointer, unsigned int size);
	int free(int idx, unsigned int size);

	/*
	* @summary: ���
	*/
	void debug(ostream& output);

	/*
	* ����ÿ��alloc
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

