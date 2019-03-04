#ifndef __LOGIC_HANDLE_MANAGER_H__
#define __LOGIC_HANDLE_MANAGER_H__

#include <map>
#include "handle.h"
#include "log/log.h"
#include "struct/mutilsize_allocator.h"
#include "struct/uniq_id.h"
#include "shm/shm_wrap.h"

using namespace std;
#include <ext/hash_map>
using namespace __gnu_cxx;

#ifdef USE_OBJ_POOL
#include "mem_alloc/obj_pool.h"
#endif

#include "toolkit.h"

class CLogicRecoverVisitor;

typedef map<unsigned int, CLogicCreator> HANDLE_REG_MAP;
typedef hash_map<unsigned int, CLogicHandle> HANDLE_ROUTE_MAP;

class CLogicHandleManager
{
public:
	friend class CLogicRecoverVisitor;

	CLogicHandleManager(CToolkit* ptoolkit, bool useObjPool, HANDLE_REG_MAP* pregmap);

	~CLogicHandleManager();

	int init_allcator(unsigned int key, unsigned int size, unsigned int blocksize);

	//pSuperCreator的存在给外部绑定处理类一定的自由度
	int process_msg(CLogicMsg& msg, CLogicCreator* pSuperCreator = NULL);
	
protected:

	class CLogicRecoverVisitor: public CFixedsizeAllocator::CNodeVisitor
	{
	public:
		CLogicRecoverVisitor(CLogicHandleManager* master):m_master(master)
		{
		}

		virtual int visit(void* p, int idx, unsigned int nodeSize);
		
	protected:
		CLogicHandleManager* m_master;
	};


	//启动时恢复
	inline int recover()
	{
		CLogicRecoverVisitor visitor(this);
		int ret = m_pallocator->for_each_usednode(&visitor);
		if(ret != 0)
		{
			LOG(LOG_ERROR, "recover for_each_usednode fail %s", m_pallocator->errmsg());
			return -1;
		}

		return 0;
	}

protected:
	HANDLE_REG_MAP *m_pregistMap;
	HANDLE_ROUTE_MAP m_routeMap;
	CToolkit* m_ptoolkit;
	CUniqID<unsigned int> m_uid;
	CShmWrapper m_pshmForAlloc;
	CMutilsizeAllocator* m_pallocator;
	bool m_usepool;
};



#endif

