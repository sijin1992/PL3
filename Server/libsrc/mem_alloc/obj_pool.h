#ifndef __OBJ_POOL_H__
#define __OBJ_POOL_H__

#include <vector>
#include <string>
#include "mem_alloc.h"

using namespace std;

//��ʼ��ĳ���ojb��pool��handle�Ƿ���ֵ, 0=ok -1=ʧ��.
#define POOL_INIT(handle, className, poolObjNum) gObjPools.pool_init(handle, #className, sizeof(className), poolObjNum)
//���handle�Ƿ��className�󶨵ģ�ֻ�з���������֮���alloc���ǰ�ȫ��
#define CHECK_HANDLE(handle, classNm) (handle.className == #classNm)

#define POOL_ALLOC_CHECKED(handle, className) (CHECK_HANDLE(handle, className)?(className*)gObjPools.pool_alloc(handle):NULL)
#define POOL_ALLOC(handle) gObjPools.pool_alloc(handle)
#define POOL_FREE(handle, pointer) gObjPools.pool_free(handle, pointer)
#define POOL_CLEAR(handle) gObjPools.pool_clear(handle)
#define POOL_ERRMSG gObjPools.errmsg()
#define POOL_DEBUG(OSTREAM) gObjPools.debug(OSTREAM)

class CObjPools
{
	public:
		struct HANDLE
		{
			HANDLE(){poolID = -1;}
			int poolID;
			string className;
		};

	protected:
		//MEM_NODE�ڲ��ڴ���������
		// MEM_NODE{ POOL_HEAD{} [OBJ_HEAD{}OBJ{}, ... ,  OBJ_HEAD{}OBJ{}] }  ->  NEXT_MEM_NODE{...}
		struct POOL_HEAD
		{
			CMemAlloc::MEM_NODE* nextMemNode;
			unsigned int poolObjNum;
			unsigned int poolObjSize;
			int freeIdx;
			int useIdx;
			unsigned int usedNum;
			void debug(ostream& os)
			{
				os << "POOL_HEAD{" << endl;
				os << "nextMemNode|" << (size_t)nextMemNode << endl;
				os << "poolObjNum|" << poolObjNum << endl;
				os << "poolObjSize|" << poolObjSize << endl;
				os << "freeIdx|" << freeIdx << endl;
				os << "useIdx|" << useIdx << endl;
				os << "usedNum|" << usedNum << endl;
				os << "} end POOL_HEAD" << endl;
			}
		};

		struct OBJ_HEAD
		{
			int next;
			int use;
		};
		
	public:
		CObjPools();

		~CObjPools();
		//�ɹ�����0��ʧ��-1
		//handle�������pool������
		int pool_init(HANDLE& handle, const string& className, unsigned int objSize, unsigned int poolObjNum);

		//ɾ��һ��pool
		void pool_clear(const HANDLE& handle);

		//����һ��obj�Ŀռ�,ʧ��=NULL
		void* pool_alloc(const HANDLE& handle);

		//�ͷ�һ��obj�Ŀռ�
		void pool_free(const HANDLE& handle, void* p);

		inline char* errmsg()
		{
			return m_errmsg;
		}

		void debug(ostream& os);

	protected:
		void init_mem_node(CMemAlloc::MEM_NODE* p, unsigned int objSize, unsigned int poolObjNum);

		inline unsigned int alloc_size( unsigned int objSize, unsigned int poolObjNum)
		{
			return sizeof(POOL_HEAD)+(sizeof(OBJ_HEAD)+objSize)*poolObjNum;
		}

		inline POOL_HEAD* get_pool_head(CMemAlloc::MEM_NODE* p)
		{
			return (POOL_HEAD*)(p->first_avail);
		}

		inline OBJ_HEAD* get_obj_head(CMemAlloc::MEM_NODE* p, int idx, unsigned int objSize)
		{
			//�ⲿ��֤idx ��[0, max)
			return (OBJ_HEAD*) (p->first_avail+sizeof(POOL_HEAD)+idx*(sizeof(OBJ_HEAD)+objSize));
		}

		inline void* get_obj(CMemAlloc::MEM_NODE* p, int idx, unsigned int objSize)
		{
			//�ⲿ��֤idx ��[0, max)
			return p->first_avail+sizeof(POOL_HEAD)+idx*(sizeof(OBJ_HEAD)+objSize)+ sizeof(OBJ_HEAD);
		}

		void* alloc_obj_innode(CMemAlloc::MEM_NODE* pnode );
		
	protected:
		CMemAlloc m_alloc;
		vector<CMemAlloc::MEM_NODE*> m_memNodes;
		int m_maxID;
		char m_errmsg[256];
};

//ϣ�������ȫ��Ӧ�ã�ֻ��һ��pool
extern CObjPools gObjPools;

#endif

