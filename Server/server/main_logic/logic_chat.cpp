#include "logic_chat.h"
#include "online_cache.h"
#include <iostream>
#include <fstream>
#include <stdlib.h>
#include <unistd.h>

#include "lua_manager.h"

#include "proto/CmdUser.pb.h"


//#include "room_sync_manager.h"

//#include "proto/room_sync.pb.h"

using namespace std;
extern int gDebugFlag;
extern COnlineCache gOnlineCache;

#define CHAT_GET_SENDER 1
#define CHAT_GET_RECVER 2

int CLogicChatGroupHookImp::hook_on_state(int retcode, int state, GroupMainData* pdata)
{
	if(retcode == CLogicUserGroupHelper::HOOK_RET_OK)
	{
		if(state == CLogicUserGroupHelper::STATE_ON_GET)
		{
			return pobj->hook_get_ok(pdata);
		}
		else if(state == CLogicUserGroupHelper::STATE_ON_LOCKGET)
		{
			return pobj->hook_lockget_ok(pdata);
		}
		else if(state == CLogicUserGroupHelper::STATE_ON_CREATE)
		{
			return pobj->hook_create_ok(pdata);
		}
		else if(state == CLogicUserGroupHelper::STATE_ON_SET)
		{
			return pobj->hook_set_ok();
		}
		else if(state == CLogicUserGroupHelper::STATE_ON_UNLOCK)
		{
			return pobj->hook_unlock_ok();
		}
	}
	else if(retcode == CLogicUserGroupHelper::HOOK_RET_NODATA)
	{
		return pobj->hook_get_nodata(NULL);
	}
	
	return pobj->send_resp();
}


void CLogicChat::on_init()
{
	m_dumpMsgBuff = NULL;
	m_dumpMsgLen = 0;
	m_locked = false;
	m_lua_handle = NULL;
}

int CLogicChat::on_active_sub(CLogicMsg& msg)
{
	if(gDebugFlag)
	{
		LOG(LOG_DEBUG, "CLogicChat[%u] recv cmd[0x%x]", m_id, m_ptoolkit->get_cmd(msg));
	}
	unsigned int cmd = m_ptoolkit->get_cmd(msg);
	if(cmd == CMD_DBCACHE_GET_USERGROUP_RESP || cmd == CMD_DBCACHE_SET_USERGROUP_RESP
		|| cmd == CMD_DBCACHE_CREATE_USERGROUP_RESP || cmd == CMD_DBCACHE_TIMEOUT_USERGROUP_RESP)
	{
		return m_helper.on_resp(cmd, msg);
	}
	else
	{
		m_saveCmd = cmd;

		CBinProtocol binpro;
		if(m_ptoolkit->parse_bin_msg(msg, binpro) != 0)
		{
			return RET_DONE;
		}
		//dump包
		m_dumpMsgLen = msg.dump(m_dumpMsgBuff);
		m_saveUser = binpro.head()->parse_name();
		m_queue_id = m_ptoolkit->get_queue_id(msg);
		if(m_saveCmd != CMD_CHAT_REQ || m_saveCmd != CMD_HTTPCB_BROADCAST_REQ)
		{
			//不在线
			LOG_USER(LOG_ERROR, "%s not chat cmd, %d", m_saveUser.str(), m_saveCmd);
			return RET_DONE;
		}
		
		if ( m_saveCmd != CMD_HTTPCB_BROADCAST_REQ && check_and_refresh_online_info() != 0)
		{
			//不在线
			LOG_USER(LOG_ERROR, "%s not online", m_saveUser.str());
			return RET_DONE;
		}

		map<unsigned int, LUA_handle>::iterator it = g_lua_cmd_map->find(m_saveCmd);
		if(it == g_lua_cmd_map->end())
		{
			LOG_USER(LOG_ERROR, "lua cmd %x, handle not find", m_saveCmd);
			if(m_locked)
			{
				return unlock_user_data(m_saveUser, false, true);
			}
			return RET_DONE;
		}
		else
		{
			m_req.assign(binpro.packet(), binpro.packet_len());
			m_task_manager.init(this, &(it->second), m_saveUser, 
				&m_req, &m_resp_fail, &m_resp, m_saveCmd);
			return run();
		}
	}
}

//对象销毁前调用一次
void CLogicChat::on_finish()
{
	if(m_dumpMsgBuff != NULL)
	{
		delete[] m_dumpMsgBuff;
		m_dumpMsgBuff = NULL;
		m_dumpMsgLen = 0;
	}
}

CLogicProcessor* CLogicChat::create()
{
	return new CLogicChat;
}

int CLogicChat::on_get_data_sub(USER_NAME& user, CDataControlSlot* dataControl)
{
	if(m_task_manager.on_get_data(dataControl) != 0)
		return send_resp();
	return run();
}

int CLogicChat::on_set_data_sub(USER_NAME & user, CDataControlSlot * dataControl)
{
	if(m_task_manager.on_set_data(dataControl) != 0)
		return send_resp();
	return run();
}

int CLogicChat::send_resp()
{
	m_task_manager.clear();
	switch(m_task_manager.act_resp())
	{
	case 0:
		{
			if(m_task_manager.ext_cmd1() == 0x1521)
			{
				ChatMsg_t t;
				if(t.ParseFromString(*m_task_manager.ext_resp1()))
				{
					for (int i = 0; i < t.msg_size(); ++i)
					{
						ChatMsg tt;
						if(t.has_channel())
							tt.set_channel(t.channel());
						if(t.has_sender())
							tt.mutable_sender()->CopyFrom(t.sender());
						if(t.has_recver())
							tt.mutable_recver()->CopyFrom(t.recver());
						tt.mutable_recvs()->CopyFrom(t.recvs());
						tt.set_msg(t.msg(i));
						if(tt.has_type())
							tt.set_type(t.type());
						tt.mutable_minor()->CopyFrom(t.minor());
						LOG_USER(LOG_DEBUG, "%s", tt.DebugString().c_str());
						if(m_ptoolkit->send_protobuf_msg(gDebugFlag, tt, m_task_manager.ext_cmd1(), m_saveUser, 
							m_queue_id) != 0)
							LOG_USER(LOG_ERROR, "send %d resp fail", m_task_manager.ext_cmd1());
					}
					
				}
			}
			if(m_ptoolkit->send_protobuf_s_msg(gDebugFlag, m_resp, m_saveCmd + 1, m_saveUser, 
				m_queue_id) != 0)
				LOG_USER(LOG_ERROR, "send %d resp fail", m_saveCmd + 1);
			break;
		}
	case 1:
		{
			if(m_ptoolkit->send_protobuf_s_msg(gDebugFlag, m_resp_fail, m_saveCmd + 1, m_saveUser, 
				m_queue_id) != 0)
				LOG_USER(LOG_ERROR, "send %d fail_resp fail", m_saveCmd + 1);
			break;
		}
	}
	return RET_DONE;
}

int CLogicChat::hook_get_ok(GroupMainData* pdata)
{
	if(m_task_manager.on_get_group_data(pdata) != 0)
		return send_resp();
	return run();
	/*CLogicMsg msg(m_dumpMsgBuff, m_dumpMsgLen);
	
	if(!CLogicUserGroupHelper::groupDataValid(*pdata))
	{
		//换成create请求
		m_helper.init(&m_hook, m_ptoolkit, m_saveUser, m_saveUser.to_str(), m_id);
		if(!CLogicUserGroupHelper::createGroupData(pdata, m_theUserProto.mutable_usergroup(), m_saveUser))
		{
			LOG_USER(LOG_ERROR, "%s", "create group fail");
			return send_resp(msg);
		}
		
		return m_helper.set(true);
	}
	
	LOG_USER(LOG_ERROR, "create but already have group(%s)", pdata->keydata().groupid().c_str());
	return send_resp(msg);*/
	LOG_USER(LOG_DEBUG, "get group");
	return RET_DONE;
}

int CLogicChat::hook_get_nodata(GroupMainData* pdata)
{
	if(m_task_manager.on_get_group_data(pdata) != 0)
		return send_resp();
	return run();
	/*
	CLogicMsg msg(m_dumpMsgBuff, m_dumpMsgLen);
	
	LOG_USER(LOG_ERROR, "cmd=0x%x should no be here", m_saveCmd);
	return send_resp(msg);
	*/
	LOG_USER(LOG_DEBUG, "get group nodate");
	return RET_DONE;
}

int CLogicChat::hook_lockget_ok(GroupMainData* pdata)
{
	if(m_task_manager.on_get_group_data(pdata) != 0)
		return send_resp();
	return run();
	/*m_lockedgroup = "";
	CLogicMsg msg(m_dumpMsgBuff, m_dumpMsgLen);
	
	LOG_USER(LOG_ERROR, "cmd=0x%x should no be here", m_saveCmd);
	return send_resp(msg);*/
	LOG_USER(LOG_DEBUG, "get group lock");
	return RET_DONE;
}

int CLogicChat::hook_set_ok()
{
	if(m_task_manager.on_set_group_data() != 0)
		return send_resp();
	return run();
	/*m_lockedgroup = "";
	CLogicMsg msg(m_dumpMsgBuff, m_dumpMsgLen);
	
	LOG_USER(LOG_ERROR, "cmd=0x%x should no be here", m_saveCmd);
	return send_resp(msg);*/
	LOG_USER(LOG_DEBUG, "set group");
	return RET_DONE;
}

int CLogicChat::hook_create_ok(GroupMainData* pdata)
{
	if(m_task_manager.on_set_group_data() != 0)
		return send_resp();
	return run();
	/*
	m_lockedgroup = "";
	
	CLogicMsg msg(m_dumpMsgBuff, m_dumpMsgLen);

	if(m_saveCmd == CMD_USERGROUP_CREATE_REQ)
	{
		UserGroupCache* pcache =m_theUserProto.mutable_usergroup();
		pcache->mutable_keydata()->set_groupid(pdata->keydata().groupid());

		m_getresp.mutable_data()->CopyFrom(*pdata);
		m_getresp.mutable_usercache()->CopyFrom(*pcache);

		pcache->set_jointime(time(NULL));
		
		if(m_pControl->set_main_data(m_theUserProto) !=0 )
		{
			LOG_USER(LOG_ERROR, "%s", "create group set user fail");
			return send_resp(msg);
		}

		if(gInfoDetail)
		{
			LOG_USER(LOG_INFO, "GROUP_CREATE|group=%s", 
				pdata->keydata().groupid().c_str());
		}
		
		return unlockset_user_data(m_saveUser);
	}
	
	LOG_USER(LOG_ERROR, "cmd=0x%x should no be here", m_saveCmd);
	return send_resp(msg);
	*/
	return RET_DONE;
}

int CLogicChat::hook_unlock_ok()
{
	return RET_DONE;
}


int CLogicChat::get_group(string groupid, bool lock)
{
	if(m_helper.init(&m_hook, m_ptoolkit, m_saveUser, groupid, m_id) != 0)
		return -1;
	return m_helper.get(lock);
}

int CLogicChat::set_group(string group_data, string groupid, bool create = false)
{
	if(create)
		if(m_helper.init(&m_hook, m_ptoolkit, m_saveUser, groupid, m_id) != 0)
			return -1;
	m_helper.rawdata()->ParseFromString(group_data);
	return m_helper.set(create);
}

int CLogicChat::unlock_group(bool nocallback)
{
	return m_helper.unlock(nocallback);
}


