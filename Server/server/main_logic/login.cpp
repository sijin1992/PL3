#include "login.h"

#include "online_cache.h"
#include "logic_util.h"

#include "proto/UserInfo.pb.h"
#include "proto/CmdLogin.pb.h"
#include "logic_info.h"
#include "codeset/codeset.h"
#include <arpa/inet.h>

extern int gDebugFlag;
extern COnlineCache gOnlineCache;
extern unsigned int CHECK_ONLINE_INTERVAL;
	
void CLogicLogin::on_init()
{
	m_req.Clear();
}

//有msg到达的时候激活对象
int CLogicLogin::on_active_sub(CLogicMsg& msg)
{
	if(gDebugFlag)
	{
		LOG_USER(LOG_DEBUG, "CLogicLogin[%d] recv cmd[0x%x]", m_id, m_ptoolkit->get_cmd(msg));
	}
	//解析包
	if(m_ptoolkit->get_cmd(msg) == CMD_LOGIN_REQ)
	{
		CBinProtocol binreq;
		if( m_ptoolkit->parse_bin_msg(msg, binreq) != 0)
		{
			return RET_DONE;
		}

		//do something
		if(!m_req.ParseFromArray(binreq.packet(), binreq.packet_len()))
		{
			LOG_USER(LOG_ERROR, "%s", "LoginReq.ParseFromArray fail");
			return RET_DONE;
		}
		
		m_saveUser = binreq.head()->parse_name();
		m_saveReqQueue = m_ptoolkit->get_queue_id(msg);
		
		//cout << "user:" << m_saveUser.str() << " with key:" << req.key() << " logined" << endl;

		return loginget_user_data(m_saveUser, 
			DATA_BLOCK_FLAG_MAIN
			|DATA_BLOCK_FLAG_SHIP
			|DATA_BLOCK_FLAG_ITEMS
			|DATA_BLOCK_FLAG_MAIL
		);

	}
	else
		LOG_USER(LOG_ERROR, "unexpect cmd=0x%x" , m_ptoolkit->get_cmd(msg) );

	return RET_DONE;
}

//对象销毁前调用一次
void CLogicLogin::on_finish()
{
}

CLogicProcessor* CLogicLogin::create()
{
	return new CLogicLogin;
}

int CLogicLogin::on_get_data_sub(USER_NAME& user, CDataControlSlot* dataControl)
{
	LoginResp resp;
	bool needwriteback = false;
	bool bgetok = false;
	int thelevel = 0;

	resp.set_user_name(user.str());
	resp.set_key(m_req.key());
	resp.set_isinit(false);
	resp.set_version(g_logic_info.version);
	if(g_logic_info.unrecharge != 0)
		resp.set_unrecharge(g_logic_info.unrecharge);
	if(g_logic_info.anti_cdkey != 0)
		resp.set_anti_cdkey(g_logic_info.anti_cdkey);
	if(g_logic_info.anti_weichat != 0)
		resp.set_anti_weichat(g_logic_info.anti_weichat);
	
	if(!dataControl)
	{
		LOG_USER(LOG_ERROR, "%s", "on_get_data_sub dataControl=NULL");
		resp.set_result(resp.FAIL); 
	}
	else
	{
		bgetok = true;
		int result = dataControl->theSet.result();
		if(result == DataBlockSet::NO_DATA)
		{
			if(g_logic_info.cur_reg >= g_logic_info.max_reg)
				resp.set_result(resp.FULL);
			else
			{
				if(gOnlineCache.onLogin(1, user, m_ptoolkit, CHECK_ONLINE_INTERVAL, 
					0, m_req.userip(), m_req.key(), m_req.domain(), m_req.user_name())!= 0)
				{
					resp.set_result(resp.FAIL);
				}
				resp.set_result(resp.NODATA);
			}
		}
		else if(result != DataBlockSet::OK)
		{
			LOG_USER(LOG_ERROR, "%s", "on_get_data_sub result != OK");
			resp.set_result(resp.FAIL);
		}
		else
		{
			UserInfo userinfo;
			ShipList ship_list;
			ItemList item_list;
			MailList mail_list;

			if(dataControl->get_main_data(userinfo) != 0
				|| dataControl->get_ship_list(ship_list) != 0
				|| dataControl->get_item_package(item_list) != 0
				|| dataControl->get_mail_list(mail_list) != 0)
			{
				resp.set_result(resp.FAIL);
			}
			else
			{
				thelevel = 1;
				int r = gOnlineCache.onLogin(0, user, m_ptoolkit, CHECK_ONLINE_INTERVAL, 
					thelevel, m_req.userip(), m_req.key(), m_req.domain(),userinfo.account());
				if(r == -2)
				{	
					resp.set_result(resp.FULL); 
				}
				else if(r != 0)
				{
					resp.set_result(resp.FAIL);
				}
				else if(userinfo.has_blocked()
					&& (userinfo.blocked().type() == 1
						|| (userinfo.blocked().type() == 2 && userinfo.blocked().stamp() > (int)time(NULL))))
				{
					LOG_USER(LOG_INFO,"blocktype %d, stamp %ld",userinfo.blocked().type(),userinfo.blocked().stamp());
					resp.set_result(resp.BLOCKED);
					needwriteback = false;
				}
				else
				{
					needwriteback = true;
					userinfo.set_client_version(m_req.version());
					int ret = dataControl->make_login_resp(user, userinfo, ship_list, item_list, mail_list,
						resp, true, &m_req);
					if((ret == 1) && 
						(dataControl->set_main_data(userinfo) !=0
							|| dataControl->set_ship_list(ship_list) != 0
						 	|| dataControl->set_item_package(item_list)!=0
						 	|| dataControl->set_mail_list(mail_list) != 0))
					{
						resp.set_result(resp.FAIL);
						needwriteback = false;
					}
					else if(ret < 0)
					{
						resp.set_result(resp.FAIL);
						needwriteback = false;
					}
					else
					{
						LOG_STAT_LOGIN(user.str(), "null", "null", "null", "null", userinfo.platform());
						/*const UserInfo &userInfo = resp.user_info();
						PARSE_USER_INFO(userInfo);

						LOG_STAT_LOGIN(user.str(), ip, mmc, level, acc, userInfo.platform());
						LOG_STAT_DEVICE(user.str(), m_req.device_type().c_str(), m_req.resolution().c_str(), m_req.os_type().c_str(), m_req.isp().c_str(), m_req.net().c_str());
						SNAP_USER(user.str());

						{
							PARSE_BAG_LIST(userInfo, item_list);
							SNAP_BAG(user.str());
						}*/
					}
				}
			}
		}
	}

	if(m_req.version() != g_logic_info.version)
	{
		bool can_pass = false;
		string req_v12 = m_req.version().substr(0, m_req.version().find_last_of("."));
		LOG_USER(LOG_DEBUG, "req_v12 = %s", req_v12.c_str());
		
		for(vector<string>::iterator it = g_logic_info.old_versions.begin();
			it != g_logic_info.old_versions.end(); it++)
		{
			
			if (m_req.version() == *it)
			{
				resp.set_version(*it);
				can_pass = true;
				break;
			}
			else
			{
				string t_v12 = (*it).substr(0, (*it).find_last_of("."));
				if(req_v12 == t_v12)
				{
					resp.set_version(*it);
					break;
				}
			}
		}
		if(!can_pass)
		{
			resp.set_result(resp.VER_ERR);
		}
		// 临时的版本兼容
		{
			/*if(req_v12 != "1.3")
			{
				if(resp.has_user_info())
				{
					UserInfo *ui = resp.mutable_user_info();
					TaskList *task_list = ui->mutable_task_list();

					google::protobuf::RepeatedPtrField<Task> *task = task_list->mutable_task_list();
					int t = task_list->task_list_size();
					for(int i = 0; i < t; i++)
					{
						if(task_list->task_list(i).id() >= 292123
							&& task_list->task_list(i).id() < 293000)
						{
							task->SwapElements(i, t -1);
							task->RemoveLast();
							break;
						}
					}
					t = task_list->task_list_size();
					for(int i = 0; i < t; i++)
					{
						if(task_list->task_list(i).id() >= 293092
							&& task_list->task_list(i).id() < 293999)
						{
							task->SwapElements(i, t -1);
							task->RemoveLast();
							break;
						}
					}
				}
			}*/
		}
	}
	//LOG_USER(LOG_INFO, "LOGIN|result=%d|pf=%d|vip=%d,%d", resp.result(),m_req.domain(), 
	//	m_req.qzonevip().level(), m_req.qzonevip().yearflag());

	LOG_USER(LOG_INFO, "UserName,%s,ClientVersion,%s,ServerVerson,%s,ResVer,%s,Result,%d", user.str(), m_req.version().c_str(), g_logic_info.version.c_str(), resp.version().c_str(), resp.result());
	if(m_ptoolkit->send_protobuf_msg(gDebugFlag, resp, CMD_LOGIN_RESP, user, m_saveReqQueue) != 0)
	{
		LOG_USER(LOG_ERROR, "%s", "send_bin_msg_to_queue(CMD_REGIST_RESP) fail");
	}

/*
	if(resp.result() == resp.OK)
	{
		//ROOM_SYNC_UNIT unit;
		//unit.avatar = 0;
		//unit.posi_x = 0;
		//unit.posi_y = 0;
		//unit.room_id = 1;
		INMAP_PLAYER unit;
		unit.avatar = 0;
		unit.posi_x = 0;
		unit.posi_y = 0;
		unit.map_id = 0;
		unit.name = user;
		unit.session_id = 0;
		g_inmap_manager.update_player(unit);
		g_inmap_manager.debug();
		

		//RoomSyncResp resp;


		//if(m_ptoolkit->send_protobuf_msg(gDebugFlag, resp, CMD_ROOM_SYNC_ON_LOGIN, user, MSG_QUEUE_ID_LOGIC))
		//	LOG(LOG_ERROR, "send CMD_ROOM_SYNC_ON_LOGIN fail");
	}
	*/
/*
	if(resp.result() == resp.OK)
	{
		QQLogReq thereq;
		thereq.set_logtype(thereq.LOGIN);
		dataControl->send_log_to_gateway(user, thereq, m_ptoolkit, thelevel);
	}
*/
	
	//有修改写入
	if(bgetok)
	{
		if(needwriteback)
		{
		// TODO:booljin 稍后整理
			return unlockset_user_data(user);
		}
		else
		{
			return unlock_user_data(user, false, true);
		}
	}

	return RET_DONE;
}

int CLogicLogin::on_set_data_sub(USER_NAME& user, CDataControlSlot* dataControl)
{
	if(dataControl == NULL)
	{
		LOG_USER(LOG_ERROR,"%s", "login write fail");
	}
	else if(dataControl->theSet.result() != DataBlockSet::OK)
	{
		LOG_USER(LOG_ERROR,"%s", "login write result not OK");
	}
	
	return RET_DONE;
}


