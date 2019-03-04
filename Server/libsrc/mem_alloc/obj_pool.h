#ifndef __OBJ_POOL_H__
#define __OBJ_POOL_H__

#include <vector>
#include <string>
#include "mem_alloc.h"

using namespace std;

//初始化某类的ojb的pool，handle是返回值, 0=ok -1=失败.
#define POOL_INIT(handle, className, poolObjNum) gObjPools.pool_init(handle, #className, sizeof(className), poolObjNum)
//检查handle是否和className绑定的，只有符合条件，之后的alloc才是安全的
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
		//MEM_NODE内部内存排列如下
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
		//成功返回0，失败-1
		//handle返回这个pool的引用
		int pool_init(HANDLE& handle, const string& className, unsigned int objSize, unsigned int poolObjNum);

		//删除一个pool
		void pool_clear(const HANDLE& handle);

		//申请一个obj的空间,失败=NULL
		void* pool_alloc(const HANDLE& handle);

		//释放一个obj的空间
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
			//外部保证idx 在[0, max)
			return (OBJ_HEAD*) (p->first_avail+sizeof(POOL_HEAD)+idx*(sizeof(OBJ_HEAD)+objSize));
		}

		inline void* get_obj(CMemAlloc::MEM_NODE* p, int idx, unsigned int objSize)
		{
			//外部保证idx 在[0, max)
			return p->first_avail+sizeof(POOL_HEAD)+idx*(sizeof(OBJ_HEAD)+objSize)+ sizeof(OBJ_HEAD);
		}

		void* alloc_obj_innode(CMemAlloc::MEM_NODE* pnode );
		
	protected:
		CMemAlloc m_alloc;
		vector<CMemAlloc::MEM_NODE*> m_memNodes;
		int m_maxID;
		char m_errmsg[256];
};

//希望这个是全局应用，只有一个pool
extern CObjPools gObjPools;

#endif

