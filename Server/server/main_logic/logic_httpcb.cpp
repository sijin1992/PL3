//to-do: 替换CLogicHttpcb为自己的类名字
//to-do: 替换logic_tool.h为自己的头文件
//to-do: 替换ModifyDataResp为应答的proto对象
//to-do: 替换ProtoTemplateReq为请求的proto对象
//to-do: 替换CMD_TEMPLATE_REQ为请求的命令字
//to-do: 替换CMD_LOGIC_TOOL_MODIFY_RESP为应答的命令字



#include "logic_httpcb.h"
#include "online_cache.h"
#include "proto/CmdUser.pb.h"
//#include "globefunction.h"

extern int gDebugFlag;
extern int gInfoDetail;
extern COnlineCache gOnlineCache;

#define HTTPCB_SERVER_INNER_ERROR -1 	//当作参数错误
#define HTTPCB_NODATA -2				// 没有这个数据
#define HTTPCB_WILL_REDO -3				// 会自动重试


int httpcbCollectionConf1[] = {7029,7030,7031,7032,7033,7034};

void CLogicHttpcb::on_init()
{
	m_dumpMsgBuff = NULL;
	m_dumpMsgLen = 0;

	m_addMoneyResp.Clear();
	m_dataControl = NULL;
	m_paydataControl = NULL;
	m_ext_items.clear();
	m_userlocked = false;
	m_itemid = 0;
	m_new_itemid = 0;
}

int CLogicHttpcb::send_resp(CLogicMsg& msg, int code)
{
	if(code != 0)
	{
		if(m_userlocked)
		{
			unlock_user_data(m_saveUser, true, true);
		}
	}

	if(m_saveCmd == CMD_HTTPCB_ADDMONEY_REQ)
	{
		HttpAddMondyReq req;
		USER_NAME tmp;
		m_ptoolkit->parse_protobuf_msg(gDebugFlag, msg, tmp, req);
		
		m_addMoneyResp.set_result(code);
		m_addMoneyResp.mutable_req()->CopyFrom(req);
		
		if(m_ptoolkit->send_protobuf_msg(gDebugFlag, m_addMoneyResp, CMD_HTTPCB_ADDMONEY_RESP, m_saveUser, 
			m_ptoolkit->get_queue_id(msg)) != 0)
			LOG_USER(LOG_ERROR, "%s", "send CMD_LOGIC_TOOL_MODIFY_RESP fail");
		if(code == 0)
		{
			AddMoneyCallBack cb;
			cb.set_sid(req.sid());
			cb.set_orderno(req.orderno());
			cb.set_amount(req.money());
			cb.set_cur_money(m_main_data.money());
			cb.set_cur_vip(m_main_data.vip_level());
			//cb.set_total_money(m_main_data.ext_data().total_money());
			cb.set_item_id(m_itemid);
			cb.set_new_item_id(m_new_itemid);
			/*cb.set_buqian(m_main_data.huodong().qiandao().status() == 2?1:0);
			if(m_yuekaflag == 1 && m_main_data.ext_data().has_yueka())
				cb.mutable_yueka()->CopyFrom(m_main_data.ext_data().yueka());
			else if(m_yuekaflag == 2)
				cb.set_zsyk(1);
			if( !m_ext_items.empty() )
			{
				if( !cb.mutable_ext_items()->ParseFromString(m_ext_items) )
				{
					LOG_USER(LOG_ERROR, "%s", "cb.mutable_ext_items()->ParseFromString(m_ext_items) fail");
				}
			}
			if(m_ptoolkit->send_protobuf_msg(gDebugFlag, cb, CMD_ADD_MONEY_CALLBACK, m_saveUser, 
				MSG_QUEUE_ID_LOGIC) != 0)
				LOG_USER(LOG_ERROR, "%s", "send CMD_ADD_MONEY_CALLBACK fail");

			if(m_yuekaflag == 1)
			{
				TaskRefleshResp resp;
				resp.set_huoyue(1);
				int daily_size = m_main_data.daily().daily_list_size();
				for(int i = 0; i < daily_size; ++i)
				{
					if(m_main_data.daily().daily_list(i).id() == 3106001)
					{
						DailyTask *dt = resp.add_daily_list();
						dt->CopyFrom(m_main_data.daily().daily_list(i));
						break;
					}
				}
				if(m_ptoolkit->send_protobuf_msg(gDebugFlag, resp, CMD_TASK_REFLEASH_RESP, m_saveUser, 
					MSG_QUEUE_ID_LOGIC) != 0)
					LOG_USER(LOG_ERROR, "send CMD_TASK_REFLEASH_RESP fail");
			}
			else if(m_yuekaflag == 2)
			{
				TaskRefleshResp resp;
				resp.set_huoyue(1);
				int daily_size = m_main_data.daily().daily_list_size();
				for(int i = 0; i < daily_size; ++i)
				{
					if(m_main_data.daily().daily_list(i).id() == 3111001)
					{
						DailyTask *dt = resp.add_daily_list();
						dt->CopyFrom(m_main_data.daily().daily_list(i));
						break;
					}
				}
				if(m_ptoolkit->send_protobuf_msg(gDebugFlag, resp, CMD_TASK_REFLEASH_RESP, m_saveUser, 
					MSG_QUEUE_ID_LOGIC) != 0)
					LOG_USER(LOG_ERROR, "send CMD_TASK_REFLEASH_RESP fail");
			}*/
		}
		LOG_USER(LOG_INFO, "orderno=%s|money=%d|ext:%s|fake:%d|selfdef:%d|gamemoney:%d|basemoney:%d|monthcard:%d, retcode = %d",
				req.orderno().c_str(), req.money(), req.extinfo().c_str(), req.fake(), req.selfdef(), 
				req.gamemoney(), req.basemoney(), req.monthcard(), code);
	}
		
	return RET_DONE;
}

int CLogicHttpcb::on_active_sub(CLogicMsg& msg)
{
	if(gDebugFlag)
	{
		LOG(LOG_DEBUG, "CLogicHttpcb[%u] recv cmd[0x%x]", m_id, m_ptoolkit->get_cmd(msg));

	}

	m_saveCmd = m_ptoolkit->get_cmd(msg);
	CBinProtocol binpro;
	if(m_ptoolkit->parse_bin_msg(msg, binpro) != 0)
	{
		LOG(LOG_ERROR, "parse_bin_msg fail");
		return RET_DONE;
	}

	m_saveUser = binpro.head()->parse_name();

	//dump包
	m_dumpMsgLen = msg.dump(m_dumpMsgBuff);

	//解析包
	if(m_saveCmd == CMD_HTTPCB_ADDMONEY_REQ)
	{
		HttpAddMondyReq req;
		if(m_ptoolkit->parse_protobuf_bin(gDebugFlag, binpro, req) !=0)
		{
			return RET_DONE;
		}

		LOG_USER(LOG_INFO, "RECV|orderno=%s|money=%d|fake=%d", 
			req.orderno().c_str(), req.money(), req.fake());

		m_addMoneyResp.mutable_req()->CopyFrom(req);
		return lockget_user_data(m_saveUser, DATA_BLOCK_FLAG_MAIN | DATA_BLOCK_FLAG_ITEMS, true);
	}
	else
		LOG_USER(LOG_ERROR, "unexpect cmd=0x%x" , m_ptoolkit->get_cmd(msg) );

	return RET_DONE;
}

//对象销毁前调用一次
void CLogicHttpcb::on_finish()
{
	if(m_dumpMsgBuff != NULL)
	{
		delete[] m_dumpMsgBuff;
		m_dumpMsgBuff = NULL;
		m_dumpMsgLen = 0;
	}
}

CLogicProcessor* CLogicHttpcb::create()
{
	return new CLogicHttpcb;
}

int CLogicHttpcb::on_get_data_sub(USER_NAME& user, CDataControlSlot* dataControl)
{
	char buff[USER_NAME_BUFF_LEN];
	CLogicMsg msg(m_dumpMsgBuff, m_dumpMsgLen);

	HttpAddMondyReq req;
	USER_NAME tmp;
	if(m_ptoolkit->parse_protobuf_msg(gDebugFlag, msg, tmp, req) != 0)
	{
		LOG_USER(LOG_ERROR, "%s", "parse_protobuf_msg fail");
		return send_resp(msg, HTTPCB_SERVER_INNER_ERROR);
	}
	
	if(!dataControl)
	{
		lua_State *l = g_lua_env.global_state;
		if(lua_gettop(l) != 0)
			LOG(LOG_ERROR, "call add_undo_recharge err: stack top is %u", lua_gettop(l));
		lua_getglobal(l, "add_undo_recharge");
		const char *n = m_saveUser.str();
		lua_pushlstring(l, n, strlen(n));
		lua_pushinteger(l, req.money());
		lua_pushlstring(l, req.extinfo().c_str(), req.extinfo().length());
		lua_pushinteger(l, req.fake());
		lua_pushinteger(l, req.selfdef());
		lua_pushinteger(l, req.gamemoney());
		lua_pushinteger(l, req.basemoney());
		lua_pushinteger(l, req.monthcard());
		lua_pushstring(l, req.orderno().c_str());
		int retcode = HTTPCB_SERVER_INNER_ERROR;
		if(lua_pcall(l, 9, 0, 0) != 0)
		{
			LOG(LOG_ERROR, "func add_undo_recharge, call error %s", lua_tostring(l, -1));
			lua_pop(l, 1);
		}
		else
		{
			LOG_USER(LOG_INFO, "add undo recharge|orderno=%s|money=%d|fake:%d",
			req.orderno().c_str(), req.money(), req.fake());
			//retcode = HTTPCB_WILL_REDO;
			retcode = HTTPCB_NODATA;
		}
		
		LOG_USER(LOG_ERROR, "%s on_get_data_sub fail", user.str(buff));
		return send_resp(msg, HTTPCB_SERVER_INNER_ERROR);
	}
	
	int result = dataControl->theSet.result();
	if(result != DataBlockSet::OK)
	{
		if(DataBlockSet::NO_DATA == result)
		{
			LOG_USER(LOG_ERROR, "%s on_get_data_sub NO DATA", user.str(buff));
			return send_resp(msg, HTTPCB_NODATA);
		}
		else
		{
			lua_State *l = g_lua_env.global_state;
			if(lua_gettop(l) != 0)
				LOG(LOG_ERROR, "call add_undo_recharge err: stack top is %u", lua_gettop(l));
			lua_getglobal(l, "add_undo_recharge");
			const char *n = m_saveUser.str();
			lua_pushlstring(l, n, strlen(n));
			lua_pushinteger(l, req.money());
			lua_pushlstring(l, req.extinfo().c_str(), req.extinfo().length());
			lua_pushinteger(l, req.fake());
			lua_pushinteger(l, req.selfdef());
			lua_pushinteger(l, req.gamemoney());
			lua_pushinteger(l, req.basemoney());
			lua_pushinteger(l, req.monthcard());
			lua_pushstring(l, req.orderno().c_str());
			int retcode = HTTPCB_SERVER_INNER_ERROR;
			if(lua_pcall(l, 9, 0, 0) != 0)
			{
				LOG(LOG_ERROR, "func add_undo_recharge, call error %s", lua_tostring(l, -1));
				lua_pop(l, 1);
			}
			else
			{
				LOG_USER(LOG_INFO, "add undo recharge|orderno=%s|money=%d|fake:%d",
				req.orderno().c_str(), req.money(), req.fake());
				//retcode = HTTPCB_WILL_REDO;
				retcode = HTTPCB_NODATA;
			}
			
			LOG_USER(LOG_ERROR, "%s on_get_data_sub result!=OK", user.str(buff));
			return send_resp(msg, retcode);
		}
	}

	

	if(m_saveUser == user) //first step
	{
		m_userlocked = true;
		//先保存data
		m_dataControl = dataControl;
		/*
		if(m_dataControl->get_main_data(m_theUserProto) != 0)
		{
			LOG_USER(LOG_ERROR, "%s", "get_main_data fail");
			return send_resp(msg, HTTPCB_SERVER_INNER_ERROR);
		}
			
		if(m_dataControl->get_bag_data(m_theBagProto) != 0)
		{
			LOG_USER(LOG_ERROR, "%s", "get_bag_data fail");
			return send_resp(msg, HTTPCB_SERVER_INNER_ERROR);
		}
		*/
	}
	else //second step
	{
		LOG_USER(LOG_ERROR, "%s", "some error");
		return send_resp(msg, HTTPCB_SERVER_INNER_ERROR);
	}

	//for safe
	if(m_saveCmd != CMD_HTTPCB_ADDMONEY_REQ)
	{
		LOG_USER(LOG_ERROR, "%s", "m_saveCmd != CMD_HTTPCB_ADDMONEY_REQ");
		return send_resp(msg, HTTPCB_SERVER_INNER_ERROR);
	}
	
	if(m_dataControl == NULL)
	{
		LOG_USER(LOG_ERROR, "%s", "m_dataControl==NULL");
		return send_resp(msg, HTTPCB_SERVER_INNER_ERROR);
	}
	string user_info_s;
	if( m_dataControl->get_data_to_string(DATA_BLOCK_FLAG_MAIN, user_info_s) != 0 )
	{
		LOG_USER(LOG_ERROR, "%s", "get_main_data fail");
		return send_resp(msg, HTTPCB_SERVER_INNER_ERROR);
	}
	string bag_info_s;
	if( m_dataControl->get_data_to_string(DATA_BLOCK_FLAG_ITEMS, bag_info_s) != 0 )
	{
		LOG_USER(LOG_ERROR, "%s", "get_items_list fail");
		return send_resp(msg, HTTPCB_SERVER_INNER_ERROR);
	}
	int ret = 0;

	lua_State *l = g_lua_env.global_state;
	if(lua_gettop(l) != 0)
		LOG(LOG_ERROR, "call platform_add_money err: stack top is %u", lua_gettop(l));
	lua_getglobal(l, "platform_add_money");
	lua_pushlstring(l, user_info_s.c_str(),user_info_s.size());
	lua_pushlstring(l, bag_info_s.c_str(),bag_info_s.size());
	lua_pushinteger(l, req.money());
	lua_pushstring(l, req.extinfo().c_str());
	lua_pushinteger(l, req.fake());
	lua_pushstring(l, req.orderno().c_str());
	//lua_pushinteger(l, req.selfdef());
	//lua_pushinteger(l, req.gamemoney());
	//lua_pushinteger(l, req.basemoney());
	//lua_pushinteger(l, req.monthcard());
	//if(lua_pcall(l, 9, 6, 0) != 0)
	if(lua_pcall(l, 6, 5, 0) != 0)
	{
		LOG(LOG_ERROR, "func platform_add_money, call error %s", lua_tostring(l, -1));
		lua_pop(l, 1);
		
		ret = -1;
		return send_resp(msg, HTTPCB_SERVER_INNER_ERROR);
	}
	else
	{
		size_t len;
		const char *t = lua_tolstring(l, -5, &len);
		user_info_s.assign(t, len);
		t = lua_tolstring(l, -4, &len);
		bag_info_s.assign(t, len);
		m_yuekaflag = lua_tointeger(l, -3);
		m_itemid = lua_tointeger(l, -2);
		m_new_itemid = lua_tointeger(l, -1);
		//if( !lua_isnil(l, -1) )
		//{
		//	t = lua_tolstring(l, -1, &len);
		//	m_ext_items.assign(t, len);
		//}
		lua_pop(l, 5);

		//const char *t = lua_tolstring(l, -4, &len);
		//user_info_s.assign(t, len);
		//m_yuekaflag = lua_tointeger(l, -3);
		//m_itemid = lua_tointeger(l, -2);
		//m_new_itemid = lua_tointeger(l, -1);		
		//lua_pop(l,4);
	}
	if(ret == 0)
	{
		if(!m_main_data.ParseFromString(user_info_s))
		{
			LOG_USER(LOG_ERROR, "%s", "parse user_data err");
			ret = -1;
			return send_resp(msg, HTTPCB_SERVER_INNER_ERROR);
		}
		else if( m_dataControl->set_data_from_string(DATA_BLOCK_FLAG_MAIN, user_info_s))
		{
			LOG_USER(LOG_ERROR, "%s", "set_main_data fail");
			return send_resp(msg, HTTPCB_SERVER_INNER_ERROR);
		}
		else if( m_dataControl->set_data_from_string(DATA_BLOCK_FLAG_ITEMS, bag_info_s))
		{
			LOG_USER(LOG_ERROR, "%s", "set_items_list fail");
			return send_resp(msg, HTTPCB_SERVER_INNER_ERROR);
		}
		//上报数据
		{
			/*PARSE_USER_INFO(m_main_data);
			SNAP_USER(m_saveUser.str());*/
		}
	}
	
	return unlockset_user_data(m_saveUser, true, false);
}

int CLogicHttpcb::on_set_data_sub(USER_NAME & user, CDataControlSlot * dataControl)
{
	char buff[USER_NAME_BUFF_LEN];
	CLogicMsg msg(m_dumpMsgBuff, m_dumpMsgLen);
	if(dataControl == NULL || dataControl->theSet.result() != DataBlockSet::OK)
	{
		LOG_USER(LOG_ERROR, "%s on_set_data_sub fail", user.str(buff));
		return send_resp(msg, HTTPCB_SERVER_INNER_ERROR);
	}

	if(user == m_saveUser)
	{
		send_resp(msg, 0); //通知发货ok
	}
	
	return RET_DONE;
}


