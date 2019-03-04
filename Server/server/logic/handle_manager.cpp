#include "handle_manager.h"

CLogicHandleManager::CLogicHandleManager(CToolkit* ptoolkit, bool useObjPool, HANDLE_REG_MAP* pregmap)
{
	m_ptoolkit = ptoolkit;
	m_usepool = useObjPool;
	m_pregistMap = pregmap;
	m_pallocator = NULL;
}

CLogicHandleManager::~CLogicHandleManager()
{
	if(m_pallocator != NULL)
	{
		delete m_pallocator;
		m_pallocator = NULL;
	}
}

int CLogicHandleManager::init_allcator(unsigned int key, unsigned int size, unsigned int blocksize)
{
	int ret = m_pshmForAlloc.get(key, size);
	if(ret == CShmWrapper::ERROR)
	{
		LOG(LOG_ERROR, "shm.get(%u,%u) fail %s", key, size, m_pshmForAlloc.errmsg());
		return -1;
	}

	m_pallocator = new CMutilsizeAllocator;

	if(m_pallocator == NULL)
	{
		LOG(LOG_ERROR, "new CMutilsizeAllocator fail");
		return -1;
	}

	char* mem = (char*)(m_pshmForAlloc.get_mem());
	if(size != m_pshmForAlloc.get_shm_size())
	{
		LOG(LOG_ERROR, "shm size not right");
		return -1;
	}

	bool bformat;

	if(ret == CShmWrapper::SHM_EXIST)
	{
		bformat = false;
	}
	else
	{ 
		bformat = true;
	}

	ret = m_pallocator->bind(mem, size, blocksize, bformat);
	if(ret != 0)
	{
		LOG(LOG_ERROR, "msa bind fail %s format=%d", 
			m_pallocator->errmsg(), bformat);
		if(!bformat)
		{
			//没有format fail时，强制format
			if(m_pallocator->bind(mem, size, blocksize, true)!=0)
			{
				LOG(LOG_ERROR, "msa bind force formated %s", 
					m_pallocator->errmsg());
				return -1;
			}
			else
			{
				LOG(LOG_INFO, "msa bind force formated");
			}
		}
		else
		{
			return -1;
		}
	}
	else
	{
		LOG(LOG_INFO, "msa bind format=%d", bformat);
	}

	return recover();
}

//pSuperCreator的存在给外部绑定处理类一定的自由度
int CLogicHandleManager::process_msg(CLogicMsg& msg, CLogicCreator* pSuperCreator)
{
	int ret = 0;
	unsigned int msgCmd = msg.head()->cmdID;
	unsigned int handleID = msg.head()->desHandleID;
	CLogicCreator* pcreator;
	if(pSuperCreator)
	{
		pcreator = pSuperCreator;
	}
	else
	{
		HANDLE_REG_MAP::iterator it = m_pregistMap->find(msgCmd);
		if(it != m_pregistMap->end())
			pcreator = &(it->second);
		else
			pcreator = NULL;
	}

	if(pcreator)
	{
		//注册命令, 创建对象
		CLogicHandle newHandle;
		ret = pcreator->create(newHandle, m_usepool);
		if(ret!= 0)
		{
			LOG(LOG_ERROR, "cmd=%u create handle fail", msgCmd);
			return -1;
		}

		//初始化对象
		unsigned int theObjID; 

		//防止冲突
		int max = 10;
		while(--max > 0)
		{
			theObjID = m_uid.get_id();
			if(m_routeMap.find(theObjID)==m_routeMap.end())
			{
				break;
			}
		}

		//什么叫尼玛的悲剧
		if(max <= 0)
		{
			LOG(LOG_ERROR, "new id for cmd(%u) conflicts...", msgCmd);
			return -1;
		}

		
		ret = newHandle.init_processor(theObjID, msgCmd, m_ptoolkit, m_pallocator);
		if(ret != 0)
		{
			LOG(LOG_ERROR, "cmd=%u init_processor fail alloc %s", msgCmd, m_pallocator->errmsg());
			return -1;
		}
		
		//回调init  & active
		newHandle.on_init();
		ret = newHandle.on_active(msg);
		if(ret == CLogicProcessor::RET_DONE)
		{
			//逻辑结束释放对象
			newHandle.on_finish();
			newHandle.free_processor();
		}
		else
		{
			//insert into map等待再次激活
			if(pcreator->uniq())
			{
				LOG(LOG_ERROR, "cmd=%u bind a creator(uniq=ture) can't ret RET_YIELD", msgCmd);
				newHandle.on_finish();
				newHandle.free_processor();
				return -1;
			}
			m_routeMap[theObjID] = newHandle;
		}

	}
	else
	{
		//给已经存在的logicHandle
		HANDLE_ROUTE_MAP::iterator itroute = m_routeMap.find(handleID);
		if(itroute == m_routeMap.end())
		{
			LOG(LOG_ERROR, "cmd=0x%x handleID=%u route fail", msgCmd, handleID);
			return -1;
		}
		
		ret = itroute->second.on_active(msg);
		if(ret == CLogicProcessor::RET_DONE)
		{
			//逻辑结束释放对象
			itroute->second.on_finish();
			itroute->second.free_processor();
			//从表中删除
			m_routeMap.erase(itroute);
		}
	}

	return 0;
}


int CLogicHandleManager::CLogicRecoverVisitor::visit(void* p, int idx, unsigned int nodeSize)
{
	if(nodeSize <= sizeof(CLogicHandle::SHM_SAVE_CREATE_INFO))
	{
		LOG(LOG_ERROR, "CLogicRecoverVisitor nodesize=%u too small ", nodeSize);
		return CFixedsizeAllocator::CNodeVisitor::RET_DEL | CFixedsizeAllocator::CNodeVisitor::RET_CONTINUE;
	}
	
	CLogicHandle::SHM_SAVE_CREATE_INFO* pcreate = (CLogicHandle::SHM_SAVE_CREATE_INFO*)p;

	//查询注册表
	HANDLE_REG_MAP::iterator it = m_master->m_pregistMap->find(pcreate->savedMsgCmd);
	if(it == m_master->m_pregistMap->end())
	{
		LOG(LOG_ERROR, "CLogicRecoverVisitor obj(%u) cmd=%u not registed", 
			pcreate->savedHandleID, pcreate->savedMsgCmd);
		return CFixedsizeAllocator::CNodeVisitor::RET_DEL | CFixedsizeAllocator::CNodeVisitor::RET_CONTINUE;
	}

	//查询管理器，是否有冲突
	if(m_master->m_routeMap.find(pcreate->savedHandleID)!=m_master->m_routeMap.end())
	{
		LOG(LOG_ERROR, "obj(%u) cmd=%u id conflicts ...", pcreate->savedHandleID, pcreate->savedMsgCmd);
		return CFixedsizeAllocator::CNodeVisitor::RET_DEL | CFixedsizeAllocator::CNodeVisitor::RET_CONTINUE;
	}
	

	//创建对象
	CLogicHandle newHandle;
	int ret = it->second.create(newHandle, m_master->m_usepool);
	if(ret!= 0)
	{
		LOG(LOG_ERROR, "cmd=%u create handle fail", pcreate->savedMsgCmd);
		return CFixedsizeAllocator::CNodeVisitor::RET_DEL | CFixedsizeAllocator::CNodeVisitor::RET_CONTINUE;
	}

	//恢复数据
	ret = newHandle.recover_processor(p, nodeSize, m_master->m_ptoolkit, m_master->m_pallocator);
	if(ret!= 0)
	{
		LOG(LOG_ERROR, "cmd=%u recover_processor fail, size not right", pcreate->savedMsgCmd);
		return CFixedsizeAllocator::CNodeVisitor::RET_DEL | CFixedsizeAllocator::CNodeVisitor::RET_CONTINUE;
	}

	//插入管理器
	m_master->m_routeMap[pcreate->savedHandleID] = newHandle;

	//更新id生成器
	m_master->m_uid.set_used(pcreate->savedHandleID);

	return CFixedsizeAllocator::CNodeVisitor::RET_CONTINUE;
}

