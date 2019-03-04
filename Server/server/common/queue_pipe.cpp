#include "queue_pipe.h"


void PIPE_CONFIG_ITEM::debug(ostream& os)
{
	os << "PIPE_CONFIG_ITEM{" << endl;
	os << "shmkey_r|" << hex << shmkey_r << dec << endl;
	os << "dequesize_r|" << dequesize_r << endl;
	os << "shmkey_w|" <<  hex << shmkey_w << dec << endl;
	os << "dequesize_w|" << dequesize_w << endl;
	os << "activeLock|" << activeLock << endl;
	os << "passiveLock|" << passiveLock << endl;
	os << "}END PIPE_CONFIG_ITEM" << endl;
}


	int CPIPEConfigInfo::set_config(CIniFile& oIni)
	{
		PIPE_CONFIG_ITEM infoItem;
		int globeID;
		int totalNum = 0;
		oIni.GetInt("PIPE_HEAD", "TOTAL", 0, &totalNum);
	
		char sectorBuff[64]= {0};
		for(int i=0; i<totalNum; ++i)
		{
			snprintf(sectorBuff, sizeof(sectorBuff), "PIPE_%d", i);
	
			oIni.GetInt(sectorBuff, "PIPE_GLOBE_ID", 0, &globeID);
			oIni.GetInt(sectorBuff, "KEY_R", 0, &(infoItem.shmkey_r));
			oIni.GetInt(sectorBuff, "KEY_W", 0, &(infoItem.shmkey_w));
			oIni.GetInt(sectorBuff, "SIZE_R", 0, &(infoItem.dequesize_r));
			oIni.GetInt(sectorBuff, "SIZE_W", 0, &(infoItem.dequesize_w));
			oIni.GetInt(sectorBuff, "ACTIVE_LOCK", 0, &(infoItem.activeLock));
			oIni.GetInt(sectorBuff, "PASSIVE_LOCK", 0, &(infoItem.passiveLock));
	
			if(globeID==0 
				|| infoItem.shmkey_r==0
				|| infoItem.shmkey_w==0
				|| infoItem.dequesize_r==0
				|| infoItem.dequesize_w==0
			)
			{
				LOG(LOG_ERROR, "[%s] globeID=%d KEY_R=%d KEY_W=%d SIZE_R=%d SIZE_W=%d", sectorBuff,
					globeID, infoItem.shmkey_r, infoItem.shmkey_w, infoItem.dequesize_r, infoItem.dequesize_w);
				return -1;
			}
	
	
			pair<MAP_PIPE_CONFIG::iterator, bool> retPair = m_mapConfig.insert(make_pair(globeID, infoItem));
			if(!retPair.second)
			{
				LOG(LOG_ERROR, "[%s] globeID=%d exsit", sectorBuff, globeID);
				return -1;
			}
		}
	
		return 0;
	}
	
	int CPIPEConfigInfo::set_config(const char* iniFilePath)
	{
		CIniFile oIni(iniFilePath);
		if(!oIni.IsValid())
		{
			LOG(LOG_ERROR, "read ini %s fail", iniFilePath);
			return -1;
		}
	
		return set_config(oIni);
	}
	
	//isActive=ture read,write方向与配置一致，否则相反
	//semKey借用shmKey，activeLock和passiveLock控制是否要加锁，active用shmkey_r，passive用shmkey_w
	int CPIPEConfigInfo::get_config(int globeID, bool isActive, key_t &shmkey_r, unsigned int &dequesize_r, key_t &shmkey_w, unsigned int &dequesize_w, key_t& semKey)
	{
		MAP_PIPE_CONFIG::iterator it = m_mapConfig.find(globeID);
		if(it == m_mapConfig.end())
		{
			return -1;
		}
	
		if(isActive)
		{
			shmkey_r = it->second.shmkey_r;
			dequesize_r = it->second.dequesize_r;
			shmkey_w = it->second.shmkey_w;
			dequesize_w = it->second.dequesize_w;
	
			if(it->second.activeLock != 0)
			{
				semKey = it->second.shmkey_r;
			}
			else
			{
				semKey = 0;
			}
		}
		else
		{
			shmkey_r = it->second.shmkey_w;
			dequesize_r = it->second.dequesize_w;
			shmkey_w = it->second.shmkey_r;
			dequesize_w = it->second.dequesize_r;
	
			if(it->second.passiveLock != 0)
			{
				semKey = it->second.shmkey_w;
			}
			else
			{
				semKey = 0;
			}
		}
	
		return 0;
	}
	
	void CPIPEConfigInfo::debug(ostream& os)
	{
		for(MAP_PIPE_CONFIG::iterator it = m_mapConfig.begin();
			it != m_mapConfig.end(); ++it)
		{
			os << "[" << it->first << "]:"; 
			it->second.debug(os);
		}
	}

	CDequePIPE::CDequePIPE()
	{
		m_errmsg[0] = 0;
		m_recvcnt = 0;
		m_sendcnt = 0;
	}
	
	int CDequePIPE::init(CPIPEConfigInfo& config, unsigned int id, bool isActive)
	{
		key_t shmkey_r;
		unsigned int dequesize_r;
		key_t shmkey_w;
		unsigned int dequesize_w;
		key_t semLockKey;
	
		if(config.get_config(id, isActive, shmkey_r, dequesize_r, shmkey_w, dequesize_w, semLockKey) != 0)
		{
			snprintf(m_errmsg, sizeof(m_errmsg), "get_config for %u fail", id);
			return -1;
		}
	
		return init(shmkey_r, dequesize_r, shmkey_w, dequesize_w, &semLockKey);
	}
	
	int CDequePIPE::init(key_t shmkey_r, unsigned int dequesize_r, key_t shmkey_w, unsigned int dequesize_w, key_t* psemLockKey )
	{
		if(psemLockKey && *psemLockKey != 0)
		{
			if(m_lock.init(*psemLockKey) != 0)
			{
				snprintf(m_errmsg, sizeof(m_errmsg), "m_lock.Init(0x%X) %s", *psemLockKey, m_lock.errmsg());
				return -1;
			}
	
			m_deque_r.set_lock(&m_lock);
			m_deque_w.set_lock(&m_lock);
		}
		
		if(init_one_side(m_shm_r, m_deque_r, shmkey_r, dequesize_r) != 0)
			return -1;
	
		if(init_one_side(m_shm_w, m_deque_w, shmkey_w, dequesize_w) != 0)
			return -1;
		
		return 0;
	}
	
	int CDequePIPE::init_one_side(CShmWrapper& shm, CDeque& deque, key_t shmkey, unsigned int dequesize)
	{
		bool brestore = false;
		unsigned int shmsize = CDeque::getallocsize(dequesize);
		int ret = shm.get(shmkey, shmsize);
		if(ret == CShmWrapper::SUCCESS)
		{
			brestore = false;
		}
		else if(ret == CShmWrapper::SHM_EXIST)
		{
			if((unsigned int)(shm.get_shm_size()) != shmsize)
			{
				snprintf(m_errmsg, sizeof(m_errmsg), "key=%u exist shm size not %u", shmkey, shmsize);
				return -1;
			}
			
			brestore = true;
		}
		else
		{
			snprintf(m_errmsg, sizeof(m_errmsg), "CShmWrapper %s", shm.errmsg());
			return -1;
		}
	
		ret = deque.initialize((char*)(shm.get_mem()), shmsize, dequesize, brestore);
		if(ret < 0)
		{
			snprintf(m_errmsg, sizeof(m_errmsg), "deque.initialize(shmpoint, %u,%u,%d) = %d", shmsize, dequesize, brestore, ret);
			return -1;
		}
	
		return 0;
	}

