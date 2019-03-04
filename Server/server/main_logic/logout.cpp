#include "logout.h"
#include "online_cache.h"
//#include "inmap_player_manager.h"
#include "shm/mmap_wrap.h"
#include "common/user_distribute.h"
#include "data_cache/data_cache_api.h"
#include "data_control.h"

extern int gDebugFlag;
extern COnlineCache gOnlineCache;
extern unsigned int MSG_QUEUE_ID_LOGIC;
extern unsigned int MSG_QUEUE_ID_DB;
extern CUserDistribute gDistribute; 
extern unsigned int CHECK_ONLINE_INTERVAL;
extern CShmTimer<unsigned int> gTheTimer;
extern CDataCache gDataCache;
extern unsigned int KICK_USER_TIME;

void CLogicLogout::on_init()
{
}

//��msg�����ʱ�򼤻����
int CLogicLogout::on_active(CLogicMsg& msg)
{
	//������
	unsigned int cmd = m_ptoolkit->get_cmd(msg);
	if(gDebugFlag)
	{
		LOG(LOG_DEBUG, "CLogicLogout[%u] recv cmd[0x%x]", m_id, cmd);
	}

	if(cmd == CMD_LOGOUT_REQ)
	{
		CBinProtocol binreq;
		if( m_ptoolkit->parse_bin_msg(msg, binreq) != 0)
		{
			return RET_DONE;
		}

		//if online ? ����Ҫ��
		
		//do something
		LogoutReq req;
		if(!req.ParseFromArray(binreq.packet(), binreq.packet_len()))
		{
			LOG(LOG_ERROR, "LogoutReq.ParseFromArray fail");
			return RET_DONE;
		}

		USER_NAME user = binreq.head()->parse_name();
		int nothing = req.nothing();
		
		//cout << "user:" << binreq.head()->parse_name().str() << " with nothing:" << req.nothing() << " logouted" << endl;
		if(nothing == 2)
			do_logout(user, nothing, &msg);
		else 
			do_logout(user, nothing, NULL);

	}
	
	else if(cmd == CMD_LOGIC_CHECKONLINE_REQ)
	{
		//��ʱ����Ƿ����ߵ�
		unsigned int theIdx = m_ptoolkit->get_timeout_flag(msg);
		USER_NAME theUser;
		ONLINE_CACHE_UNIT* ptheUnit;
		if(gOnlineCache.checkRef(theIdx, KICK_USER_TIME, theUser, ptheUnit)!=0)
		{
			//do logout
			if(gDebugFlag)
			{
				LOG(LOG_DEBUG, "%s|online timeout kicked", theUser.str());
			}
			do_logout(theUser, 3, NULL);
		}
		else
		{
			//�����´εļ��
			if(gTheTimer.get_timer()->set_timer_s(ptheUnit->selfCheckTimerID, theIdx, CHECK_ONLINE_INTERVAL)!=0)
			{
				//�������������Ҽ��������ˣ��ߵ�
				LOG(LOG_ERROR, "shit no more timer, force logout");
				do_logout(theUser, 4, NULL);
			}
			/*
			if(gDebugFlag)
			{
				cout << "--------------------set ok-----------------------" << endl;
				gTheTimer.get_timer()->debug(cout);
				LOG(LOG_DEBUG, "%s|online check idx=%u set_timer(%u,%us)", theUser.str(), theIdx, ptheUnit->selfCheckTimerID, CHECK_ONLINE_INTERVAL);
			}*/
		}
	}
	else
		LOG(LOG_ERROR, "unexpect cmd=0x%x" , cmd);

	return RET_DONE;
}

//��������ǰ����һ��
void CLogicLogout::on_finish()
{
}

CLogicProcessor* CLogicLogout::create()
{
	return new CLogicLogout;
}

//nothing=0 �ͻ���
//nothing=1 ����
//nothing=2 �ظ���¼��dbsvr���͹�����
//nothing=3 check online ��ʱ
//nothing=4 �޷����䶨ʱ��
void CLogicLogout::do_logout(USER_NAME& user, int nothing, CLogicMsg* pmsgfromdb)
{
	LOG(LOG_INFO, "%s|LOGOUT|nothing=%d", user.str(), nothing);

	//������־
	/*
	QQLogReq thereq;
	thereq.set_logtype(thereq.LOGOUT);
	CDataControlSlot::send_log_to_gateway(user, thereq, m_ptoolkit);
	*/
	gOnlineCache.onLogout(user, m_ptoolkit);
	//g_inmap_manager.erase(user);
	//g_inmap_manager.debug();


	if(nothing != 1)
	{
		//�ذ��������Ĳ���Ҫ����
		LogoutResp resp;
		resp.set_result(LogoutResp_Result_OK);
		if(!resp.SerializeToArray(m_ptoolkit->send_binbody_buff(), m_ptoolkit->send_binbody_buff_len()))
		{
			LOG(LOG_ERROR, "LogoutResp.SerializeToArray fail");
		}
	
		if(m_ptoolkit->send_bin_msg_to_queue(CMD_LOGOUT_RESP, user, MSG_QUEUE_ID_LOGIC, resp.ByteSize()) != 0)
		{
			LOG(LOG_ERROR, "send_bin_msg_to_queue(%d) fail", MSG_QUEUE_ID_LOGIC);
		}
	}

	
	if(nothing == 2)
	{
		//�ذ�CMD_DBCACHE_LOGOUT_RESP
		if(m_ptoolkit->send_bin_msg_to_queue(CMD_DBCACHE_LOGOUT_RESP, user,
			MSG_QUEUE_ID_DB, 0, 
			m_ptoolkit->get_src_server(*pmsgfromdb), m_ptoolkit->get_src_handle(*pmsgfromdb)) != 0)
		{
			LOG(LOG_ERROR, "CMD_DBCACHE_LOGOUT_RESP send_to_queue(%u) fail", MSG_QUEUE_ID_DB);
		}
	}
	else
	{
		//����CMD_DBCACHE_LOGOUT_REQ��
		unsigned int desSvrID;
		if(gDistribute.get_svr(user, desSvrID)==0)
		{
			if(m_ptoolkit->send_bin_msg_to_queue(CMD_DBCACHE_LOGOUT_REQ, user,
				MSG_QUEUE_ID_DB, 0, desSvrID) != 0)
			{
				LOG(LOG_ERROR, "CMD_DBCACHE_LOGOUT_REQ send_to_queue(%u) fail", MSG_QUEUE_ID_DB);
			}
		}
	}

	//ɾ�����ػ���
	CDataCacheTmp tmpcache;
	if(tmpcache.init(&gDataCache) == tmpcache.OK)
	{
		tmpcache.del(user);
	}
}
