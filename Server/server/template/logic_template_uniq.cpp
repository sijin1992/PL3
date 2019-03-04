#include "logicYYY.h"

void CLogicYYY::on_init()
{
}

int CLogicYYY::on_active(CLogicMsg& msg)
{
	if(gDebug)
	{
		LOG(LOG_DEBUG, "CLogicYYY[%u] recv cmd[0x%x]", m_id, m_ptoolkit->get_cmd(msg));

	}

	unsigned int cmd = m_ptoolkit->get_cmd(msg);

	//解析包
	if(cmd == 0)
	{
		CBinProtocol binreq;
		if( m_ptoolkit->parse_bin_msg(msg, binreq) != 0)
		{
			return RET_DONE;
		}

		//!!to-do: modify the req class
		/*
		YYYReq req;
		if(!req.ParseFromArray(binreq.packet(), binreq.packet_len()))
		{
			LOG(LOG_ERROR, "YYYReq.ParseFromArray fail");
			return RET_DONE;
		}
		*/

		USER_NAME user = binreq.head()->parse_name();
		
		/*XXXResp resp;
		if(!resp.SerializeToArray(m_ptoolkit->send_binbody_buff(), m_ptoolkit->send_binbody_buff_len()))
		{
			LOG(LOG_ERROR, "XXXResp.SerializeToArray fail");
			return RET_DONE;
		}
		
		if(m_ptoolkit->send_bin_msg_to_queue(CMD_XXX, user, 
			m_ptoolkit->get_queue_id(msg), resp.ByteSize(), 
			m_ptoolkit->get_src_server(msg), m_ptoolkit->get_src_handle(msg)) != 0)
		{
			LOG(LOG_ERROR, "send_bin_msg_to_queue(XXXResp) fail");
			return RET_DONE;
		}*/

	}
	else
		LOG(LOG_ERROR, "unexpect cmd=0x%x" , m_ptoolkit->get_cmd(msg) );

	return RET_DONE;
}

//对象销毁前调用一次
void CLogicYYY::on_finish()
{
}

CLogicProcessor* CLogicYYY::create()
{
	return new CLogicYYY;
}

