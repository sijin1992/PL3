#include "logic/driver.h"
#include "logic_dbgroupuser.h"

extern CDataCache gDataCacheGroup;
extern unsigned int MSG_QUEUE_ID_TO_MYSQL;
extern unsigned int MSG_QUEUE_ID_FROM_LOGIC;
extern int gMysqlTimeout;
extern int gDebug;
extern CLoginLock gLoginLock;

#ifndef USE_USERID_AS_GROUPID
#include "common/id_creator.h"
#include "proto/Group.pb.h"
extern CGroupIDCreator gGourpID;
#endif

time_t gRespTime = 0;
time_t gRespTimeFight = 0;

void CLogicDBUserGroup::on_init()
{
	m_timerID = 0;
	m_specialCmd = 0;
	m_dumpMsgBuff = NULL;
	m_saveCmd = 0;
	m_theSet.get_clear_obj();
}

void CLogicDBUserGroup::on_finish()
{
	if(m_dumpMsgBuff != NULL)
	{
		delete[] m_dumpMsgBuff;
		m_dumpMsgBuff = NULL;
	}
}

CLogicProcessor* CLogicDBUserGroup::create()
{
	return new CLogicDBUserGroup;
}

int CLogicDBUserGroup::send_resp(CLogicMsg& msg, int code)
{
	if(m_saveCmd == CMD_DBCACHE_GET_USERGROUP_REQ)
	{
		if(code == -1)
		{
			m_theSet.save_only_result(true);
		}
		
		if(m_ptoolkit->send_protobuf_msg(gDebug, m_theSet.get_obj(),
			CMD_DBCACHE_GET_USERGROUP_RESP, m_saveName, 
			m_ptoolkit->get_queue_id(msg), 
			m_ptoolkit->get_src_server(msg), m_ptoolkit->get_src_handle(msg)) != 0)
		{
			LOG(LOG_ERROR, "%s|send_to_queue(CMD_DBCACHE_GET_USERGROUP_RESP, %u) fail",  m_saveName.str(), m_ptoolkit->get_queue_id(msg));
		}
	
	}
	else if(m_saveCmd == CMD_DBCACHE_SET_USERGROUP_REQ)
	{
		if(code == -1)
		{
			m_theSet.save_only_result(true);
		}
		else
		{
			m_theSet.save_without_blockbuff();
			m_theSet.set_result(DataBlockSet::OK);
		}
		
		if(m_ptoolkit->send_protobuf_msg(gDebug, m_theSet.get_obj(),
			CMD_DBCACHE_SET_USERGROUP_RESP, m_saveName, 
			m_ptoolkit->get_queue_id(msg), 
			m_ptoolkit->get_src_server(msg), m_ptoolkit->get_src_handle(msg)) != 0)
		{
			LOG(LOG_ERROR, "%s|send_to_queue(CMD_DBCACHE_SET_USERGROUP_RESP, %u) fail",  m_saveName.str(), m_ptoolkit->get_queue_id(msg));
		}

	}
	else if(m_saveCmd == CMD_DBCACHE_CREATE_USERGROUP_REQ)
	{
		if(code == -1)
		{
			m_theSet.save_only_result(true);
		}
		else
		{
			m_theSet.set_result(DataBlockSet::OK);
		}
		if(m_ptoolkit->send_protobuf_msg(gDebug, m_theSet.get_obj(),
			CMD_DBCACHE_CREATE_USERGROUP_RESP, m_saveName, 
			m_ptoolkit->get_queue_id(msg), 
			m_ptoolkit->get_src_server(msg), m_ptoolkit->get_src_handle(msg)) != 0)
		{
			LOG(LOG_ERROR, "%s|send_to_queue(CMD_DBCACHE_CREATE_USERGROUP_RESP, %u) fail",  m_saveName.str(), m_ptoolkit->get_queue_id(msg));
		}
	}
	/*
	else if(m_saveCmd == CMD_DBCACHE_LIST_USERGROUP_REQ)
	{
		if(code == -1)
		{
			m_listresp.set_result(m_listresp.FAIL);
		}
		else
		{
			m_listresp.set_result(m_listresp.OK);
		}
		
		if(m_ptoolkit->send_protobuf_msg(gDebug, m_listresp,
			CMD_DBCACHE_LIST_USERGROUP_RESP, m_saveName, 
			m_ptoolkit->get_queue_id(msg), 
			m_ptoolkit->get_src_server(msg), m_ptoolkit->get_src_handle(msg)) != 0)
		{
			LOG(LOG_ERROR, "%s|send_to_queue(CMD_DBCACHE_CREATE_USERGROUP_RESP, %u) fail",  m_saveName.str(), m_ptoolkit->get_queue_id(msg));
		}
	}
	*/
	return RET_DONE;
}

int CLogicDBUserGroup::try_get(CLogicMsg& msg)
{
	CBinProtocol binpro;
	if(m_ptoolkit->parse_bin_msg(msg, binpro) !=0)
	{
		return RET_DONE;
	}
	USER_NAME user = binpro.head()->parse_name();

	dump_req_msg(msg, user, CMD_DBCACHE_GET_USERGROUP_REQ);
	
	int ret = m_dbcache.init(&gDataCacheGroup);
	if(ret != m_dbcache.OK)
	{
		return send_resp(msg);
	}
	
	//组get请求
	USER_NAME tmpuser;
	if(m_ptoolkit->parse_protobuf_msg(gDebug, msg, tmpuser, m_theSet.get_obj())!=0)
	{
		return RET_DONE;
	}
	
	//看本地是否有
	CDataBlockSet theMissSet;
	ret = m_dbcache.get(user, m_theSet, theMissSet);
	if(ret == m_dbcache.WOULD_BLOCK)
	{
		//把missSet送给mysql_helper查询
		//定时
		if(m_ptoolkit->set_timer_s(m_timerID, gMysqlTimeout, m_id, CMD_DBCACHE_TIMEOUT_RESP)!=0)
		{
			return send_resp(msg);
		}
		
		//转发
		if(m_ptoolkit->send_protobuf_msg(gDebug, theMissSet.get_obj(),
			CMD_DBCACHE_GET_USERGROUP_REQ, user, 
			MSG_QUEUE_ID_TO_MYSQL) != 0)
		{
			LOG(LOG_ERROR, "send_to_queue(CMD_DBCACHE_GET_USERGROUP_REQ, MSG_QUEUE_ID_TO_MYSQL) fail");
			m_ptoolkit->del_timer(m_timerID);
			return send_resp(msg);
		}
		
		return RET_YIELD;
	}
	else if(ret == m_dbcache.OK)
	{
		m_theSet.set_result(DataBlockSet::OK);
		return on_get(msg);
	}
	else
	{
		return send_resp(msg);
	}
}

/*int CLogicDBUserGroup::on_list(CLogicMsg& msg)
{
	USER_NAME user;
	UserGroupListReq req;
	if(m_ptoolkit->parse_protobuf_msg(gDebug, msg, user, req)!=0)
	{
		return send_resp(msg);
	}

	m_saveCmd = CMD_DBCACHE_LIST_USERGROUP_REQ;
	m_saveName = user;
	//每refreshTimeS秒钟只更新一次
	const int refreshTimeS = 5;
	//最大返回100个
	const int retMax = 100;
	time_t nowtime = time(NULL);
	UserGroupListResp* presp = NULL;

	if(req.has_listtype() && req.listtype() == 1)
	{
		presp = &gRespFight;
		//可挑战的工会信息
		if(nowtime >= gRespTimeFight + refreshTimeS)
		{
			CGroupVisitorFight fightvistor;
			fightvistor.setmaxconf(req);
			gRespTimeFight = nowtime;
			gRespFight.Clear();
			gDataCacheUserGroup.getmap()->random_used_data(&fightvistor, rand());
		}
	}
	else
	{
		presp = &gResp;
		//可加入的工会信息
		if(nowtime >= gRespTime+refreshTimeS)
		{
			CGroupVisitor thevistor;
			thevistor.setmaxconf(req);
			gRespTime = nowtime;
			gResp.Clear();
			gDataCacheUserGroup.getmap()->reverse_used_data(&thevistor);
		}
	}

	if(presp == NULL)
	{
		LOG(LOG_ERROR, "%s|presp==NULL", user.str());
		return send_resp(msg);
	}
	
	int retnum = presp->items_size();
	if(retnum > 0)
	{
		int startIdx = rand()%retnum;
		for(int i=0; i<retnum && i< retMax; ++i)
		{
			m_listresp.add_items()->CopyFrom(presp->items((startIdx+i)%retnum));
		}
	}
	
	return send_resp(msg, 0);
}
*/
int CLogicDBUserGroup::on_get(CLogicMsg& msg, CLogicMsg* dbmsg)
{
	if(dbmsg) //从db回来了
	{
		USER_NAME user;
		CDataBlockSet theMissResp;
		if(m_ptoolkit->parse_protobuf_msg(gDebug, *dbmsg, user, theMissResp.get_obj())!=0)
		{
			return send_resp(msg);
		}
		
		if(m_saveName != user)
		{
			//不能吧
			LOG(LOG_ERROR, "%s|m_user != user(%s) ", m_saveName.to_str().c_str(), user.str());
			return send_resp(msg);
		}
	
		int result = theMissResp.result();
		int ret = 0;
		if(result == DataBlockSet::OK)
		{
			ret = m_dbcache.on_get(user, theMissResp);
			if(ret != m_dbcache.OK)
			{
				LOG(LOG_ERROR, "%s|m_dbcache onget fail", user.str());
				return send_resp(msg);
			}
			
			//merge将传递result
			ret = m_dbcache.merge(m_theSet, theMissResp);
			if(ret != m_dbcache.OK)
			{
				LOG(LOG_ERROR, "%s|m_dbcache merge fail", user.str());
				return send_resp(msg);
			}
		}
		else
		{
			m_theSet.set_result(theMissResp.result());
		}
	}


	if(m_saveCmd == CMD_DBCACHE_GET_USERGROUP_REQ)
	{
		if(m_theSet.result() == DataBlockSet::OK)
		{
			return send_resp(msg , 0);
		}
		else if(m_theSet.result() == DataBlockSet::LOCKED || m_theSet.result() == DataBlockSet::NO_DATA)
		{
			m_theSet.save_only_result();
			return send_resp(msg, 0);
		}
		else
		{
			LOG(LOG_ERROR, "%s|inner fail ret = %d", m_saveName.str(), m_theSet.result());
			return send_resp(msg);
		}
	}
	else
	{
		LOG(LOG_ERROR, "%s|cmd=%u not valid", m_saveName.str(), m_saveCmd);
	}
	
	return send_resp(msg);
}

int CLogicDBUserGroup::on_timeout(CLogicMsg& msg)
{
	LOG(LOG_ERROR, "%s|cmd=%u timeout", m_saveName.str(), m_saveCmd);
	return send_resp(msg);
}

int CLogicDBUserGroup::on_set(CLogicMsg& msg)
{
	USER_NAME user;
	if(m_ptoolkit->parse_protobuf_msg(gDebug, msg, user, m_theSet.get_obj())!=0)
	{
		return RET_DONE;
	}

	dump_req_msg(msg, user, CMD_DBCACHE_SET_USERGROUP_REQ);

	int ret = m_dbcache.init(&gDataCacheGroup);
	if(ret != m_dbcache.OK)
	{
		LOG(LOG_ERROR, "%s|m_dbcache init fail", user.str());
		return send_resp(msg);
	}

	ret = m_dbcache.set(user, m_theSet);
	if(ret != m_dbcache.OK)
	{
		LOG(LOG_ERROR, "%s|m_dbcache set fail", user.str());
		return send_resp(msg);
	}
   
	//不要返回值的就不管了
	if(m_theSet.get_obj().has_noresp() && m_theSet.get_obj().noresp() != 0)
	{
		return RET_DONE;
	}
	   
   	return send_resp(msg, 0);
}

int CLogicDBUserGroup::try_create(CLogicMsg& msg)
{
	USER_NAME user;
	if(m_ptoolkit->parse_protobuf_msg(gDebug, msg, user, m_theSet.get_obj()) != 0)
	{
		return RET_DONE;
	}

	dump_req_msg(msg, user, CMD_DBCACHE_CREATE_USERGROUP_REQ);

	int ret = m_dbcache.init(&gDataCacheGroup);
	if(ret != m_dbcache.OK)
	{
		return send_resp(msg);
	}

	DataBlock* theBlock;
	if(m_theSet.get_block(0, theBlock) != 0)
	{
		LOG(LOG_ERROR, "%s|no block 0", user.str());
		return send_resp(msg);
	}
	
	if(!theBlock->has_buff())
	{
		LOG(LOG_ERROR, "%s|block no buff", user.str());
		return send_resp(msg);
	}

	GroupMainData tmpdata;
	if(theBlock->buff().length()!=0 && !tmpdata.ParseFromString(theBlock->buff()))
	{
		LOG(LOG_ERROR, "%s|ParseFromString fail", user.str());
		return send_resp(msg);
	}

	m_saveGroupid.from_str(tmpdata.groupid());
	//tmpdata.mutable_keydata()->set_groupid(m_saveGroupid.to_str());

	if(!tmpdata.SerializeToString(theBlock->mutable_buff()))
	{
		LOG(LOG_ERROR, "%s|SerializeToString fail", user.str());
		return send_resp(msg);
	}

	if(m_ptoolkit->set_timer_s(m_timerID, gMysqlTimeout, m_id, CMD_DBCACHE_TIMEOUT_RESP)!=0)
	{
		LOG(LOG_ERROR, "%s|on_create set_timer fail", user.str());
		return send_resp(msg);
	}

	if(m_ptoolkit->send_protobuf_msg(gDebug, m_theSet.get_obj(),CMD_DBCACHE_CREATE_USERGROUP_REQ,
		m_saveGroupid, MSG_QUEUE_ID_TO_MYSQL) != 0)
	{
		LOG(LOG_ERROR, "%s|send_bin_msg_to_queue(CMD_DBCACHE_CREATE_REQ, MSG_QUEUE_ID_TO_MYSQL) fail", user.str());
		m_ptoolkit->del_timer(m_timerID);
		return send_resp(msg);
	}
	return RET_YIELD;
}

int CLogicDBUserGroup::on_create(CLogicMsg& msg, CLogicMsg& dbmsg)
{
	CDataBlockSet mysqlset;
	USER_NAME user;
	if(m_ptoolkit->parse_protobuf_msg(gDebug, dbmsg, user,mysqlset.get_obj()) != 0)
	{
		return send_resp(msg);
	}
	
	if(m_saveGroupid != user)
	{
		//不能吧
		LOG(LOG_ERROR, "%s|m_saveGroupid != user(%s) ", m_saveGroupid.to_str().c_str(), user.str());
		return send_resp(msg);
	}
	else if(mysqlset.result() != DataBlockSet::OK)
	{
		//insert出错
		LOG(LOG_ERROR, "%s|create_resp mysql fail", user.str());
		return send_resp(msg);
	}

	int ret = m_dbcache.on_get(user, m_theSet);
	if(ret != m_dbcache.OK)
	{
		LOG(LOG_ERROR, "%s|m_dbcache onget fail", user.str());
		return send_resp(msg);
	}

	//数据加上了groupid，照原样发回
	return send_resp(msg, 0);
}



int CLogicDBUserGroup::on_active(CLogicMsg& msg)
{
	//验证包是否完整
	unsigned int cmd = m_ptoolkit->get_cmd(msg);
	if(gDebug)
	{
	   LOG(LOG_DEBUG, "active cmd=0x%x", cmd);
	}

	if(cmd == CMD_DBCACHE_GET_USERGROUP_REQ)
	{
		return try_get(msg);
	}
	else if(cmd == CMD_DBCACHE_GET_USERGROUP_RESP)
	{
		if(m_dumpMsgBuff == NULL)
		{
		   //shit
		   LOG(LOG_ERROR, "m_dumpMsgBuff=NULL");
		   return RET_DONE;
		}
	   
		m_ptoolkit->del_timer(m_timerID);
		CLogicMsg reqMsg(m_dumpMsgBuff, m_dumpMsgLen);
		
		return on_get(reqMsg, &msg);
	}
	else if(cmd == CMD_DBCACHE_TIMEOUT_RESP)
	{
		if(m_dumpMsgBuff == NULL)
		{
			//shit
			LOG(LOG_ERROR, "m_dumpMsgBuff=NULL");
			return RET_DONE;
		}
		CLogicMsg reqMsg(m_dumpMsgBuff, m_dumpMsgLen);

		//get 超时
		return on_timeout(reqMsg);
	}
	else if(cmd == CMD_DBCACHE_SET_USERGROUP_REQ)
	{
		return on_set(msg);
	}
	else if(cmd == CMD_DBCACHE_CREATE_USERGROUP_REQ)
	{
		return try_create(msg);
	}
	else if(cmd == CMD_DBCACHE_CREATE_USERGROUP_RESP)
	{
		if(m_dumpMsgBuff == NULL)
		{
			//shit
			LOG(LOG_ERROR, "m_dumpMsgBuff=NULL");
			return RET_DONE;
		}
		m_ptoolkit->del_timer(m_timerID);
		CLogicMsg reqMsg(m_dumpMsgBuff, m_dumpMsgLen);
		return on_create(reqMsg, msg);
	}
	/*else if(cmd == CMD_DBCACHE_LIST_USERGROUP_REQ)
	{
		return on_list(msg);
	}*/
	else
		LOG(LOG_ERROR, "unexpect cmd=0x%x" , m_ptoolkit->get_cmd(msg));

	return RET_DONE;
}


