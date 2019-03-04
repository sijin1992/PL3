#include "online_cache.h"
#include "logic_info.h"

extern CShmTimer<unsigned int> gTheTimer;

ONLINE_CACHE_UNIT::ONLINE_CACHE_UNIT()
{
	userState = 0;
	loginTime = 0;
	lastActiveTime = 0;
}

void ONLINE_CACHE_UNIT::debug(ostream& os)
{
	time_t tmp;
	os << "ONLINE_CACHE_UNIT{" << endl;
	os << "userState|" << userState << endl;
	tmp = loginTime;
	os << "loginTime|" << loginTime << "|" << ctime(&tmp) << endl;
	tmp = lastActiveTime;
	os << "lastActiveTime|" << lastActiveTime << "|" << ctime(&tmp) << endl;
	os << "selfCheckTimerID|" << selfCheckTimerID << endl;
	os << "userip|" << userip << endl;
	os << "userdomain|" << userdomain << endl;
	os << "userkey|" << userkey << endl;
	os << "}END ONLINE_CACHE_UNIT" << endl;
}

int ONLINE_CACHE_CONFIG::read_from_ini(CIniFile& oIni, const char* sector)
{
	if(oIni.GetInt(sector, "SHM_KEY", 0, &shmKey)!= 0)
	{
		LOG(LOG_ERROR, "%s.SHM_KEY not found", sector);
		return -1;
	}

	if(oIni.GetInt(sector, "TIMER_KEY", 0, &timershmkey)!= 0)
	{
		LOG(LOG_ERROR, "%s.TIMER_KEY not found", sector);
		return -1;
	}
	
	if(oIni.GetInt(sector, "USER_NUM", 0, &nodeNum)!= 0)
	{
		LOG(LOG_ERROR, "%s.USER_NUM not found", sector);
		return -1;
	}

	if(oIni.GetInt(sector, "TIMER_NUM", 0, &timerNum)!= 0)
	{
		LOG(LOG_ERROR, "%s.TIMER_NUM not found", sector);
		return -1;
	}
	
	if(oIni.GetInt(sector, "HASH_NUM", 0, &hashNum)!= 0)
	{
		LOG(LOG_ERROR, "%s.HASH_NUM not found", sector);
		return -1;
	}

	return 0;
}

void ONLINE_CACHE_CONFIG::debug(ostream& os)
{
	os << "ONLINE_CACHE_CONFIG{" << endl;
	os << "shmKey|" << hex << shmKey << dec << endl;
	os << "timershmkey|" << hex << timershmkey << dec << endl;
	os << "nodeNum|" << nodeNum << endl;
	os << "hashNum|" << hashNum << endl;
	os << "timerNum|" << timerNum << endl;
	os << "}END ONLINE_CACHE_CONFIG" << endl;
}

COnlineCache::COnlineCache()
{
	m_pmap = NULL;
	m_inited = false;
}

COnlineCache::~COnlineCache()
{
	if(m_pmap)
	{
		delete m_pmap;
		m_pmap = NULL;
	}
}

void COnlineCache::info(ostream& os)
{

	if(!m_inited)
	{
		os << "not inited" << endl;
		return;
	}

	m_pmap->get_head()->debug(os);
}

int COnlineCache::onlineNum()
{
	if(m_inited)
	{
		return m_pmap->get_head()->curNodeNum;
	}

	return 0;
}

int COnlineCache::init(ONLINE_CACHE_CONFIG& config)
{
	bool format = false;
	size_t memSize = ONLINE_CACHE_MAP::mem_size(config.nodeNum,config.hashNum);
	int ret = m_shm.get(config.shmKey, memSize);
	if(ret == m_shm.SHM_EXIST)
	{
		if(m_shm.get_shm_size() != memSize)
		{
			LOG(LOG_INFO, "getshm(key=0x%x) size not %lu formated", config.shmKey, memSize);
			if(m_shm.remove(config.shmKey)!=m_shm.SUCCESS)
			{
				LOG(LOG_ERROR, "remove(key=0x%x) fail", config.shmKey);
				return -1;
			}

			ret = m_shm.get(config.shmKey, memSize);
			format = true;
		}
	}
	else if(ret == m_shm.SUCCESS)
	{
		format = true;
	}

	if(ret == m_shm.ERROR)
	{
		LOG(LOG_ERROR, "getshm(key=%u) %s", config.shmKey, m_shm.errmsg());
		return -1;
	}

	void* memStart = m_shm.get_mem();

	if(format)
	{
		ONLINE_CACHE_MAP::clear(memStart);
	}
	
	m_pmap = new ONLINE_CACHE_MAP (memStart, memSize, config.nodeNum,config.hashNum);
	if(!m_pmap)
	{
		LOG(LOG_ERROR, "new ONLINE_CACHE_MAP fail");
		return -1;
	}

	if(!(m_pmap->valid()))
	{
		LOG(LOG_ERROR, "ONLINE_CACHE_MAP not valid %d %s", m_pmap->m_err.errcode, m_pmap->m_err.errstrmsg);
		return -1;
	}
	
	m_inited = true;
	return 0;
}

int COnlineCache::onLogin(int phase, USER_NAME& user, CToolkit* ptoolkit, int checkinterval, int level,
	unsigned int auserip, const string& auserkey, const string &auserdamain, const string &account)
{
	if(!m_inited)
	{
		LOG(LOG_ERROR, "%s|getOnlineUnit not inited", user.str());
		return -1;
	}
	if(phase == 0 || phase == 2)//正常登录or 注册完毕
	{
		unsigned int theIdx;
		int ret = m_pmap->get_node_idx(user, theIdx);
		if(ret < 0)
		{
			LOG(LOG_ERROR, "%s|COnlineCache get_node_idx %d %s", user.str(), m_pmap->m_err.errcode, m_pmap->m_err.errstrmsg);
			return -1;
		}
		else if(ret == 1)
		{
			ONLINE_CACHE_UNIT* pval = m_pmap->get_val_pointer(theIdx);
			pval->active();
			if(phase == 0)
			{
				LOG(LOG_DEBUG, "%s|COnlineCache LOGIN already online",user.str());
			}
			else
			{
				//修改状态
				pval->userState = ONLINE_CACHE_UNIT_STATE_LOGINOK;
			}
			
			if(pval->selfCheckTimerID != 0)
			{
				gTheTimer.get_timer()->del_timer(pval->selfCheckTimerID);
			}
			if(gTheTimer.get_timer()->set_timer_s(pval->selfCheckTimerID, theIdx, checkinterval)!=0)
			{
				LOG(LOG_ERROR, "%s|online reset timer fail: %s", user.str(), gTheTimer.get_timer()->m_err.errstrmsg);
				onLogout(user, NULL); //回滚
				return -1;
			}
			
		}
		else
		{
			/*if(phase == 2)
			{
				LOG(LOG_ERROR, "%s|onLogin for regist should has onlineunit", user.str());
				return -1;
			}*/
			if(m_pmap->get_head()->curNodeNum >= (unsigned int)g_logic_info.max_client)
				return -2;
			ONLINE_CACHE_UNIT newUnit;
			newUnit.on_login(ONLINE_CACHE_UNIT_STATE_LOGINOK, auserip, auserkey, auserdamain, account);
			ret = m_pmap->set_node(user, newUnit);
			if(ret < 0)
			{
				LOG(LOG_ERROR, "%s|COnlineCache set_node %d %s", user.str(), m_pmap->m_err.errcode, m_pmap->m_err.errstrmsg);
				return -1;
			}
		
			//定时检查在线
			unsigned int theIdx;
			ONLINE_CACHE_UNIT* punit;
			
			if(getOnlineRef(user, theIdx, punit)!=0)
			{
				return -1;
			}
		
			if(gTheTimer.get_timer()->set_timer_s(punit->selfCheckTimerID, theIdx, checkinterval)!=0)
			{
				LOG(LOG_ERROR, "%s|online set timer fail: %s", user.str(), gTheTimer.get_timer()->m_err.errstrmsg);
				onLogout(user, NULL); //回滚
				return -1;
			}
		}
	}
	else if(phase == 1) //没有数据
	{
		if(m_pmap->get_head()->curNodeNum >= (unsigned int)g_logic_info.max_client)
			return -2;
		ONLINE_CACHE_UNIT newUnit;
		newUnit.on_login(ONLINE_CACHE_UNIT_STATE_NO_DATA, auserip, auserkey, auserdamain, account);
		int ret = m_pmap->set_node(user, newUnit);
		if(ret < 0)
		{
			LOG(LOG_ERROR, "%s|COnlineCache set_node %d %s", user.str(), m_pmap->m_err.errcode, m_pmap->m_err.errstrmsg);
			return -1;
		}
	}
	else
	{
		LOG(LOG_ERROR, "%s|onLogin invalid phase=%d", user.str(), phase);
		return -1;
	}
	return 0;
};

int COnlineCache::onLogout(USER_NAME & user, CToolkit* ptoolkit)
{
	if(!m_inited)
	{
		LOG(LOG_ERROR, "%s|getOnlineUnit not inited", user.str());
		return -1;
	}

	ONLINE_CACHE_UNIT old;
	int ret = m_pmap->del_node(user, &old);
	if(ret < 0)
	{
		LOG(LOG_ERROR, "%s|COnlineCache del_node %d %s", user.str(), m_pmap->m_err.errcode, m_pmap->m_err.errstrmsg);
		return -1;
	}

	if(old.selfCheckTimerID != 0)
	{
		gTheTimer.get_timer()->del_timer(old.selfCheckTimerID);
		old.selfCheckTimerID = 0;
	}
	LOG_STAT_LOGOUT(user.str(), time(NULL) - (time_t)(old.loginTime), old.user_account);
	return 0;
}

//0=ok -1=fail
//确保已经在线的情况下调用，不在线也是错误
int COnlineCache::getOnlineRef(USER_NAME & user, unsigned int& theIdx, ONLINE_CACHE_UNIT*& punit)
{
	if(!m_inited)
	{
		LOG(LOG_ERROR, "%s|getOnlineRef not inited", user.str());
		return -1;
	}

	if(m_pmap->get_node_idx(user, theIdx)!= 1)
	{
		//LOG(LOG_ERROR, "%s|getOnlineRef fail", user.str());
		return -1;
	}

	punit = m_pmap->get_val_pointer(theIdx);
	
	return 0;
}

//0=ok -1=fail
//使用theIdx还原信息
int COnlineCache::checkRef(unsigned int theIdx, int timeout, USER_NAME & user, ONLINE_CACHE_UNIT*& punit)
{
	if(!m_inited)
	{
		LOG(LOG_ERROR, "%s|checkRef not inited", user.str());
		return -1;
	}

	user = *(m_pmap->get_key_pointer(theIdx));
	punit = m_pmap->get_val_pointer(theIdx);

	//check
	unsigned int theCheckIdx;
	if(m_pmap->get_node_idx(user, theCheckIdx)!= 1)
	{
		LOG(LOG_ERROR, "%s|checkRef fail",  user.str());
		return -1;
	}

	if(theCheckIdx != theIdx)
	{
		LOG(LOG_ERROR, "%s|checkRef theIdx(%u)!=theCheckIdx(%u)", user.str(), theIdx, theCheckIdx);
		return -1;
	}

	//看看是否
	return punit->isActive(timeout);
}

//0=ok -1=fail
//punit = NULL not online, 调用此命令将更新活跃时间
int COnlineCache::getOnlineUnit(USER_NAME & user, ONLINE_CACHE_UNIT*& punit)
{
	if(!m_inited)
	{
		LOG(LOG_ERROR, "%s|getOnlineUnit not inited", user.str() );
		return -1;
	}
	
	punit = NULL;
	unsigned int theIdx;
	int ret = m_pmap->get_node_idx(user, theIdx);
	if(ret < 0)
	{
		LOG(LOG_ERROR, "%s|COnlineCache get_node_idx %d %s", user.str(), m_pmap->m_err.errcode, m_pmap->m_err.errstrmsg);
		return -1;
	}
	else if(ret == 1)
	{
		punit = m_pmap->get_val_pointer(theIdx);
		punit->active();
	}

	return 0;
}

class COnlineCacheMapVisitor: public CHashMapVisitor<USER_NAME, ONLINE_CACHE_UNIT>
{
public:
	COnlineCacheMapVisitor()
	{
		m_count = 0;
	}
	virtual ~COnlineCacheMapVisitor(){}
	virtual int call(const USER_NAME& key, ONLINE_CACHE_UNIT& val, int callTimes) 
	{
		if(val.isActive(TIMEOUT)!=0)
		{
			//除掉
			shouldDelete = true;
			if(val.selfCheckTimerID > 0)
				gTheTimer.get_timer()->del_timer(val.selfCheckTimerID);
			++m_count;
		}

		return 0;
	}
public:
	int TIMEOUT;
	int m_count;
};

int COnlineCache::cleanTimeoutNode(int timeout)
{	
	if(!m_inited)
		return -1;
	COnlineCacheMapVisitor visitor;
	visitor.TIMEOUT = timeout;
	m_pmap->for_each_node(&visitor);
	LOG(LOG_INFO,"ONLINE_CACHE_TIMEOUT|count=%d", visitor.m_count);
	return 0;
}
