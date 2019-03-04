#include "logic_cdkey.h"
#include "online_cache.h"
//#include "proto/CmdUser.pb.h"
#include "proto/inner_cmd.pb.h"

extern int gDebugFlag;
extern int gInfoDetail;
extern COnlineCache gOnlineCache;



void CLogicCDKEY::on_init()
{
	m_dumpMsgBuff = NULL;
	m_dumpMsgLen = 0;
	m_dataControl = NULL;
	m_userlocked = false;
	m_status = 0;
	//m_resp.Clear();
}

int CLogicCDKEY::send_resp(int code)
{
	/*if(code != 0)
	{
		if(m_userlocked)
		{
			unlock_user_data(m_saveUser, false, true);
		}
	}
	if(code == 0)
		m_resp.set_result(CDKEY_Resp::OK);
	else if(code == -2)
		m_resp.set_result(CDKEY_Resp::USED);
	else if(code == -3)
		m_resp.set_result(CDKEY_Resp::CANT_USED);
	else if(code == -4)
		m_resp.set_result(CDKEY_Resp::UNKNOW);
	else if(code == -5)
		m_resp.set_result(CDKEY_Resp::SELF_USED);
	else
		m_resp.set_result(CDKEY_Resp::FAIL);
	if(m_ptoolkit->send_protobuf_msg(gDebugFlag, m_resp, CMD_CDKEY_RESP, m_saveUser, 
		MSG_QUEUE_ID_LOGIC) != 0)
		LOG_USER(LOG_ERROR, "send CMD_CDKEY_RESP fail");*/
	return RET_DONE;
}

int CLogicCDKEY::on_active_sub(CLogicMsg& msg)
{
	if(gDebugFlag)
	{
		LOG(LOG_DEBUG, "CLogicCDKEY[%u]", m_id);

	}
	int cmd = m_ptoolkit->get_cmd(msg);
	if(cmd == CMD_CDKEY_REQ)
	{
		m_saveCmd = cmd;
		if(m_status != 0)
		{
			LOG(LOG_ERROR, "m_status %d != 0", m_status);
			return RET_DONE;
		}
		CBinProtocol binpro;
		if(m_ptoolkit->parse_bin_msg(msg, binpro) != 0)
		{
			LOG(LOG_ERROR, "parse_bin_msg fail");
			return RET_DONE;
		}

		m_saveUser = binpro.head()->parse_name();

		//dump包
		m_dumpMsgLen = msg.dump(m_dumpMsgBuff);
		//m_resp.set_result(CDKEY_Resp::FAIL);

		return lockget_user_data(m_saveUser, DATA_BLOCK_FLAG_MAIN|DATA_BLOCK_FLAG_ITEMS);
	}
	else if(cmd == CMD_CDKEY_INNER_RESP)
	{
		if(m_status != 2)
			return send_resp(-1);
		InnerCDKEYResp resp;
		USER_NAME tmp;
		if(m_ptoolkit->parse_protobuf_msg(gDebugFlag, msg, tmp, resp) != 0)
		{
			LOG_USER(LOG_ERROR, "%s", "parse_protobuf_msg fail");
			return send_resp(-1);
		}
		LOG_USER(LOG_DEBUG, "cdkey ret %d", resp.ret());
		if(resp.ret() < 0)
		{
			return send_resp(resp.ret());
		}
		CLogicMsg req_msg(m_dumpMsgBuff, m_dumpMsgLen);
		/*CDKEY_Req req;
		if(m_ptoolkit->parse_protobuf_msg(gDebugFlag, req_msg, tmp, req) != 0)
		{
			LOG_USER(LOG_ERROR, "%s", "parse_protobuf_msg fail");
			return send_resp(-1);
		}
		
		string user_info_s;
		string item_list_s;
		m_dataControl->get_data_to_string(DATA_BLOCK_FLAG_MAIN, user_info_s);
		m_dataControl->get_data_to_string(DATA_BLOCK_FLAG_ITEMS, item_list_s);
	
		lua_State *l = g_lua_env.global_state;
		if(lua_gettop(l) != 0)
			LOG(LOG_ERROR, "call do_cdkey err: stack top is %u", lua_gettop(l));
		lua_getglobal(l, "do_cdkey");
		lua_pushlstring(l, user_info_s.c_str(), user_info_s.size());
		lua_pushlstring(l, item_list_s.c_str(), item_list_s.size());
		lua_pushstring(l, req.cdkey().c_str());
		lua_pushnumber(l, resp.ret());
		if(lua_pcall(l, 4, 3, 0) != 0)
		{
			LOG(LOG_ERROR, "func do_cdkey, call error %s", lua_tostring(l, -1));
			lua_pop(l, 1);
			return send_resp(-1);
		}
		else
		{
			if(lua_isstring(l, -3))
			{
				size_t ll;
				const char *s = lua_tolstring(l, -3, &ll);
				user_info_s.assign(s, ll);
				UserInfo ui;
				if(!ui.ParseFromString(user_info_s))
				{
					LOG_USER(LOG_ERROR, "UserInfo err");
					lua_pop(l,3);
					return send_resp(-1);
				}
			}
			else
			{
				lua_pop(l, 3);
				return send_resp(-1);
			}
			if(lua_isstring(l, -2))
			{
				size_t ll;
				const char *s = lua_tolstring(l, -2, &ll);
				item_list_s.assign(s, ll);
				ItemList il;
				if(!il.ParseFromString(item_list_s))
				{
					LOG_USER(LOG_ERROR, "ItemList err");
					lua_pop(l,3);
					return send_resp(-1);
				}
			}
			else
			{
				lua_pop(l, 3);
				return send_resp(-1);
			}
			if(lua_isstring(l, -1))
			{
				size_t ll;
				string rsync;
				const char *s = lua_tolstring(l, -1, &ll);
				rsync.assign(s, ll);
				CDKEY_Resp::CDKEYRsync r;
				if(!r.ParseFromString(rsync))
				{
					LOG_USER(LOG_ERROR, "ItemList err");
					lua_pop(l,3);
					return send_resp(-1);
				}
				else
				{
					m_resp.mutable_rsync()->CopyFrom(r);
				}
			}
			else
			{
				lua_pop(l, 3);
				return send_resp(-1);
			}
			lua_pop(l,3);
		}
		LOG_STAT_USE_CDKEY(m_saveUser.str(), req.cdkey().c_str());
		m_dataControl->set_data_from_string(DATA_BLOCK_FLAG_MAIN, user_info_s);
		m_dataControl->set_data_from_string(DATA_BLOCK_FLAG_ITEMS, item_list_s);
		return unlockset_user_data(m_saveUser);*/
		return RET_DONE;
	}
	else
	{
		LOG_USER(LOG_ERROR, "unexpect cmd=0x%x" , m_ptoolkit->get_cmd(msg) );
		return RET_DONE;
	}
	
}

//对象销毁前调用一次
void CLogicCDKEY::on_finish()
{
	if(m_dumpMsgBuff != NULL)
	{
		delete[] m_dumpMsgBuff;
		m_dumpMsgBuff = NULL;
		m_dumpMsgLen = 0;
	}
}

CLogicProcessor* CLogicCDKEY::create()
{
	return new CLogicCDKEY;
}

int CLogicCDKEY::on_get_data_sub(USER_NAME& user, CDataControlSlot* dataControl)
{
	if(m_status != 0)
		return send_resp(-1);
	m_status = 1;
	CLogicMsg msg(m_dumpMsgBuff, m_dumpMsgLen);
	if(!dataControl)
	{
		LOG_USER(LOG_ERROR, "on_get_data_sub fail");
		return send_resp(-1);
	}
	int result = dataControl->theSet.result();
	if(result != DataBlockSet::OK)
	{
		if(DataBlockSet::NO_DATA == result)
		{
			LOG_USER(LOG_ERROR, "on_get_data_sub NO DATA");
			return send_resp(-1);
		}
		else
		{
			LOG_USER(LOG_ERROR, "on_get_data_sub result!=OK");
			return send_resp(-1);
		}
	}

	/*CDKEY_Req req;
	USER_NAME tmp;
	if(m_ptoolkit->parse_protobuf_msg(gDebugFlag, msg, tmp, req) != 0)
	{
		LOG_USER(LOG_ERROR, "%s", "parse_protobuf_msg fail");
		return send_resp(-1);
	}
	m_userlocked = true;
	m_dataControl = dataControl;
	if(m_dataControl == NULL)
	{
		LOG_USER(LOG_ERROR, "%s", "m_dataControl==NULL");
		return send_resp(-1);
	}
	string user_info_s;
	m_dataControl->get_data_to_string(DATA_BLOCK_FLAG_MAIN, user_info_s);
	int ret = 0;

	lua_State *l = g_lua_env.global_state;
	if(lua_gettop(l) != 0)
		LOG(LOG_ERROR, "call check_cdkey err: stack top is %u", lua_gettop(l));
	lua_getglobal(l, "check_cdkey");
	lua_pushlstring(l, user_info_s.c_str(),user_info_s.size());
	lua_pushstring(l, req.cdkey().c_str());
	if(lua_pcall(l, 2, 1, 0) != 0)
	{
		LOG(LOG_ERROR, "func check_cdkey, call error %s", lua_tostring(l, -1));
		lua_pop(l, 1);
		
		ret = -1;
		return send_resp(-1);
	}
	else
	{
		ret = lua_tointeger(l, -1);
		lua_pop(l,1);
	}

	if(ret != 0)
	{
		return send_resp(ret); 
	}
	InnerCDKEYReq ireq;
	ireq.set_cdkey(req.cdkey());
	unsigned int desSvrID;
	if(gDistribute.get_svr(m_saveUser, desSvrID)!=0)
	{
		return -1;
	}
	if(m_ptoolkit->send_protobuf_msg(1, ireq, CMD_CDKEY_INNER_REQ, m_saveUser, 
		MSG_QUEUE_ID_DB, desSvrID) != 0)
	{
		LOG_USER(LOG_ERROR, "send CMD_CDKEY_INNER_REQ fail");
		return send_resp(-1);
	}
	
	m_status = 2;*/
	return RET_YIELD;
}

int CLogicCDKEY::on_set_data_sub(USER_NAME & user, CDataControlSlot * dataControl)
{
	if(dataControl == NULL || dataControl->theSet.result() != DataBlockSet::OK)
	{
		LOG_USER(LOG_ERROR, "on_set_data_sub fail");
		return send_resp(-1);
	}
	return send_resp(0);
}


