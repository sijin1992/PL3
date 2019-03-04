
#include "heart_beat.h"
#include "online_cache.h"
#include "proto/logprotocol.pb.h"


extern int gDebugFlag;
extern COnlineCache gOnlineCache;

void CLogicHeartBeat::on_init()
{
}

//有msg到达的时候激活对象
int CLogicHeartBeat::on_active(CLogicMsg& msg)
{
	unsigned int cmd = m_ptoolkit->get_cmd(msg);
	//解析包
	if(gDebugFlag)
	{
		LOG(LOG_DEBUG, "CLogicHeartBeat[%u] recv cmd[0x%x]", m_id, cmd);

	}

	
	if(cmd == CMD_HEART_BEAT_REQ)
	{
		unsigned int queueID = m_ptoolkit->get_queue_id(msg);
		CBinProtocol binreq;
		if( m_ptoolkit->parse_bin_msg(msg, binreq) != 0)
		{
			return RET_DONE;
		}

		USER_NAME user = binreq.head()->parse_name();
		
		HeartBeatResp resp;

		ONLINE_CACHE_UNIT * punit;
		if(gOnlineCache.getOnlineUnit(user, punit)!=0)
		{
			resp.set_result(HeartBeatResp_Result_FAIL);
		}
		else if(punit == NULL)
		{
			resp.set_result(HeartBeatResp_Result_FAIL);
			LOG(LOG_ERROR, "not online");
		}
		else
		{
			resp.set_result(HeartBeatResp_Result_OK);
			resp.set_nowtime(time(NULL));
		}
		
		if(!resp.SerializeToArray(m_ptoolkit->send_binbody_buff(), m_ptoolkit->send_binbody_buff_len()))
		{
			LOG(LOG_ERROR, "SerializeToArray fail");
			return RET_DONE;
		}

		if(m_ptoolkit->send_bin_msg_to_queue(CMD_HEART_BEAT_RESP, user, queueID, resp.ByteSize()) != 0)
		{
			LOG(LOG_ERROR, "send_bin_msg_to_queue(%d) fail", queueID);
			return RET_DONE;
		}


		return RET_DONE;

	}
	else if(cmd == CMD_USERLOG_REQ)
	{
		//记录日志,写在这里图个方便
		LogReportReq req;
		USER_NAME tmpuser;
		if(m_ptoolkit->parse_protobuf_msg(gDebugFlag, msg, tmpuser, req)!=0)
		{
			LOG(LOG_ERROR, "parse LogReportReq fail");
		}
		else
		{
			LOG(LOG_INFO, "%s|USERLOG|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d", 
				tmpuser.str(), req.logid(), req.logval1(), req.logval2(), req.logval3(), req.logval4(),
				req.logval5(), req.logval6(), req.logval7(), req.logval8(), req.logval9());
		}
		
	}
	else
		LOG(LOG_ERROR, "unexpect cmd=0x%x" , cmd );

	return RET_DONE;
}

//对象销毁前调用一次
void CLogicHeartBeat::on_finish()
{
}

CLogicProcessor* CLogicHeartBeat::create()
{
	return new CLogicHeartBeat;
}

