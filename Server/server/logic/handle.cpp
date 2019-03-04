#include "handle.h"

CLogicHandle::CLogicHandle()
{
	m_processor = NULL;
	m_shmaddr = NULL;
	m_pallocator = NULL;
	m_shmsize = 0;
	m_busepool = false;
	m_bholdprocessor = true;
}

void CLogicHandle::free_processor()
{
	//还掉共享内存
	if(m_shmaddr && m_pallocator)
	{
		m_pallocator->free(m_shmaddr, m_shmsize);
		m_shmaddr = NULL;
		m_shmsize = 0;
	}

	if(m_processor && m_bholdprocessor)
	{
		if(m_busepool)
		{
			POOL_FREE(m_objPoolHandle,m_processor);
		}
		else
		{
			delete m_processor;
		}
		m_processor = NULL;
	}
}

int CLogicHandle::init_processor(unsigned int id, unsigned int msgID, CToolkit* ptool, CMutilsizeAllocator* pallocator)
{
	if(m_processor == NULL)
		return -1;

	//对processor初始化
	m_processor->m_id = id;
	m_processor->m_ptoolkit = ptool;
	
	m_pallocator = pallocator;

	//是否要绑定一块共享内存
	unsigned int shmsize = m_processor->need_shm_size();

	if(shmsize > 0 && m_pallocator)
	{
		void* p;
		m_shmsize = shmsize+sizeof(SHM_SAVE_CREATE_INFO);
		int ret = m_pallocator->alloc(p,m_shmsize);
		if(ret != 0)
		{
			return -1;
		}

		m_shmaddr = (char*)p;

		//给processor用的共享内存
		m_processor->bind_shm(m_shmaddr+sizeof(SHM_SAVE_CREATE_INFO));
		
		//保存下create信息
		SHM_SAVE_CREATE_INFO* pcreate = (SHM_SAVE_CREATE_INFO*)m_shmaddr;
		pcreate->savedHandleID = id;
		pcreate->savedMsgCmd = msgID;
	}
	return 0;
}

//从共享内存中恢复
int CLogicHandle::recover_processor(void* shm, unsigned shmsize, CToolkit* ptool, CMutilsizeAllocator* pallocator)
{
	if(m_processor == NULL)
		return -1;
	m_shmsize = shmsize;
	m_shmaddr = (char*)shm;
	m_pallocator = pallocator;
	SHM_SAVE_CREATE_INFO* pcreate = (SHM_SAVE_CREATE_INFO*)m_shmaddr;

	//校验一下shm大小是否一致
	unsigned int usershmsize = m_processor->need_shm_size();
	if(usershmsize + sizeof(SHM_SAVE_CREATE_INFO) != shmsize)
	{
		return -1;
	}

	m_processor->m_id = pcreate->savedHandleID;
	m_processor->m_ptoolkit = ptool;
	m_processor->bind_shm(m_shmaddr+sizeof(SHM_SAVE_CREATE_INFO));

	return 0;
}

int CLogicCreator::create(CLogicHandle& handle, bool buseobjpool)
{
	if(m_proto == NULL)
		return -1;

	handle.m_busepool = buseobjpool;
	if(m_uniq)
	{
		handle.m_bholdprocessor = false;
		handle.m_processor = m_proto;
	}
	else
	{
		if(buseobjpool)
		{
			handle.m_processor = m_proto->create_in_objpool(handle.m_objPoolHandle);
		}
		else
		{
			handle.m_processor	= m_proto->create(); 
		}
	}

	if(handle.m_processor == NULL)
		return -1;
	
	return 0;
}

