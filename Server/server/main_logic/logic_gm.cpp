#include "lua_manager.h"
#include "logic_gm.h"
#include "online_cache.h"
#include <unistd.h>

//#include "xml_reader/gm.h"
//#include "globefunction.h"

extern int gDebugFlag;
extern COnlineCache gOnlineCache;
extern string gGMXML;

void CLogicGM::on_init()
{
	m_dumpMsgBuff = NULL;
	m_dumpMsgLen = 0;
}

int CLogicGM::send_general_resp(CLogicMsg& msg, int code)
{
	if(m_saveCmd != CMD_GM_SEND_MAIL_REQ)
	{
		GMGeneralResp resp;
		resp.set_result(code);
		resp.set_fd(m_fd);
		resp.set_session(m_session);
		
		if(m_ptoolkit->send_protobuf_msg(gDebugFlag, resp, CMD_GM_RESP, m_saveUser, 
			m_ptoolkit->get_queue_id(msg)) != 0)
			LOG(LOG_ERROR, "send CMD_GM_RESP fail");
	}
	return RET_DONE;
}

//int CLogicGM::check_gm(const char* gmuser, string gmkey)
//{
//	CConfgm gmconf;
//	if(gmconf.read_from_xml(gGMXML.c_str()) != 0)
//	{
//		LOG(LOG_ERROR, "gmconf.read_from_xml(%s) fail", gGMXML.c_str());
//		return -1;
//	}

//	CConfItemgm* pgm = gmconf.get_conf(gmuser, true);
//	if(pgm == NULL)
//	{
//		LOG(LOG_ERROR, "gm %s not exsit", gmuser);
//		m_resp.set_code(-2);
//		return -1;
//	}

//	if(pgm->key != gmkey)
//	{
//		LOG(LOG_ERROR, "gmkey %s error", gmkey.c_str());
//		m_resp.set_code(-3);
//		return -1;
//	}
//	
//	return 0;
//}

int CLogicGM::on_active_sub(CLogicMsg& msg)
{
	if(gDebugFlag)
	{
		LOG(LOG_DEBUG, "CLogicGM[%u] recv cmd[0x%x]", m_id, m_ptoolkit->get_cmd(msg));

	}
	
	int cmd = m_ptoolkit->get_cmd(msg);
	if(cmd == CMD_DBCACHE_GM_RESP)
	{
		CLogicMsg dump_msg(m_dumpMsgBuff, m_dumpMsgLen);
		DBGMResp req;
		if(m_ptoolkit->parse_protobuf_msg(gDebugFlag, msg, m_saveUser, req) == 0)
		{
			int code = req.result();

			//如果邮件没有发送成功，就要加到重发列表
			if(code != 0 && m_saveCmd == CMD_GM_SEND_MAIL_REQ)
			{
				GMSendMailReq req;
				if(m_ptoolkit->parse_protobuf_msg(gDebugFlag, dump_msg, m_saveUser, req) == 0)
				{
					DBSendMailReq db_req;
					db_req.CopyFrom(req.req());

					lua_State *l = g_lua_env.global_state;
					if(lua_gettop(l) != 0)
						LOG(LOG_ERROR, "call send_gmail err: stack top is %u", lua_gettop(l));
					lua_getglobal(l, "add_undo_mail");
					char buff[10240];
					db_req.SerializeToArray(buff, 10240);
					string req;
					req.assign(buff, db_req.GetCachedSize());
					const char *n = m_saveUser.str();
					lua_pushlstring(l, n, strlen(n));
					lua_pushlstring(l, req.c_str(),req.size());
					if(lua_pcall(l, 2, 0, 0) != 0)
					{
						LOG(LOG_ERROR, "func add_undo_mail, call error %s", lua_tostring(l, -1));
						lua_pop(l, 1);
						
						return send_general_resp(msg,-1);
					}
					else
					{
						LOG(LOG_INFO, "gm add remail success");
					}
				}
				else
					LOG(LOG_ERROR, "send_mail err");
			}
			
			return send_general_resp(dump_msg,code);
		}
		else
		{
			LOG(LOG_ERROR, "parse CMD_GM_SEND_MAIL_REQ faile");
		}
		return send_general_resp(dump_msg,-1);
	}
	else
	{
		m_saveCmd = m_ptoolkit->get_cmd(msg);

		//dump包
		m_dumpMsgLen = msg.dump(m_dumpMsgBuff);
		
		if(m_saveCmd == CMD_GM_SEND_MAIL_REQ)
		{
			GMSendMailReq req;
			if(m_ptoolkit->parse_protobuf_msg(gDebugFlag, msg, m_saveUser, req) == 0)
			{
				DBSendMailReq db_req;
				db_req.CopyFrom(req.req());
				if(db_req.has_user())
				{
					m_fd = req.fd();
					m_session = req.session();
					unsigned int desSvrID;
					if(gDistribute.get_svr(m_saveUser, desSvrID)!=0)
					{
						return -1;
					}
					// TODO: 防止超时，需要启一个定时器
					if(m_ptoolkit->send_protobuf_msg(gDebugFlag, db_req, CMD_DBCACHE_SEND_MAIL_REQ, m_saveUser, MSG_QUEUE_ID_DB,desSvrID) != 0){
						LOG(LOG_ERROR, "send CMD_DBCACHE_SEND_MAIL_REQ fail");
					}
					return RET_YIELD;
				}
				else
				{
					m_fd = req.fd();
					m_session = req.session();
					lua_State *l = g_lua_env.global_state;
					if(lua_gettop(l) != 0)
						LOG(LOG_ERROR, "call send_gmail err: stack top is %u", lua_gettop(l));
					lua_getglobal(l, "send_gmail");
					char buff[10240];
					db_req.SerializeToArray(buff, 10240);
					string req;
					req.assign(buff, db_req.GetCachedSize());
					lua_pushlstring(l, req.c_str(),req.size());
					if(lua_pcall(l, 1, 0, 0) != 0)
					{
						LOG(LOG_ERROR, "func send_gmail, call error %s", lua_tostring(l, -1));
						lua_pop(l, 1);
						
						return send_general_resp(msg,-1);
					}
					else
					{
						LOG(LOG_INFO, "gm send global mail success");
						return send_general_resp(msg,0);
					}
				}
			}
			else
			{
				LOG(LOG_ERROR, "parse CMD_GM_SEND_MAIL_REQ failed");
			}
		}
		else if(m_saveCmd == CMD_HTTPCB_GM_BLOCK_REQ)
		{
			GMBlockReq req;
			if(m_ptoolkit->parse_protobuf_msg(gDebugFlag, msg, m_saveUser, req) !=0)
			{
				send_general_resp(msg,-1);
				return RET_DONE;
			}
			return lockget_user_data(m_saveUser, DATA_BLOCK_FLAG_MAIN, true);
		}
		else
			LOG(LOG_ERROR, "unexpect cmd=0x%x" , m_ptoolkit->get_cmd(msg) );
	}
	return send_general_resp(msg,-1);
}

//对象销毁前调用一次
void CLogicGM::on_finish()
{
	if(m_dumpMsgBuff != NULL)
	{
		delete[] m_dumpMsgBuff;
		m_dumpMsgBuff = NULL;
		m_dumpMsgLen = 0;
	}
}

CLogicProcessor* CLogicGM::create()
{
	return new CLogicGM;
}


int CLogicGM::on_get_data_sub(USER_NAME& user, CDataControlSlot* dataControl)
{
	CLogicMsg msg(m_dumpMsgBuff, m_dumpMsgLen);
	if(!dataControl)
	{
		LOG(LOG_ERROR, "get %s data fail", user.str());
		return send_general_resp(msg,-1);
	}
	
	int result = dataControl->theSet.result();
	if(result != DataBlockSet::OK)
	{
		LOG(LOG_ERROR, "%s no data", user.str());
		return send_general_resp(msg,-1);
	}

	if(m_saveCmd == CMD_HTTPCB_GM_BLOCK_REQ)
	{
		string user_info_s;
		if (dataControl->get_data_to_string(DATA_BLOCK_FLAG_MAIN, user_info_s) != 0)
		{
			LOG_USER(LOG_ERROR, "%s", "get_main_data fail");
			return send_general_resp(msg, -1);
		}

		int block_type = 0;
		int block_time = 0;
		GMBlockReq req;
		if(m_ptoolkit->parse_protobuf_msg(gDebugFlag, msg, m_saveUser, req) ==0)
		{
			block_type = req.type();
			block_time = req.blocktime();
		}

		lua_State *l = g_lua_env.global_state;
		if (lua_gettop(l) != 0)
			LOG(LOG_ERROR, "call set_user_block err: stack top is %u", lua_gettop(l));
		lua_getglobal(l, "set_user_block");
		lua_pushlstring(l, user_info_s.c_str(), user_info_s.size());
		lua_pushinteger(l, block_type);
		lua_pushinteger(l, block_time);
		if (lua_pcall(l, 3, 1, 0) != 0)
		{
			LOG(LOG_ERROR, "func set_user_block, call error %s", lua_tostring(l, -1));
			lua_pop(l, 1);

			return send_general_resp(msg, -1);
		}
		else
		{
			size_t len;
			const char *t = lua_tolstring(l, -1, &len);
			user_info_s.assign(t, len);
			lua_pop(l, 1);
		}
	
		
		if (dataControl->set_data_from_string(DATA_BLOCK_FLAG_MAIN, user_info_s))
		{
			LOG_USER(LOG_ERROR, "%s", "set_main_data fail");
			return send_general_resp(msg, -1);
		}
	}
	return unlockset_user_data(m_saveUser, true, false);
}

int CLogicGM::on_set_data_sub(USER_NAME & user, CDataControlSlot * dataControl)
{
	CLogicMsg msg(m_dumpMsgBuff, m_dumpMsgLen);
//	if(dataControl == NULL || dataControl->theSet.result() != DataBlockSet::OK)
//	{
//		return send_fail_resp(msg);
//	}

//	m_resp.set_code(0);

//	LOG_USER(LOG_INFO, "GM_ACT|itemid=%d|itemnum=%d|expr=%d|gold=%d", 
//		m_resp.itemid(), m_resp.itemnum(), m_resp.expr(), m_resp.money());
//	
//	if(m_ptoolkit->send_protobuf_msg(gDebugFlag, m_resp, CMD_HTTPCB_GM_RESP,
//		 	m_saveUser, m_ptoolkit->get_queue_id(msg)) != 0)
//		LOG(LOG_ERROR, "send CMD_HTTPCB_GM_RESP fail");
	return send_general_resp(msg, 0);
}


