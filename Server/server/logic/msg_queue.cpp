#include "msg_queue.h"

int CMsgQueuePipe::get_msg(CLogicMsg& msg)
{
	unsigned int len = msg.buff_len();
	int ret = m_queue.read(msg.buff(), len);
	if(ret == 0)
	{
		if(!msg.verify_size(len))
		{
			LOG(LOG_ERROR, "CMsgQueuePipe msg.verify_size(%u) fail", len);
			return ERROR;
		}
		msg.head()->queueID = id;
		if(m_pdebug && *m_pdebug)
		//if(true)
		{
			string desSvr = CTcpSocket::addr_to_str(msg.head()->desServerID);
			string srcSvr = CTcpSocket::addr_to_str(msg.head()->srcServerID);
			LOG(LOG_DEBUG, "recv msg(cmd=0x%x,srcSvr=%u(%s),srcID=%u,desSvr=%u(%s),desID=%u,queue=%u,bodySize=%u)", 
				msg.head()->cmdID, msg.head()->srcServerID, srcSvr.c_str(), msg.head()->srcHandleID,
				msg.head()->desServerID, desSvr.c_str(), msg.head()->desHandleID, id, msg.head()->bodySize);
		}
		return OK;
	}
	else if(ret < 0)
	{
		LOG(LOG_ERROR, "queue(%u) read %s", id, m_queue.errmsg());
		return ERROR;
	}
	else if(ret == 1)
	{
		return EMPTY;
	}
	else
	{
		if(!m_allowNew)
		{
			LOG(LOG_ERROR, "msg too large and msgbuff replace not allowed");
			return ERROR;
		}
		
		char* buff;
		ret = m_queue.read_new(buff, len);
		if(ret == 0)
		{
			msg.replace_buffer(buff, len, true);
			if(!msg.verify_size(len))
			{
				LOG(LOG_ERROR, "queue(%u) verify_size(%u) fail", id, len);
				return ERROR;
			}
			msg.head()->queueID = id;
			if(m_pdebug && *m_pdebug)
			{
				string desSvr = CTcpSocket::addr_to_str(msg.head()->desServerID);
				string srcSvr = CTcpSocket::addr_to_str(msg.head()->srcServerID);
				LOG(LOG_DEBUG, "recv newmem msg(cmd=0x%x,srcSvr=%u(%s),srcID=%u,desSvr=%u(%s),desID=%u,queue=%u,bodySize=%u)", 
					msg.head()->cmdID, msg.head()->srcServerID, srcSvr.c_str(), msg.head()->srcHandleID,
					msg.head()->desServerID, desSvr.c_str(), msg.head()->desHandleID, id, msg.head()->bodySize);
				
			}
			return OK;
		}
		else if(ret < 0)
		{
			LOG(LOG_ERROR, "queue(%u) readnew %s", id, m_queue.errmsg());
			return ERROR;
		}
		else
			return EMPTY;
	}
}

int CMsgQueuePipe::send_msg(CLogicMsg& msg)
{
	int ret = m_queue.write(msg.buff(), msg.data_len());
	if(ret == 0)
	{
		if(m_pdebug && *m_pdebug)
		//if(true)
		{
			string desSvr = CTcpSocket::addr_to_str(msg.head()->desServerID);
			string srcSvr = CTcpSocket::addr_to_str(msg.head()->srcServerID);
			LOG(LOG_DEBUG, "send msg(cmd=0x%x,srcSvr=%u(%s),srcID=%u,desSvr=%u(%s),desID=%u,queue=%u,bodySize=%u)", 
				msg.head()->cmdID, msg.head()->srcServerID, srcSvr.c_str(), msg.head()->srcHandleID,
				msg.head()->desServerID, desSvr.c_str(), msg.head()->desHandleID, id, msg.head()->bodySize);
		}
	}
	else if(ret == 1)
	{
		LOG(LOG_ERROR,"quque %u is full", id);
		LOG(LOG_INFO,"quque %u is full", id);
		return -1;
	}
	else
	{
		LOG(LOG_ERROR,"send to queue(%u) %s", id, m_queue.errmsg());
		return -1;
	}
	
	return 0;
}


