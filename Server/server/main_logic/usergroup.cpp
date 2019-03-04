#include "../../libsrc/time/time_util.h"
#include "../../libsrc/random/random.h"
#include "usergroup.h"
#include "common/user_distribute.h"
#include "log/log.h"
#include "logic/handle.h"
#include "string/strutil.h"

extern CUserDistribute gDistribute; 
extern unsigned int TIMEOUT_FOR_DB;
extern int gDebugFlag;
extern unsigned int MSG_QUEUE_ID_DB;
/*
bool CLogicUserGroupHelper::updateUserGroupCache(const UserGroupData* pdata, UserGroupCache* pcache)
{
	struct tm tm;
	time_t nowtime = time(NULL);
	localtime_r(&nowtime, &tm);
	int day = (tm.tm_year-110)*1000 + tm.tm_yday;

	int lastday = 0;
	if(pcache->timestamp() > 0)
	{
		time_t lasttime = pcache->timestamp();
		localtime_r(&lasttime, &tm);
		lastday = (tm.tm_year-110)*1000 + tm.tm_yday;
	}

	UserGroupFightData *pfight = pcache->mutable_fight();
	int freetimes= 0;
	int paytimes=0;
		
	CConfItemgroupskill* pconf = getSkillConf(pdata, 5);
	if(pconf)
	{
		freetimes = pconf->Parameters1;
		paytimes = pconf->Parameters2;
	}
	
	pfight->set_maxfreetimes(freetimes);
	pfight->set_maxpaytimes(paytimes);
	
	if(day != lastday)
	{
		pfight->set_opentimes(0);
		pfight->set_nowlevel(0);
		pfight->set_paytimes(0);
		
		pcache->clear_giftflag();
		pcache->clear_resourceflag();
		pcache->set_timestamp(nowtime);
		return true;
	}

	return false;
}

void CLogicUserGroupHelper::syncGroupCache(UserGroupCache* pcache, const UserGroupData& data)
{
	pcache->mutable_keydata()->CopyFrom(data.keydata());
	pcache->mutable_skills()->CopyFrom(data.skills());
	pcache->set_level(data.level());
}

bool CLogicUserGroupHelper::groupDataValid(const UserGroupData& data)
{
	return !(data.state()!= 0 || data.keydata().version() != data.keydata().version());
}

void CLogicUserGroupHelper::disableGroupData(UserGroupData* pdata)
{	
	pdata->set_state(1);
	pdata->clear_joinreqs();
	pdata->clear_records();
}

bool CLogicUserGroupHelper::createGroupData(UserGroupData* pdata, UserGroupCache* pcache, USER_NAME& user)
{
	int version;
	if(pdata->state()==1)
	{
		version = pdata->keydata().version()+1;
	}
	else if(!pdata->has_keydata())
	{
		version = 1;
	}
	else
	{
		LOG(LOG_ERROR, "%s|create group on valid key(%s)", user.str(), pdata->keydata().groupid().c_str());
		return false;
	}

	pdata->Clear();
	UserGroupKeyData* pkeydata = pdata->mutable_keydata();
	pkeydata->set_version(version);
	pkeydata->set_groupid(user.to_str()); //如果后台不使用user做key，返回的值会覆盖之
	pdata->set_expr(0);
	pdata->set_level(1);
	pdata->set_master(user.to_str());
	pdata->add_users(user.to_str());
	
	//修改自己的数据
	clearGroup(pcache);
	syncGroupCache(pcache, *pdata);
	updateUserGroupCache(pdata, pcache);
	pcache->set_ismaster(1);

	// 初始化工会BOSS信息
	bool bagmodify = false;
	if (0 != initFightBossInfo(pdata, bagmodify, true, time(NULL)))
	{
		LOG(LOG_ERROR, "%s", "initFightBossInfo error");
		return false;
	}

	return true;
}

bool CLogicUserGroupHelper::trySyncGroupCache(UserGroupCache* pcache, const UserGroupData& data)
{
	bool bmodified = false;
	
	if(pcache->skills_size() != data.skills_size())
	{
		pcache->clear_skills();
		pcache->mutable_skills()->CopyFrom(data.skills());
		bmodified = true;
	}
	else
	{
		for(int i=0; i<pcache->skills_size(); ++i)
		{
			if(pcache->skills(i) != data.skills(i))
			{
				pcache->clear_skills();
				pcache->mutable_skills()->CopyFrom(data.skills());
				bmodified = true;
				break;
			}
		}
	}
	
	if(pcache->level() != data.level())
	{
		pcache->set_level(data.level());
		bmodified = true;
	}

	if (false == pcache->has_groupname() ||
		(true == pcache->has_groupname() && pcache->groupname() != data.name()))
	{
		pcache->set_groupname(data.name());
		bmodified = true;
	} 

	return bmodified;
}

bool CLogicUserGroupHelper::hasGroup(const UserData& userdata)
{
	if(userdata.has_usergroup() && userdata.usergroup().has_keydata())
	{
		return true;
	}

	return false;
}

void CLogicUserGroupHelper::clearGroup(UserGroupCache* pcache)
{	
	pcache->clear_keydata();
	pcache->clear_joingroupid();
	pcache->clear_ismaster();
	pcache->clear_isvicemaster();
	pcache->clear_level();
	pcache->clear_skills();
	pcache->mutable_fight()->set_nowlevel(0);
	pcache->mutable_fight()->set_paytimes(0);
	pcache->set_score(0);
	pcache->set_newscore(0);

	pcache->clear_defendtime();
	pcache->clear_attacktime();
	pcache->clear_attendtime();
	pcache->clear_attendinfo();
	pcache->clear_defendflag();
	pcache->clear_groupname();
	pcache->clear_resourceflag();
	pcache->clear_defendtimelinux();

	updateUserGroupCache(NULL, pcache);
}

bool CLogicUserGroupHelper::isGroupFull(UserGroupData* pdata)
{
	bool ret = false;
	CConfItemgrouplevelup* pconf = gAllConf.confgrouplevelup.get_conf(pdata->level());
	if(pconf == NULL)
		return true;
	
	if(pdata->users_size() >= pconf->Population)
	{
		ret = true;
	}
	
	return ret;
}

bool CLogicUserGroupHelper::isGroupReqFull(UserGroupData* pdata)
{
	bool ret = false;
	
	if(pdata->joinreqs_size() >= 300)
	{
		ret = true;
	}
	
	return ret;
}
*/
int CLogicUserGroupHelper::on_resp(unsigned int cmd, CLogicMsg& msg)
{
	if(!m_inited)
	{
		LOG(LOG_ERROR, "not inited");
		return CLogicProcessor::RET_DONE;
	}

	if(cmd == CMD_DBCACHE_GET_USERGROUP_RESP)
	{
		return on_get(msg);
	}
	else if(cmd == CMD_DBCACHE_SET_USERGROUP_RESP || CMD_DBCACHE_CREATE_USERGROUP_RESP)
	{
		return on_set(msg);
	}
	else if(cmd == CMD_DBCACHE_TIMEOUT_USERGROUP_RESP)
	{
		LOG(LOG_ERROR, "%s|timeout state=%d", m_loguser.str(), m_state);
		return m_phook->hook_on_state(HOOK_RET_TIMEOUT, m_state, NULL);
	}
	else
	{
		LOG(LOG_ERROR, "%s|cmd=0x%x not valid", m_loguser.str(),cmd);
		return m_phook->hook_on_state(HOOK_RET_INNER_FAIL, m_state, NULL);
	}
}

CLogicUserGroupHelper::CLogicUserGroupHelper()
{
	m_inited = false;
}

CLogicUserGroupHelper::~CLogicUserGroupHelper()
{
	if(m_inited && m_locked != 0)
	{
		unlock(true);
	}
}

int CLogicUserGroupHelper::init(CLogicUserGroupHook* phook, CToolkit* ptoolkit, USER_NAME& loguser, string groupid, unsigned int handleid)
{
	if(m_inited)
		return -1;
	m_inited = true;
	m_phook = phook;
	m_ptoolkit = ptoolkit;
	m_state = STATE_INIT;
	m_loguser = loguser;
	m_groupid.from_str(groupid); // create的时候填的是创建者id
	m_tmpdata.Clear();
	m_handleid = handleid;
	m_locked = 0;
	return 0;
}

int CLogicUserGroupHelper::get(bool lock)
{
	if(!m_inited)
	{
		LOG(LOG_ERROR, "not inited");
		return CLogicProcessor::RET_DONE;
	}

	if(STATE_INIT != m_state)
	{
		LOG(LOG_ERROR, "%s|STATE_INIT != state(%d)", m_loguser.str(), m_state);
		return m_phook->hook_on_state(HOOK_RET_INNER_FAIL, m_state, NULL);
	}


	unsigned int desSvrID;
	if(gDistribute.get_svr(m_groupid, desSvrID)!=0)
	{
		return m_phook->hook_on_state(HOOK_RET_INNER_FAIL, m_state, NULL);
	}

	m_set.get_clear_obj();
	if(lock)
	{
		m_state = STATE_TRY_LOCKGET;
		m_set.add_get_req(0, 1);
	}
	else
	{
		m_state = STATE_TRY_GET;
		m_set.add_get_req(0, 0);
	}

	if(m_ptoolkit->set_timer_s(m_timerID, TIMEOUT_FOR_DB, m_handleid, 
		CMD_DBCACHE_TIMEOUT_USERGROUP_RESP) != 0)
	{
		LOG(LOG_ERROR, "%s|set_timer fail", m_loguser.str());
		return m_phook->hook_on_state(HOOK_RET_INNER_FAIL, m_state, NULL);
	}

	if(m_ptoolkit->send_protobuf_msg(gDebugFlag, m_set.get_obj(),
		CMD_DBCACHE_GET_USERGROUP_REQ, m_groupid, MSG_QUEUE_ID_DB,  desSvrID ) != 0)
	{
		m_ptoolkit->del_timer(m_timerID);
		m_timerID = 0;
		LOG(LOG_ERROR, "%s|send to db fail", m_loguser.str());
		return m_phook->hook_on_state(HOOK_RET_INNER_FAIL, m_state, NULL);
	}	

	return CLogicProcessor::RET_YIELD;
}

int CLogicUserGroupHelper::on_get(CLogicMsg& msg)
{
	if(m_ptoolkit->del_timer(m_timerID)!=0)
	{
		LOG(LOG_ERROR, "%s|deltimer fail", m_loguser.str());
	}
	m_timerID = 0;


	if(STATE_TRY_GET == m_state)
	{
		m_state = STATE_ON_GET;
	}
	else if(STATE_TRY_LOCKGET == m_state)
	{
		m_state = STATE_ON_LOCKGET;
	}
	else
	{
		LOG(LOG_ERROR, "%s|state(%d) not valid", m_loguser.str(), m_state);
		return m_phook->hook_on_state(HOOK_RET_INNER_FAIL, m_state, NULL);
	}


	USER_NAME name;
	if(m_ptoolkit->parse_protobuf_msg(gDebugFlag, msg, name, m_set.get_clear_obj())!=0)
	{
		LOG(LOG_ERROR, "%s|parse_protobuf_msg fail", m_loguser.str());
		return m_phook->hook_on_state(HOOK_RET_INNER_FAIL, m_state, NULL);
	}
	
	if(name != m_groupid)
	{
		LOG(LOG_ERROR, "%s|ret grouid(%s) != groupid(%s)", m_loguser.str(), name.to_str().c_str(), m_groupid.to_str().c_str());
		return m_phook->hook_on_state(HOOK_RET_INNER_FAIL, m_state, NULL);
	}

	int result = m_set.result();
	if(result == DataBlockSet::OK)
	{
		DataBlock* theBlock;
		if(m_set.get_block(0, theBlock) != 0)
		{
			LOG(LOG_ERROR, "%s|no block 0", m_loguser.str());
			return m_phook->hook_on_state(HOOK_RET_INNER_FAIL, m_state, NULL);
		}
		
		if(!theBlock->has_buff())
		{
			LOG(LOG_ERROR, "%s|block no buff", m_loguser.str());
			return m_phook->hook_on_state(HOOK_RET_INNER_FAIL, m_state, NULL);
		}
		
		if(theBlock->buff().length()!=0 && !m_tmpdata.ParseFromString(theBlock->buff()))
		{
			LOG(LOG_ERROR, "%s|ParseFromString fail", m_loguser.str());
			return m_phook->hook_on_state(HOOK_RET_INNER_FAIL, m_state, NULL);
		}
		if(m_state == STATE_ON_LOCKGET)
			m_locked = 1;//这个数据取来了，并且db上lock了
		return m_phook->hook_on_state(HOOK_RET_OK, m_state, &m_tmpdata);
	}
	else if(result == DataBlockSet::NO_DATA)
	{
		return m_phook->hook_on_state(HOOK_RET_NODATA, m_state, &m_tmpdata);
	}
	else if(result == DataBlockSet::LOCKED)
	{
		return m_phook->hook_on_state(HOOK_RET_LOCKED, m_state, NULL);
	}
	else 
	{
		LOG(LOG_ERROR, "%s|db fail", m_loguser.str());
		return m_phook->hook_on_state(HOOK_RET_INNER_FAIL, m_state, NULL);
	}
}

int CLogicUserGroupHelper::set(bool create)
{
	if(!m_inited)
	{
		LOG(LOG_ERROR, "not inited");
		return CLogicProcessor::RET_DONE;
	}

	if(!create && STATE_ON_LOCKGET != m_state)
	{
		LOG(LOG_ERROR, "%s|STATE_ON_LOCKGET != state(%d)", m_loguser.str(), m_state);
		return m_phook->hook_on_state(HOOK_RET_INNER_FAIL, m_state, NULL);
	}

	unsigned int cmd= 0;
	if(create)
	{
		m_state = STATE_TRY_CREATE;
		cmd = CMD_DBCACHE_CREATE_USERGROUP_REQ;
		m_set.make_get_req(0);
	}
	else
	{
		m_state = STATE_TRY_SET;
		cmd = CMD_DBCACHE_SET_USERGROUP_REQ;
	}

	unsigned int desSvrID;
	if(gDistribute.get_svr(m_groupid, desSvrID)!=0)
	{
		return m_phook->hook_on_state(HOOK_RET_INNER_FAIL, m_state, NULL);
	}

	for(int i=0; i<m_set.get_obj().blocks_size(); ++i)
	{
		DataBlock* pblock = m_set.get_obj().mutable_blocks(i);
		pblock->set_unlock(1);
	}

	DataBlock* theBlock;
	if(m_set.get_block(0, theBlock) != 0)
	{
		LOG(LOG_ERROR, "%s|no block 0", m_loguser.str());
		return m_phook->hook_on_state(HOOK_RET_INNER_FAIL, m_state, NULL);
	}

	if(!m_tmpdata.SerializeToString(theBlock->mutable_buff()))
	{
		LOG(LOG_ERROR, "%s|SerializeToString fail", m_loguser.str());
		return m_phook->hook_on_state(HOOK_RET_INNER_FAIL, m_state, NULL);
	}

	
	if(m_ptoolkit->set_timer_s(m_timerID, TIMEOUT_FOR_DB, m_handleid, 
		CMD_DBCACHE_TIMEOUT_USERGROUP_RESP) != 0)
	{
		LOG(LOG_ERROR, "%s|set_timer_s fail", m_loguser.str());
		return m_phook->hook_on_state(HOOK_RET_INNER_FAIL, m_state, NULL);
	}
	
	if(m_ptoolkit->send_protobuf_msg(gDebugFlag, m_set.get_obj(),
		cmd, m_groupid, MSG_QUEUE_ID_DB, desSvrID ) != 0)
	{
		m_ptoolkit->del_timer(m_timerID);
		m_timerID = 0;
		LOG(LOG_ERROR, "%s|send_protobuf_msg fail", m_loguser.str());
		return m_phook->hook_on_state(HOOK_RET_INNER_FAIL, m_state, NULL);
	}

	return CLogicProcessor::RET_YIELD;		
}

int CLogicUserGroupHelper::on_set(CLogicMsg & msg)
{
	if(m_ptoolkit->del_timer(m_timerID)!=0)
	{
		LOG(LOG_ERROR, "%s|deltimer fail", m_loguser.str());
	}
	m_timerID = 0;


	if(STATE_TRY_SET == m_state)
	{
		m_state = STATE_ON_SET;
	}
	else if(STATE_TRY_CREATE== m_state)
	{
		m_state = STATE_ON_CREATE;
	}
	else
	{
		LOG(LOG_ERROR, "%s|state(%d) not valid", m_loguser.str(), m_state);
		return m_phook->hook_on_state(HOOK_RET_INNER_FAIL, m_state, NULL);
	}

	USER_NAME name;
	if(m_ptoolkit->parse_protobuf_msg(gDebugFlag, msg, name, m_set.get_clear_obj())!=0)
	{
		LOG(LOG_ERROR, "%s|parse_protobuf_msg fail", m_loguser.str());
		return m_phook->hook_on_state(HOOK_RET_INNER_FAIL, m_state, NULL);
	}
	
	if(name != m_groupid)
	{
		LOG(LOG_ERROR, "%s|ret grouid(%s) != groupid(%s)", m_loguser.str(), name.to_str().c_str(), m_groupid.to_str().c_str());
		return m_phook->hook_on_state(HOOK_RET_INNER_FAIL, m_state, NULL);
	}


	if(m_set.result() == DataBlockSet::OK)
	{
		if(STATE_ON_CREATE == m_state)
		{
			DataBlock* theBlock;
			if(m_set.get_block(0, theBlock) != 0)
			{
				LOG(LOG_ERROR, "%s|no block 0", m_loguser.str());
				return m_phook->hook_on_state(HOOK_RET_INNER_FAIL, m_state, NULL);
			}
			
			if(!theBlock->has_buff())
			{
				LOG(LOG_ERROR, "%s|block no buff", m_loguser.str());
				return m_phook->hook_on_state(HOOK_RET_INNER_FAIL, m_state, NULL);
			}
			
			if(theBlock->buff().length()!=0 && !m_tmpdata.ParseFromString(theBlock->buff()))
			{
				LOG(LOG_ERROR, "%s|ParseFromString fail", m_loguser.str());
				return m_phook->hook_on_state(HOOK_RET_INNER_FAIL, m_state, NULL);
			}
			m_locked = 0;
			return m_phook->hook_on_state(HOOK_RET_OK, m_state, &m_tmpdata);
		}
		m_locked = 0;
		return m_phook->hook_on_state(HOOK_RET_OK, m_state, NULL);
	}
	else
	{
		LOG(LOG_ERROR, "%s|db fail", m_loguser.str());
		return m_phook->hook_on_state(HOOK_RET_INNER_FAIL, m_state, NULL);
	}

}

int CLogicUserGroupHelper::unlock(bool nocallback)
{
	if(!m_inited)
	{
		LOG(LOG_ERROR, "not inited");
		return CLogicProcessor::RET_DONE;
	}

	if(STATE_ON_LOCKGET != m_state)
	{
		LOG(LOG_ERROR, "%s|STATE_ON_LOCKGET != state(%d)", m_loguser.str(), m_state);
		if(nocallback)
			return CLogicProcessor::RET_DONE;
		else
			return m_phook->hook_on_state(HOOK_RET_INNER_FAIL, m_state, NULL);
	}

	m_state = STATE_ON_UNLOCK;

	unsigned int desSvrID;
	if(gDistribute.get_svr(m_groupid, desSvrID)!=0)
	{
		if(nocallback)
			return CLogicProcessor::RET_DONE;
		else
			return m_phook->hook_on_state(HOOK_RET_INNER_FAIL, m_state, NULL);
	}

	for(int i=0; i<m_set.get_obj().blocks_size(); ++i)
	{
		DataBlock* pblock = m_set.get_obj().mutable_blocks(i);
		pblock->clear_buff();
		pblock->set_unlock(1);
	}

	m_set.get_obj().set_noresp(1);

	if(m_ptoolkit->send_protobuf_msg(gDebugFlag, m_set.get_obj(),
		CMD_DBCACHE_SET_USERGROUP_REQ, m_groupid, MSG_QUEUE_ID_DB, desSvrID ) != 0)
	{
		m_ptoolkit->del_timer(m_timerID);
		m_timerID = 0;
		LOG(LOG_ERROR, "%s|send_protobuf_msg fail", m_loguser.str());
		if(nocallback)
			return CLogicProcessor::RET_DONE;
		else
			return m_phook->hook_on_state(HOOK_RET_INNER_FAIL, m_state, NULL);
	}

	if(nocallback)
		return CLogicProcessor::RET_DONE;
	else
		return m_phook->hook_on_state(HOOK_RET_OK, m_state, NULL);
}


