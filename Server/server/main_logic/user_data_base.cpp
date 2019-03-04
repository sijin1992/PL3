#include "user_data_base.h"

extern COnlineCache gOnlineCache;
extern CDataCache gDataCache;
extern int LOCK_PERIOD;
extern unsigned int TIMEOUT_FOR_DB;
extern int gInfoDetail;

CUserDataBase::CUserDataBase()
{
}

void CUserDataBase::on_init()
{
	presp = NULL;
}

int CUserDataBase::on_active(CLogicMsg& msg)
{
	//只有这里m_ptoolkit被赋值了，而且不会被子类覆盖
	m_pool.attach_toolkit(m_ptoolkit);

	unsigned int cmd = m_ptoolkit->get_cmd(msg);
	if(gDebugFlag)
	{
		LOG(LOG_DEBUG, "CUserDataBase[%u] recv cmd[0x%x]", m_id, cmd);
		LOG(LOG_INFO, "CUserDataBase[%u] recv cmd[0x%x]", m_id, cmd);
	}
	
	if(cmd == CMD_DBCACHE_GET_RESP)
		return on_get_resp(msg, cmd);
	else if(cmd == CMD_DBCACHE_CREATE_RESP || cmd == CMD_DBCACHE_SET_RESP)
		return on_set_resp(msg, cmd);
	else if(cmd == CMD_DBCACHE_TIMEOUT_RESP)
		return on_db_timeout(msg);
	else
	{
		int ret = on_active_sub(msg);
		
		if(gInfoDetail)
		{
			LOG_USER(LOG_INFO, "[%u] ACTIVE_SUB_CMD(0x%x)=%d", m_id, cmd, ret);
		}
		
		return ret;
	}
}

//对象销毁前调用一次
void CUserDataBase::on_finish()
{
}

//data消息处理函数
int CUserDataBase::on_get_resp(CLogicMsg& msg, unsigned int cmd)
{
	CBinProtocol binpro;
	if(m_ptoolkit->parse_bin_msg(msg, binpro))
	{
		LOG_USER(LOG_ERROR, "%s", "msg invalid");
		return RET_DONE;
	}
	
	USER_NAME user = binpro.head()->parse_name();

	CDataControlSlot* pslot = m_pool.get_slot(user);
	if(pslot == NULL)
	{
		LOG_USER(LOG_ERROR, "user(%s), pslot=NULL", user.str());
		return on_get_data_sub(user, NULL);
	}

	if(m_ptoolkit->del_timer(pslot->timerID)!=0)
	{
		LOG_USER(LOG_ERROR, "%s", "del_timer fail");
	}
	pslot->timerID = 0;

	bool useCache = !pslot->guest;
//char tmp[USER_NAME_BUFF_LEN];
//LOG_USER(LOG_INFO, "ON_GET_RESP|%s|%d", user.str(tmp),pslot->guest);

	if(pslot->state != CONTROL_STATE_WAIT_GET && pslot->state != CONTROL_STATE_WAIT_LOCKGET)
	{
		LOG_USER(LOG_ERROR, "state=%d error", pslot->state);
		return on_get_data_sub(user, NULL);
	}
	
	if(useCache && m_tmpcache.init(&gDataCache)!=m_tmpcache.OK)
	{
		LOG_USER(LOG_ERROR, "%s", "m_tmpcache.init fail");
		return on_get_data_sub(user, NULL);
	}

	if(m_ptoolkit->parse_protobuf_bin(gDebugFlag,binpro, pslot->theSet.get_obj()) != 0)
	{
		LOG_USER(LOG_ERROR, "%s", "on_get parse_protobuf_bin fail");
		return on_get_data_sub(user, NULL);
	}

	int result = pslot->theSet.result();
	bool needOnGet = true;
	if(result == DataBlockSet::OK)
	{
		needOnGet = true;
	}
	else if(result == DataBlockSet::NO_DATA)
	{
		//no data 不需要on_get了
		needOnGet = false;
	}
	else
	{
		LOG_USER(LOG_ERROR, "recv result=%d not ok or no_data", pslot->theSet.result());
		return on_get_data_sub(user, NULL);
	}

	if(useCache && needOnGet && m_tmpcache.on_get(user, pslot->theSet) != m_tmpcache.OK)
	{
		LOG_USER(LOG_ERROR, "%s", "on_get_resp, m_tmpcache.on_get fail");
		return on_get_data_sub(user, NULL);
	}

	if(pslot->state == CONTROL_STATE_WAIT_LOCKGET)
	{
		pslot->state = CONTROL_STATE_LOCKGET_OK;
	}
	else
	{
		pslot->state = CONTROL_STATE_GET_OK;
	}
	
	return on_get_data_sub(user, pslot);
}

int CUserDataBase::on_set_resp(CLogicMsg& msg, unsigned int cmd)
{
	CBinProtocol binpro;
	if(m_ptoolkit->parse_bin_msg(msg, binpro))
	{
		LOG(LOG_ERROR, "msg invalid");
		return RET_DONE;
	}
	
	USER_NAME user = binpro.head()->parse_name();

	CDataControlSlot* pslot = m_pool.get_slot(user);
	if(pslot == NULL)
	{
		LOG_USER(LOG_ERROR, "user(%s), pslot=NULL", user.str());
		return on_set_data_sub(user, NULL);
	}
	
	if(m_ptoolkit->del_timer(pslot->timerID)!=0)
	{
		LOG_USER(LOG_ERROR, "%s", "on_set_data del_timer fail");
	}
	pslot->timerID = 0;
	
	bool useCache = !pslot->guest;

	if(pslot->state != CONTROL_STATE_WAIT_SET && pslot->state != CONTROL_STATE_WAIT_UNLOCKSET
		&& pslot->state != CONTROL_STATE_WAIT_CREATE && pslot->state != CONTROL_STATE_WAIT_UNLOCK)
	{
		LOG_USER(LOG_ERROR, "state=%d error", pslot->state);
		return on_set_data_sub(user, NULL);
	}

	if(useCache && m_tmpcache.init(&gDataCache)!=m_tmpcache.OK)
	{
		LOG_USER(LOG_ERROR, "%s", "m_tmpcache.init fail");
		return on_set_data_sub(user, NULL);
	}

	CDataBlockSet resultSet;

	if(m_ptoolkit->parse_protobuf_bin(gDebugFlag,binpro, resultSet.get_obj()) != 0)
	{
		LOG_USER(LOG_ERROR, "%s", "on_set parse_protobuf_bin fail");
		return on_set_data_sub(user, NULL);
	}

	if(resultSet.result() != DataBlockSet::OK)
	{
		LOG_USER(LOG_ERROR, "recv result=%d not ok", pslot->theSet.result());
		return on_set_data_sub(user, NULL);
	}

	bool needOnSet = true;
	if(pslot->state == CONTROL_STATE_WAIT_UNLOCK)
	{
		//unlock only, no data update
		needOnSet = false;
	}

	if(useCache &&  needOnSet)
	{
		if(m_tmpcache.update_stamp(pslot->theSet, resultSet)!=m_tmpcache.OK)
		{
			LOG_USER(LOG_ERROR, "%s", "m_tmpcache.update_stamp fail");
			return on_set_data_sub(user, NULL);
		}
		
		if(m_tmpcache.on_set(user, pslot->theSet) != m_tmpcache.OK)
		{
			LOG_USER(LOG_ERROR, "%s", "m_tmpcache.on_set fail");
			return on_set_data_sub(user, NULL);
		}
	}

	if(pslot->state == CONTROL_STATE_WAIT_SET)
	{
		pslot->state = CONTROL_STATE_LOCKGET_OK;
	}
	else 
	{
		pslot->state = CONTROL_STATE_GET_OK;
	}

	return on_set_data_sub(user, pslot);
}

int CUserDataBase::on_db_timeout(CLogicMsg& msg)
{
	int flag = m_ptoolkit->get_timeout_flag(msg);
	unsigned int timerID = m_ptoolkit->get_src_handle(msg);
	CDataControlSlot* pslot = m_pool.get_slot_bytimer(timerID);
	if(pslot == NULL)
	{
		LOG_USER(LOG_ERROR, "on_db_timeout get_slot_bytimer(%u) not exist", timerID);
		return RET_DONE;
	}
	
	if(flag & TIMEOUT_FLAG_GET)
	{
		LOG_USER(LOG_ERROR, "%s", "get data timeout");
		return on_get_data_sub(pslot->user, NULL);
	}
	else if(flag & TIMEOUT_FLAG_SET)
	{
		LOG_USER(LOG_ERROR, "%s", "get data timeout");
		return on_set_data_sub(pslot->user, NULL);
	}
	else
	{
		LOG_USER(LOG_ERROR, "timer flag=%d error", flag);
		return RET_DONE;
	}
}


//操纵函数
//请求用户数据，lock指是否加锁
//返回0=ok，-1=fail，ok后程序需要return RET_YIELD，等待on_get_data的调用
int CUserDataBase::get_user_data_inner(USER_NAME& user, unsigned int flags, bool lock, bool login, bool guest)
{
	unsigned int desSvrID;
	if(gDistribute.get_svr(user, desSvrID)!=0)
	{
		return on_get_data_sub(user, NULL);
	}
	
	CDataControlSlot* pslot = m_pool.get_slot(user);
	if(!pslot)
	{
		pslot = m_pool.new_slot(user);
		if(!pslot)
		{
			return on_get_data_sub(user, NULL);
		}
	}

	pslot->guest = guest;
	bool useCache = !pslot->guest;
//char tmp[USER_NAME_BUFF_LEN];
//LOG_USER(LOG_INFO, "ON_GET_REQ|%s|%d", user.str(tmp),pslot->guest);

	if(pslot->timerID != 0)
	{
		LOG_USER(LOG_ERROR, "%s", "timerID!=0, please wait");
		return on_get_data_sub(user, NULL);
	}

	if(useCache && m_tmpcache.init(&gDataCache)!=m_tmpcache.OK)
	{
		LOG_USER(LOG_ERROR, "%s", "m_tmpcache.init fail");
		return on_get_data_sub(user, NULL);
	}

	pslot->fill_get_from_flags(flags,lock);
	pslot->state = CONTROL_STATE_START; //已经修改了set

	int ret;
	if(useCache)
	{
		ret = m_tmpcache.get(user, pslot->theSet);
	}
	else
	{
		ret = CDataCacheTmp::OK;
	}
	
	if(ret == CDataCacheTmp::OK)
	{	
		unsigned int cmd = CMD_DBCACHE_GET_REQ;
		if(login)
			cmd = CMD_DBCACHE_LOGIN_GET_REQ;

		if(m_ptoolkit->set_timer_s(pslot->timerID, TIMEOUT_FOR_DB, m_id, 
			CMD_DBCACHE_TIMEOUT_RESP, TIMEOUT_FLAG_GET) != 0)
		{
			LOG_USER(LOG_ERROR, "%s", "getreq set_timer fail");
			return on_get_data_sub(user, NULL);
		}
		
		if(m_ptoolkit->send_protobuf_msg(gDebugFlag, pslot->theSet.get_obj(),
			cmd, user, MSG_QUEUE_ID_DB,  desSvrID ) != 0)
		{
			m_ptoolkit->del_timer(pslot->timerID);
			pslot->timerID = 0;
			LOG_USER(LOG_ERROR, "send getreq(0x%x) to db fail", cmd);
			return on_get_data_sub(user, NULL);
		}
		
		if(lock)
			pslot->state = CONTROL_STATE_WAIT_LOCKGET;
		else
			pslot->state = CONTROL_STATE_WAIT_GET;
		return RET_YIELD;
	}
	else 
	{
		LOG_USER(LOG_ERROR, "%s", "m_tmpcache.get fail");
		return on_get_data_sub(user, NULL);
	}
}

//回写用户数据
//请求用户数据，unlock指是否解开锁, create指是否使用create指令
int CUserDataBase::set_user_data_inner(USER_NAME& user, bool unlock, bool nodata, RegistReq* pCreateInfo, bool guest, bool noresp)
{
	unsigned int desSvrID;
	if(gDistribute.get_svr(user, desSvrID)!=0)
	{
		return on_set_data_sub(user, NULL);
	}
	
	int slotIdx;
	CDataControlSlot* pslot;
	
	//check state
	if(pCreateInfo)
	{
		pslot = m_pool.new_slot(user);
		if(!pslot)
		{
			//必须先已经get了
			LOG_USER(LOG_ERROR, "%s", "new_slot fail create must new");
			if(noresp)
				return RET_DONE;
			else
				return on_set_data_sub(user, NULL);
		}
		
		if(presp == NULL)
		{
			LOG_USER(LOG_ERROR, "%s", "presp=NULL");
			if(noresp)
				return RET_DONE;
			else
				return on_set_data_sub(user, NULL);
		}
		int ret = pslot->create_new_data(user, pCreateInfo);
		if(ret != 0)
		{
			if(noresp)
				return RET_DONE;
			else
			{
				if(ret == -2){
					presp->set_result(presp->NICKNAME_EXIST);
				}
				else{
					presp->set_result(presp->FAIL);
				}
				return on_set_data_sub(user, NULL);
			}
		}
	}
	else
	{
		pslot = m_pool.get_slot(user,&slotIdx);
		if(!pslot)
		{
			//必须先已经get了
			LOG_USER(LOG_ERROR, "%s", "[pslot=NULL] set_user_data must be called after get_user_data");
			if(noresp)
				return RET_DONE;
			else
				return on_set_data_sub(user, NULL);
		}
		
		if(pslot->state != CONTROL_STATE_LOCKGET_OK)
		{
			LOG_USER(LOG_ERROR,  "state(%d) is not CONTROL_STATE_LOCKGET_OK", pslot->state);
			if(noresp)
				return RET_DONE;
			else
				return on_set_data_sub(user, NULL);
		}
	}

	if(pslot->timerID != 0)
	{
		LOG_USER(LOG_ERROR,  "%s", "timerID!=0, please wait");
		if(noresp)
			return RET_DONE;
		else
			return on_set_data_sub(user, NULL);
	}

	pslot->guest = guest;
	bool useCache = !pslot->guest;
	
	if(useCache && m_tmpcache.init(&gDataCache)!=m_tmpcache.OK)
	{
		LOG_USER(LOG_ERROR, "%s", "m_tmpcache.init fail");
		if(noresp)
			return RET_DONE;
		else
			return on_set_data_sub(user, NULL);
	}

	//发包
	CDataBlockSet* psetToSend;
	CDataBlockSet sendSet;
	if(unlock)
		pslot->set_unlock_flag();
		
	if(nodata)
	{
		m_tmpcache.copy_unlock(sendSet, pslot->theSet);
		if(noresp)
		{
			sendSet.get_obj().set_noresp(1);
		}
		else
		{
			sendSet.get_obj().clear_noresp();
		}
		psetToSend = &sendSet;
	}
	else
	{
		if(noresp)
			pslot->theSet.get_obj().set_noresp(1);
		else 
			pslot->theSet.get_obj().clear_noresp();
		psetToSend = &(pslot->theSet);
	}

	unsigned int cmd = CMD_DBCACHE_SET_REQ;
	if(pCreateInfo)
	{
		//if(!pCreateInfo->has_recreate() || !pCreateInfo->recreate())
			cmd = CMD_DBCACHE_CREATE_REQ;
	}

	if(!noresp && m_ptoolkit->set_timer_s(pslot->timerID, TIMEOUT_FOR_DB, m_id, 
		CMD_DBCACHE_TIMEOUT_RESP, TIMEOUT_FLAG_GET) != 0)
	{
		LOG_USER(LOG_ERROR, "%s", "setreq set_timer fail");
		if(noresp)
			return RET_DONE;
		else
			return on_set_data_sub(user, NULL);
	}

	if(m_ptoolkit->send_protobuf_msg(gDebugFlag, psetToSend->get_obj(),
		cmd, user, MSG_QUEUE_ID_DB, desSvrID ) != 0)
	{
		if(!noresp)
		{
			m_ptoolkit->del_timer(pslot->timerID);
			pslot->timerID = 0;
		}
		LOG_USER(LOG_ERROR, "send setreq(0x%x) fail to db", cmd);
		if(noresp)
			return RET_DONE;
		else
			return on_set_data_sub(user, NULL);
	}
		
	//set state
	if(pCreateInfo)
	{
		pslot->state = CONTROL_STATE_WAIT_CREATE;
	}
	else if(unlock)
	{
		if(nodata)
			pslot->state = CONTROL_STATE_WAIT_UNLOCK;
		else
			pslot->state = CONTROL_STATE_WAIT_UNLOCKSET;
	}
	else
		pslot->state = CONTROL_STATE_WAIT_SET;

	if(noresp)
		return RET_DONE;
	return RET_YIELD;		
}

