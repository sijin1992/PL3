#include "logic_gm_usersnap.h"
#include "online_cache.h"
#include <unistd.h>

extern int gDebugFlag;
extern COnlineCache gOnlineCache;
extern string gGMXML;

void CLogicGMUserSnap::on_init()
{
	m_dumpMsgBuff = NULL;
	m_dumpMsgLen = 0;
}

int CLogicGMUserSnap::send_general_resp(CLogicMsg& msg, int code)
{
	if(m_saveCmd == CMD_GM_GET_USER_SNAP_REQ)
	{
		if( code != 0 )
		{
			m_userSnapResp.set_result(m_userSnapResp.FAIL);
		}
		else
		{
			m_userSnapResp.set_result(m_userSnapResp.OK);
		}
		
		if(m_ptoolkit->send_protobuf_msg(gDebugFlag, m_userSnapResp, CMD_GM_GET_USER_SNAP_RESP, m_saveUser, 
			m_ptoolkit->get_queue_id(msg)) != 0)
			LOG(LOG_ERROR, "send CMD_GM_GET_USER_SNAP_RESP fail");
	}
	return RET_DONE;
}


int CLogicGMUserSnap::check_gm(const char* gmuser, string gmkey)
{
	/*
	CConf gmconf;
	if(gmconf.read_from_xml(gGMXML.c_str()) != 0)
	{
		LOG(LOG_ERROR, "gmconf.read_from_xml(%s) fail", gGMXML.c_str());
		return -1;
	}

	CConfItemgm* pgm = gmconf.get_conf(gmuser, true);
	if(pgm == NULL)
	{
		LOG(LOG_ERROR, "gm %s not exsit", gmuser);
		m_resp.set_code(-2);
		return -1;
	}

	if(pgm->key != gmkey)
	{
		LOG(LOG_ERROR, "gmkey %s error", gmkey.c_str());
		m_resp.set_code(-3);
		return -1;
	}
	*/
	return 0;
}

int CLogicGMUserSnap::on_active_sub(CLogicMsg& msg)
{
	if(gDebugFlag)
	{
		LOG(LOG_DEBUG, "CLogicGM[%u] recv cmd[0x%x]", m_id, m_ptoolkit->get_cmd(msg));

	}
	int cmd = m_ptoolkit->get_cmd(msg);
	if(cmd == CMD_GM_GET_USER_SNAP_REQ)
	{
		m_saveCmd = m_ptoolkit->get_cmd(msg);
		GMGetUserSnapReq req;
		if(m_ptoolkit->parse_protobuf_msg(gDebugFlag, msg, m_saveUser, req) != 0)
		{
			LOG(LOG_ERROR, "parse_protobuf_msg failed");
			return send_general_resp(msg, -1);
		}
		USER_NAME tarUser;
		tarUser.from_str(req.username());
		unsigned int desSvrID;
		m_userSnapResp.set_fd(req.fd());
		m_userSnapResp.set_session(req.session());
		m_userSnapResp.mutable_info()->set_uid(tarUser.to_str().c_str());
		if(gDistribute.get_svr(tarUser, desSvrID)!=0)
		{
			LOG_USER(LOG_ERROR, "gDistribute.get_svr(tarUser:%s, desSvrID:%u) failed", 
				tarUser.to_str().c_str(), desSvrID);
			return send_general_resp(msg, -1);
		}
		//保存MSG
		m_dumpMsgLen = msg.dump(m_dumpMsgBuff);
		unsigned int flags = DATA_BLOCK_FLAG_MAIN | DATA_BLOCK_FLAG_ITEMS | DATA_BLOCK_FLAG_SHIP;
		return get_user_data(tarUser, flags , true);
	}
	else
	{
		LOG(LOG_ERROR, "unknown cmd:%x", cmd);
	}
	return RET_DONE;
}

//对象销毁前调用一次
void CLogicGMUserSnap::on_finish()
{
	if(m_dumpMsgBuff != NULL)
	{
		delete[] m_dumpMsgBuff;
		m_dumpMsgBuff = NULL;
		m_dumpMsgLen = 0;
	}
}

CLogicProcessor* CLogicGMUserSnap::create()
{
	return new CLogicGMUserSnap;
}


int CLogicGMUserSnap::on_get_data_sub(USER_NAME& user, CDataControlSlot* dataControl)
{
	CLogicMsg msg(m_dumpMsgBuff, m_dumpMsgLen);
	if(!dataControl)
	{
		LOG_USER(LOG_ERROR, "get %s data fail", user.str());
		return send_general_resp(msg, -1);
	}
	
	int result = dataControl->theSet.result();
	if(result != DataBlockSet::OK)
	{
		LOG_USER(LOG_ERROR, "%s no data", user.str());
		return send_general_resp(msg, -1);
	}

	if( m_saveCmd == CMD_GM_GET_USER_SNAP_REQ )
	{
		/*UserInfo userInfo ;
		if( dataControl->get_main_data(userInfo) != 0 )
		{
			LOG_USER(LOG_ERROR, "%s get_main_data", user.str());
			return send_general_resp(msg, -1);
		}
		//取出快照
		{
			PARSE_USER_INFO(userInfo);

			UserSnapInfo &info = *m_userSnapResp.mutable_info();
			info.set_nick(nick);
			info.set_qd(qudao);
			info.set_exp(exp);
			info.set_lv(level);
			info.set_exp(exp);
			info.set_viplv(vipLevel);
			info.set_vipscore(vipScore);
			info.set_totaldep(totalDep);
			info.set_totalrmb(totalRMB);
			info.set_gold(gold);
			info.set_money(money);
			info.set_php(php);
			info.set_maxpower(maxpower);
			info.set_state(state);
			info.set_php(php);
			info.set_maxpower(maxpower);
			info.set_state(state);
			info.set_stagelv(stagelv);
			info.set_maxrank(maxrank);
			info.set_menpai(menpai);

			info.set_ip(ip);
		}
		send_general_resp(msg, 0);*/
	}

	return RET_DONE;

}

int CLogicGMUserSnap::on_set_data_sub(USER_NAME & user, CDataControlSlot * dataControl)
{
	return RET_DONE;
}


