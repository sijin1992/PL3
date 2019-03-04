/*
 * @file     fixedsize_allocator.h
 * @brief    webgame��ܵĹ̶���С�ڴ������(������Ԥ����������ڴ���)
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

	    const static int E_MAGICID = -100; //magicid����
	    const static int E_NODE_INFO = -101; //����Ľڵ�������ȷ
	    const static int E_MEM_SIZE = -102; //�ⲿ������ڴ�ռ䲻��ʹ��
	    const static int E_DATAP_ERR = -103;    //�ⲿ���������ָ��Ƿ�
	    const static int E_MEM_FULL = -104; //�ռ������ˡ�
	    const static int E_DATAP_FREED = -105; //�ظ���������
	    const static int E_BINDED = -106; //�ظ���
	    const static int E_NOT_BIND = -107; //��δ��
	    const static int E_BREAK = -108; //��visitor��ֹ


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

		//�����ڴ�Ļ�����λ��ͷ��Ϣ
		class CBlockHead
		{
			public:
				int usedFlag; //�Ƿ�ʹ���� 0=��ʹ����, ����Ҫ���룬�ɴ��1��int
				int nextFreeIdx; //free����
		};

		//�������������ϢҲҪ�䵽�ڴ��ϡ�
		class CHead
		{
			public:
				char magicID[32]; //����ʶ��
				CNodeInfo oNodeInfo;
				int freeStartIdx; //��������ʼƫ��
				unsigned int used; //�Ѿ�ʹ�ù��Ľڵ�
				int borderIdx; //�ֽ�λ�ã�ƫ���ڴ��Լ�֮��Ľڵ�δʹ�ù���
				unsigned int blockSize;
				char reserve[72];
		};
		
	public:
		CFixedsizeAllocator();


		/*
		* @summary: ��������ռ�
		*/
		static MEMSIZE calculate_size(CNodeInfo oInfo);

		/*
		* @summary: �����������ɵĽڵ�
		*/
		static MEMSIZE calculate_num(MEMSIZE memSize, unsigned int nodeSize);
	
		/*
		* @summary: �󶨵��ڴ� 
		* @param:pMemStart: �󶨵��ڴ��ַ
		* @param:memSize: �󶨵��ڴ泤��
		* @param:magicID: �����Ϊ��ʶ������Ҫ��飬�Ժ�������á�
		* @param:format: �Ƿ�Ҫ��ʽ����=true������ȫ����ա�
		*/
		int bind(void* pMemStart, MEMSIZE  memSize,  CNodeInfo oInfo, bool format = false);

		/*
		* @summary: ����һ���ڵ�
		* @param:offset: ����ƫ��
		*/
		int alloc(int& idx);


		/*
		* @summary: ����һ���ڵ�
		* @param:pointer: ���ص�ַ
		*/
		int alloc(void*& pointer);


		/*
		* @summary: �ͷ�һ���ڵ�
		* @param:pointer: �ͷŵ�ƫ��
		*/
		int free(int idx);


		/*
		* @summary: �ͷ�һ���ڵ�
		* @param:pointer: �ͷŵĵ�ַ
		*/
		int free(void* pointer);

		/*
		* @summary: ���
		*/
		void dump(ostream& output, bool simple = false);

		/*
		* @summary:����
		*/
		class CNodeVisitor
		{
			public:
				static const int RET_CONTINUE=1;
				static const int RET_BREAK=2;
				static const int RET_DEL=4; //ɾ���Ľڵ�
				/*
				*p��offset��ͬ��ʣ�һ��ʹ��ָ�����
				*�ص��������壬����RET_CONTINUE, RET_BREAK, RET_CONTINUE|RET_DEL, RET_BREAK|RET_DEL
				*/
				virtual int visit(void* p, int idx, unsigned int nodeSize) = 0;
				virtual ~CNodeVisitor();
		};

		int for_each_usednode(CNodeVisitor* pvisitor);


		/*
		* @summary:���ؽڵ�������Ϣ, �Լ�������û�г�ʼ����
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
		* @summary: ��ַ�ͽڵ㻥ת����ֻ�����ڲ�ʹ��
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
		bool m_bBind; //�Ƿ��Ѿ��󶨹���
		char* m_pMemstart; //�ڴ濪ʼ��ַ��
		char* m_pNodestart; //node����ʼλ��
		MEMSIZE m_memSize; // �����ڴ�ʵ�ʴ�С��
		CHead* m_pHead; //��������head�ṹ��m_pHead = m_pMemStart
};

#endif

