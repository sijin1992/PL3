#include "shm/mmap_wrap.h"
#include "struct/hash_map.h"
#include "common/msg_define.h"
#include <string>
#include "log/log.h"
#pragma once

using namespace std;

class CHashedUserList
{
public:
	struct NEICEDATA{
		int flag;
		int level;
		NEICEDATA()
		{
			flag =0;
			level = 0;
		}
	};
	typedef CHashMap<USER_NAME, NEICEDATA, UserHashType> CHashedUserListType;
	
	CHashedUserList()
	{
		m_phashmap = NULL;
	}

	~CHashedUserList()
	{
		if(m_phashmap != NULL)
		{
			delete m_phashmap;
			m_phashmap = NULL;
		}
	}
	
	int init(const char* file, int usermax)
	{
		int isnew = 0;
		size_t memSize = CHashedUserListType::mem_size(usermax, usermax/2);
		int ret = m_mmap.map(file, memSize, isnew);
		if(ret != 0)
		{
			LOG(LOG_ERROR, "m_mmap(file=%s) %s", file, m_mmap.errmsg());
			return -1;
		}
		
		char* memStart = m_mmap.get_mem();
		if(isnew)
		{
			CHashedUserListType::clear(memStart);
		}
		
		m_phashmap = new CHashedUserListType(memStart, memSize, usermax, usermax/2);
		if(m_phashmap == NULL)
		{
			LOG(LOG_ERROR, "new CHashedUserListType fail");
			return -1;
		}

		if(!m_phashmap->valid())
		{
			LOG(LOG_ERROR, "CHashedUserListType not valid %d %s", m_phashmap->m_err.errcode, m_phashmap->m_err.errstrmsg);
			return -1;
		}

		return 0;
	}

	//return 0=ok -1=fail
	int add_user(const USER_NAME& theuser, int level)
	{
		NEICEDATA val;
		val.flag = 0;
		val.level = level;
		int ret = m_phashmap->set_node(theuser, val);
		if(ret < 0)
		{
			LOG(LOG_ERROR, "CHashedUserListType set=%d %s", m_phashmap->m_err.errcode, m_phashmap->m_err.errstrmsg);
			return -1;
		}

		return 0;
	}

	//return 0=ok, -1=fail
	int get_user(const USER_NAME& theuser, bool& inlist, NEICEDATA& val)
	{	
		int ret = m_phashmap->get_node(theuser, val);
		if(ret < 0)
		{
			LOG(LOG_ERROR, "CHashedUserListType get=%d %s", m_phashmap->m_err.errcode, m_phashmap->m_err.errstrmsg);
			return -1;
		}
		else if(ret == 0)
		{
			inlist = false;
		}
		else
		{
			inlist = true;
		}

		return 0;
	}

protected:
	CMmapWrap m_mmap;
	CHashedUserListType* m_phashmap;
};

