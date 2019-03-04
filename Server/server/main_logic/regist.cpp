#include "regist.h"
#include "online_cache.h"
#include "logic_info.h"
#include "common/zone_define.h"
#include <arpa/inet.h>

#include "proto/inner_cmd.pb.h"

extern int gDebugFlag;
extern COnlineCache gOnlineCache;
extern unsigned int CHECK_ONLINE_INTERVAL;

void CLogicRegist::on_init()
{
	m_req.Clear();
	m_resp.Clear();
}

//有msg到达的时候激活对象
 int CLogicRegist::on_active_sub(CLogicMsg& msg)
{
	if(gDebugFlag)
	{
		LOG_USER(LOG_DEBUG, "CLogicRegist[0x%x] recv cmd[0x%x]", m_id, m_ptoolkit->get_cmd(msg));
	}
	//解析包
	if(m_ptoolkit->get_cmd(msg) == CMD_REGIST_REQ)
	{
		/*if(g_logic_info.cur_reg >= g_logic_info.max_reg)
		{
			return send_fail_resp(1);
		}*/
		CBinProtocol binreq;
		if( m_ptoolkit->parse_bin_msg(msg, binreq) != 0)
		{
			return RET_DONE;
		}
		if(!m_req.ParseFromArray(binreq.packet(), binreq.packet_len()))
		{
			LOG_USER(LOG_ERROR, "%s", "RegistReq.ParseFromArray fail");
			return RET_DONE;
		}
		
		m_saveUser = binreq.head()->parse_name();
		m_saveReqQueue = m_ptoolkit->get_queue_id(msg);

		//需要保证没有数据
		//现在不需要了，可以直接设置

		InnerQueryBeforeRegReq ireq;
		ireq.set_name(m_req.real_name());
		ireq.set_account(m_req.account());
		ireq.set_act_id(1);
		unsigned int desSvrID;
		if(gDistribute.get_svr(m_saveUser, desSvrID)!=0)
		{
			return -1;
		}
		if(m_ptoolkit->send_protobuf_msg(gDebugFlag, ireq, CMD_QUERY_BEFORE_REGIST_REQ, m_saveUser, 
			MSG_QUEUE_ID_DB, desSvrID) != 0)
		{
			LOG_USER(LOG_ERROR, "send CMD_QUERY_BEFORE_REGIST_REQ fail");
			return send_fail_resp();
		}
		else
			return RET_YIELD;
	}
	else if(m_ptoolkit->get_cmd(msg) == CMD_QUERY_BEFORE_REGIST_RESP)
	{
		CBinProtocol binreq;
		if( m_ptoolkit->parse_bin_msg(msg, binreq) != 0)
		{
			return RET_DONE;
		}
		InnerQueryBeforeReqResp t;
		if(!t.ParseFromArray(binreq.packet(), binreq.packet_len()))
		{
			LOG_USER(LOG_ERROR, "%s", "InnerQueryBeforeReqResp.ParseFromArray fail");
			return RET_DONE;
		}
		if(t.result() == -1)
		{
			LOG_USER(LOG_ERROR, "%s", "InnerQueryBeforeReqResp.reslut = -1");
		}
		else if(t.result() == 1)
		{
			RegistReq::ExtInfo ei;
			ei.set_real_money(t.real_money());
			ei.set_money(t.money());
			m_req.mutable_ext_info()->CopyFrom(ei);
		}
			
		return create_user_data(m_saveUser, m_req, m_resp);
	}
	else
		LOG_USER(LOG_ERROR, "unexpect cmd=0x%x" , m_ptoolkit->get_cmd(msg) );

	return RET_DONE;
}

//对象销毁前调用一次
 void CLogicRegist::on_finish()
{
}

 CLogicProcessor* CLogicRegist::create()
{
	return new CLogicRegist;
}

int CLogicRegist::on_set_data_sub(USER_NAME& user, CDataControlSlot* dataControl)
{
	m_resp.set_isinit(false);
	if(g_logic_info.unrecharge != 0)
		m_resp.set_unrecharge(g_logic_info.unrecharge);
	if(g_logic_info.anti_cdkey != 0)
		m_resp.set_anti_cdkey(g_logic_info.anti_cdkey);
	if(g_logic_info.anti_weichat != 0)
		m_resp.set_anti_weichat(g_logic_info.anti_weichat);
	if(!dataControl)
	{
		LOG_USER(LOG_ERROR, "%s","on_set_data_sub dataControl = NULL");
		//m_resp.set_result(m_resp.FAIL); 
	}
	else
	{
		m_resp.set_user_name(user.str());
		m_resp.set_key("bbb");
		m_resp.set_isinit(false);
		int result = dataControl->theSet.result();
		if(result != DataBlockSet::OK)
		{
			LOG_USER(LOG_ERROR, "%s","on_set_data_sub result != OK");
			m_resp.set_result(m_resp.FAIL);
		}
		else
		{
			UserInfo userinfo;
			ItemList item_list;
			MailList mail_list;
			ShipList ship_list;
			if(dataControl->get_main_data(userinfo) !=0
				|| dataControl->get_ship_list(ship_list) != 0
				|| dataControl->get_item_package(item_list) != 0
				|| dataControl->get_mail_list(mail_list) != 0)
			{
				m_resp.set_result(m_resp.FAIL);
			}
			else
			{
				string ignore;
				string account;
				if(userinfo.has_account())
					account = userinfo.account();
				else
					account = "";
				int iLevel = 1;
				if(gOnlineCache.onLogin(2, user, m_ptoolkit, CHECK_ONLINE_INTERVAL, iLevel, 0, ignore, "", account)!= 0)
				{
					LOG_USER(LOG_ERROR,"%s,UserName,%s,Account,%s", "onLogin fail", user.str(), account.c_str());
					m_resp.set_result(m_resp.FAIL);
				}
				else
				{
				
//					if(dataControl->get_bag_monsters(monsters) !=0 || dataControl->get_bag_equips(equips) != 0 || dataControl->get_bag_fuwens(fuwens) != 0)
//					{
//						resp.set_result(resp.FAIL);
//					}
//					else
					{
						dataControl->make_login_resp(user, userinfo, ship_list, item_list, mail_list, m_resp, true);
					}
				}
			}
			
			// TODO:注册成功
			unsigned int theIdx;
			ONLINE_CACHE_UNIT* punit;
			if(gOnlineCache.getOnlineRef(user, theIdx, punit)==0)
			{
				/*LOG_STAT_REGIST(user.str(), userinfo.ip().c_str(), m_req.mcc().c_str(), 
					userinfo.account().c_str(), userinfo.nickname().c_str(), userinfo.lead().level(), userinfo.platform());
				LOG_STAT_DEVICE(user.str(), m_req.device_type().c_str(), m_req.resolution().c_str(), m_req.os_type().c_str(), m_req.isp().c_str(), m_req.net().c_str());*/
			
//台湾地区
#if IS_SERVER_ZONE_TW 
				//向GAME SDK 上报角色数据
				UserInfoReportReq reportReq;
				reportReq.set_act_type(reportReq.REGIST);
				reportReq.set_user_id(user.to_str());
				reportReq.set_nick_name(userinfo.nickname());
				//reportReq.set_sex(userinfo.lead().sex());
				reportReq.set_time(time(NULL));
				if(m_ptoolkit->send_protobuf_msg(gDebugFlag, reportReq, CMD_GATEWAY_USERINFO_REPORT_REQ,
					user, MSG_QUEUE_ID_GATEWAY) !=0)
				{
					LOG(LOG_ERROR, "CMD_GATEWAY_USERINFO_REPORT_REQ send fail");
				}
#endif
			}
			g_logic_info.cur_reg++;
		}
	}

	/*if(m_resp.result() == m_resp.OK)
	{
		INMAP_PLAYER unit;
		unit.map_id = 0;
		unit.avatar = 0;
		unit.posi_x = 0;
		unit.posi_y = 0;
		unit.name = user;
		unit.session_id = 0;
		//g_inmap_manager.update_player(unit);
		//g_inmap_manager.debug();
	}*/

	LOG_USER(LOG_INFO, "REGIST|result=%d", m_resp.result());

	if(m_ptoolkit->send_protobuf_msg(gDebugFlag, m_resp, CMD_LOGIN_RESP, user, m_saveReqQueue) != 0)
	{
		LOG_USER(LOG_ERROR, "%s", "send_bin_msg_to_queue(CMD_REGIST_RESP) fail");
		return RET_DONE;
	}

	return RET_DONE;
}

int CLogicRegist::send_fail_resp(int code)
{
	m_resp.set_user_name(m_saveUser.str());
	m_resp.set_key("bbb");
	m_resp.set_isinit(false);
	if (code == 0)
		m_resp.set_result(LoginResp::FAIL);
	else if(code == 1)
		m_resp.set_result(LoginResp::FULL);
	if(m_ptoolkit->send_protobuf_msg(gDebugFlag, m_resp, CMD_LOGIN_RESP, m_saveUser, 
			m_saveReqQueue) != 0)
	{
		LOG_USER(LOG_ERROR, "send CMD_LOGIN_RESP fail");
	}
	return RET_DONE;
}
