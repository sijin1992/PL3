#include "driver.h"

#define DRIVER_INFO_LOG_CNT 10000

bool CCmdFilter::check(unsigned int cmd, unsigned int queueID)
{
	bool ret = true;
	//allow优先
	CMD_QUEUEID_MAP::iterator it = m_allowMap.find(cmd);
	if(it != m_allowMap.end())
	{
		//在allow中的check ok
		ret = false;
		for(unsigned int i=0; i< it->second->size(); ++i)
		{
			if( queueID == (*(it->second))[i])
			{
				ret = true;
				break;
			}
		}
	}
	else
	{
		//尝试deny，不在deny中的check ok
		it = m_denyMap.find(cmd);
		if(it != m_denyMap.end())
		{
			for(unsigned int i=0; i< it->second->size(); ++i)
			{
				if( queueID == (*(it->second))[i])
				{
					ret = false;
					break;
				}
			}
		}
	}

	return ret;
}

CCmdFilter::~CCmdFilter()
{
	CMD_QUEUEID_MAP::iterator it;
	for(it = m_allowMap.begin(); it != m_allowMap.end(); ++it)
	{
		if(it->second != NULL)
		{
			delete it->second;
			it->second = NULL;
		}
	}
	
	for(it = m_denyMap.begin(); it != m_denyMap.end(); ++it)
	{
		if(it->second != NULL)
		{
			delete it->second;
			it->second = NULL;
		}
	}
}

CLogicDriverConfig::CLogicDriverConfig()
{
	saveLogicInMsa = false;
	msaKey = 0;
	msaSize = 0;
	msaBlocksize = 0;
	useTimer = false;
	timerKey = 0;
	timerMaxNum = 0;
	useObjPool = false;
	readMsgNumInLoop = 100;
	atWhichServer = 0;
	useSuperCreator = false;
	logReportQueueID = 0;
}

int CLogicDriverConfig::readFromIni(const char* file, const char* sector)
{
	CIniFile oIni(file);
	if(!oIni.IsValid())
	{
		LOG(LOG_ERROR, "%s not valid", file);
		return -1;
	}
	
	return readFromIni(oIni, sector);
}

int CLogicDriverConfig::readFromIni(CIniFile& oIni, const char* sector)
{
	int saveLogic = 0;
	oIni.GetInt(sector, "SAVE_LOGIC_IN_SHM", 0, &saveLogic);
	if(saveLogic == 0)
	{
		saveLogic = false;
	}
	else
	{
		saveLogic = true;
		if(oIni.GetInt(sector, "LOGIC_SHM_KEY", 0, &msaKey)!= 0)
		{
			LOG(LOG_ERROR, "%s.LOGIC_SHM_KEY not found", sector);
			return -1;
		}

		if(oIni.GetInt(sector, "LOGIC_SHM_SIZE", 0, &msaSize)!= 0)
		{
			LOG(LOG_ERROR, "%s.LOGIC_SHM_SIZE not found", sector);
			return -1;
		}

		if(oIni.GetInt(sector, "LOGIC_SHM_BLOCK_SIZE", 0, &msaBlocksize)!= 0)
		{
			LOG(LOG_ERROR, "%s.LOGIC_SHM_BLOCK_SIZE not found", sector);
			return -1;
		}
	}

	int timer = 0;
	oIni.GetInt(sector, "USE_TIMER", 0, &timer);
	if(timer == 0)
	{
		useTimer = false;
	}
	else
	{
		useTimer = true;
		if(oIni.GetInt(sector, "TIMER_SHM_KEY", 0, &timerKey)!= 0)
		{
			LOG(LOG_ERROR, "%s.TIMER_SHM_KEY not found", sector);
			return -1;
		}

		if(oIni.GetInt(sector, "TIMER_MAX_NUM", 0, &timerMaxNum)!= 0)
		{
			LOG(LOG_ERROR, "%s.TIMER_MAX_NUM not found", sector);
			return -1;
		}
	}

	int usePool;
	oIni.GetInt(sector, "USE_OBJ_POOL", 0, &usePool);
	if(usePool == 0)
	{
		useObjPool = false;
	}
	else
	{
		useObjPool = true;
	}

	int superCreator;
	oIni.GetInt(sector, "USE_SUPER_CREATOR", 0, &superCreator);
	if(superCreator == 0)
	{
		useSuperCreator = false;
	}
	else
	{
		useSuperCreator = true;
	}

	oIni.GetInt(sector, "READ_MSG_NUM_PERLOOP", 100, &readMsgNumInLoop);

	char svrBuff[32]={0};
	if(oIni.GetString(sector, "SERVER_ID", "", svrBuff, sizeof(svrBuff))!=0)
	{
		LOG(LOG_ERROR, "%s.SERVER_ID not found", sector);
		return -1;
	}

	if(CTcpSocket::str_to_addr(svrBuff, atWhichServer) != 0)
	{
		LOG(LOG_ERROR, "%s.SERVER_ID(%s) not valid", sector, svrBuff);
		return -1;
	}

	oIni.GetInt(sector, "LOG_REPORT_QUEUE_ID", 0, &logReportQueueID);

	oIni.GetInt(sector, "LOG_REPORT_SVR_ID", 0, &logReportSvrID);

	return 0;

}

CLogicDriver::CLogicDriver()
{
	stopFlag = 0;
	m_ptimer = NULL;
	m_pmanager = NULL;
	m_readMsgNumInLoop = 0;
	m_inited = false;
	m_useSuper = false;
	m_delTimerMem = NULL;
	m_msgcnt = 0;
	m_timermsgcnt = 0;
}

CLogicDriver::~CLogicDriver()
{
	if(m_ptimer != NULL)
	{
		delete m_ptimer;
		m_ptimer = NULL;
	}

	if(m_delTimerMem != NULL)
	{
		delete m_delTimerMem;
		m_delTimerMem = NULL;
	}

	if(m_pmanager != NULL)
	{
		delete m_pmanager;
		m_pmanager = NULL;
	}	if(m_logPipeWriter != NULL)	{		delete m_logPipeWriter;		m_logPipeWriter = NULL;		LOG_SET_WRITER_PROXY(NULL);	}
}

int CLogicDriver::set_super_creator(CLogicMsg& msg, CLogicCreator& superCreator)
{
	return -1;
}

int CLogicDriver::hook_loop_end()
{
	return 0;
}

int CLogicDriver::init(CLogicDriverConfig& config)
{
	if(m_inited)
	{
		LOG(LOG_ERROR, "has been intied");
		return -1;
	}
	
	//设置server id
	m_serverID = config.atWhichServer;
	LOG(LOG_INFO, "bind server id [%s]", CTcpSocket::addr_to_str(m_serverID).c_str());
	
	m_useSuper = config.useSuperCreator;
	if(m_useSuper)
		LOG(LOG_INFO, "allow super creator");
	//初始化管理器
	m_pmanager = new CLogicHandleManager(&m_toolkit, config.useObjPool, &m_theRegMap);
	if(m_pmanager == NULL)
	{
		LOG(LOG_ERROR, "new CLogicHandleManager fail");
		return -1;
	}

	int ret = 0;
	if(config.saveLogicInMsa)
	{
		ret = m_pmanager->init_allcator(config.msaKey, config.msaSize, config.msaBlocksize);
		if(ret !=0)
		{
			return -1;
		}
		LOG(LOG_INFO, "saveLogicInMsa true");
	}
	else
	{
		LOG(LOG_INFO, "saveLogicInMsa false");
	}

	//初始化timer
	if(config.useTimer)
	{
		unsigned int memSize = CTimerPool<DRIVER_TIMER_DATA>::mem_size(config.timerMaxNum);
		char* memstart;
		if(config.timerKey == 0)
		{
			memstart = new char[memSize];
			if(memstart == NULL)
			{
				LOG(LOG_ERROR, "new timerbuff size=%d fail", memSize);
				return -1;
			}
			m_delTimerMem = memstart;
		}
		else
		{
			ret = m_timershm.get(config.timerKey,memSize);
			if(ret == CShmWrapper::ERROR)
			{
				LOG(LOG_ERROR, "m_timershm init %s", m_timershm.errmsg());
				return -1;
			}
			
			memstart = (char*)(m_timershm.get_mem());
			if(memSize != m_timershm.get_shm_size())
			{
				LOG(LOG_ERROR, "size not right");
				return -1;
			}
		}
		
		m_ptimer = new CTimerPool<DRIVER_TIMER_DATA>(memstart, memSize, config.timerMaxNum);
		if(m_ptimer == NULL)
		{
			LOG(LOG_ERROR, "new CTimerPool fail");
			return -1;
		}
		
		if(!m_ptimer->valid())
		{
			LOG(LOG_ERROR, "timer not valid %s", m_ptimer->m_err.errstrmsg);
			return -1;
		}

		LOG(LOG_INFO, "useTimer formated=%d", m_ptimer->formated());

		//m_ptimer->debug(cout);
	}
	else
	{
		LOG(LOG_INFO, "useTimer false");
	}

	//初始化toolkit
	m_toolkit.init(m_ptimer,&m_queuemap,m_serverID);

	if( config.logReportQueueID != 0 && config.logReportSvrID != 0 )
	{
		m_logPipeWriter = new CLogPipeWriter(m_toolkit, config.logReportQueueID, config.logReportSvrID);
		LOG_SET_WRITER_PROXY(m_logPipeWriter);
	}

	m_readMsgNumInLoop = config.readMsgNumInLoop;

	m_inited = true;
	
	return 0;
}

int CLogicDriver::add_msg_queue(unsigned int id, CMsgQueue* pqueue)
{
	if(id <= CLogicMsg::QUEUE_ID_FOR_TIMER)
	{
		LOG(LOG_ERROR, "queue id(%u) is for timer", id);
		return -1;
	}
	
	pqueue->id = id;
	if(m_queuemap.find(id) != m_queuemap.end())
	{
		LOG(LOG_ERROR, "queue id=%u exsit", id);
		return -1;
	}

	cout << "add queue " << id << endl;
	LOG(LOG_INFO, "add queue=%u", id);

	m_queuemap[id] = pqueue;
	return 0;
}

int CLogicDriver::regist_handle(unsigned int msgCmd, CLogicCreator creator)
{
	if(m_inited)
	{
		cout << "please do regist_handle before init" << endl;
		LOG(LOG_ERROR, "regist_handle must before init");
		return -1;
	}

	//不允许重复
	if(m_theRegMap.find(msgCmd) != m_theRegMap.end())
	{
		cout << "cmd=0x" << hex << msgCmd<<  dec<<" has been registed"	<< endl;
		LOG(LOG_ERROR, "cmd=0x%x has been registed", msgCmd);
		return -1;
	}
	m_theRegMap[msgCmd] = creator;

	cout << "regist cmd=0x" << hex << msgCmd << dec<< endl;
	LOG(LOG_INFO, "regist cmd=0x%x", msgCmd);

	return 0;
}

int CLogicDriver::main_loop(int loopNum)
{
	if(!m_inited)
	{
		LOG(LOG_ERROR, "main_loop() not inited");
		return -1;
	}

	LOG(LOG_INFO, "main_loop() start with loopNum(%d)", loopNum);
	
	MSG_QUEUE_MAP::iterator it;
	vector<unsigned int> vtimerID;
	vector<DRIVER_TIMER_DATA> vtimerData;
	vtimerID.reserve(1000);
	vtimerData.reserve(1000);
	int ret = 0;
	int msgi = 0;
	while(!stopFlag)
	{
		if(loopNum >=0 && --loopNum <= 0)
		{
			break;
		}
		
		//从m_queuemap中遍历取消息
		for(it=m_queuemap.begin(); it!=m_queuemap.end(); ++it)
		{
			CLogicMsg msg(m_toolkit.readBuff, m_toolkit.BUFFLEN);
			unsigned int i=0;
			for(i=0; i<m_readMsgNumInLoop; ++i)
			{
				ret = it->second->get_msg(msg);
				if(ret == CMsgQueue::EMPTY)
				{
					break;
				}
				else if(ret == CMsgQueue::OK)
				{
					++m_msgcnt;
					++msgi;
					unsigned int cmd = m_toolkit.get_cmd(msg);
					if(!m_cmdFilter.check(cmd,	it->second->id))
					{
						LOG(LOG_ERROR, "m_cmdFilter.check(%u, %u) false", cmd, it->second->id);
						continue;
					}
					
					if(m_useSuper && set_super_creator(msg, m_theSuper)==0)
						ret = m_pmanager->process_msg(msg, &m_theSuper);
					else
						ret = m_pmanager->process_msg(msg);
					if(ret != 0)
					{
					}
				}
				else
				{
					break;
				}
			}
			m_sleep.work(i);
		}
		
		//如果有timer从timer中取消息
		if(m_ptimer)
		{
			ret = m_ptimer->check_timer(vtimerID, vtimerData);
			if(ret != 0)
			{
				LOG(LOG_ERROR, "check_timer %d %s", m_ptimer->m_err.errcode, m_ptimer->m_err.errstrmsg);
			}
			else
			{
				unsigned int j=0;
				for(j=0; j<vtimerID.size(); ++j)
				{
					++m_timermsgcnt;
					++msgi;
					CLogicMsg msg(m_toolkit.readBuff, m_toolkit.BUFFLEN);
					msg.head()->queueID = CLogicMsg::QUEUE_ID_FOR_TIMER;
					msg.head()->desHandleID = vtimerData[j].handleID;
					msg.head()->srcHandleID = vtimerID[j];
					msg.head()->srcServerID = m_serverID;
					msg.head()->desServerID = m_serverID;
					msg.head()->cmdID = vtimerData[j].msgCmd;
					msg.head()->bodySize = sizeof(vtimerData[j].userFlag);
					memcpy(msg.body(), &(vtimerData[j].userFlag), sizeof(vtimerData[j].userFlag));

					if(m_useSuper && set_super_creator(msg, m_theSuper)==0)
						ret = m_pmanager->process_msg(msg, &m_theSuper);
					else
						ret = m_pmanager->process_msg(msg);
					if(ret != 0)
					{
					}
				}
				m_sleep.work(j);
			}
		}

		ret = hook_loop_end();
		if(ret > 0)
			m_sleep.work(ret);
		//sleep or not
		m_sleep.sleep();

		if(msgi > DRIVER_INFO_LOG_CNT)
		{
			LOG(LOG_INFO, "DRIVER|msgcnt=%lu|timermsgcnt=%lu", m_msgcnt, m_timermsgcnt);
			msgi -= DRIVER_INFO_LOG_CNT;
		}
	}

	LOG(LOG_INFO, "main_loop stoped");

	return 0;
}


