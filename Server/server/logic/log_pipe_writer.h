#ifndef __LOG_PIPE_WRITER_H__
#define __LOG_PIPE_WRITER_H__
#include "log/writer_proxy.h"
#include "toolkit.h"
class CLogPipeWriter : public CWriterProxy
{
public:
	CLogPipeWriter(CToolkit &toolkit, unsigned int queueID, unsigned int desSvrID)
		:m_toolkit(toolkit), m_queueID(queueID), m_desSvrID(desSvrID)
	{
	
	}

	int writeData(const char *data, unsigned int size, int level )
	{
		if( level < LOG_EXT_INFO )
		{
			return 0;
		}
		char *buff = m_toolkit.send_buff();
		unsigned int buffLen = m_toolkit.send_buff_len();
		if( size > buffLen ) //buff ²»¹»ÓÃ
		{
			LOG(LOG_ERROR, "buff size not enough size:%u > buffLen:%u ", size, buffLen);
			return -1;
		}
		memcpy(buff, data, size);
		if( m_toolkit.send_to_queue(CMD_GAME_LOG_REPORT_REQ, m_queueID, size, m_desSvrID) != 0 )
		{
			LOG(LOG_ERROR, "send_to_queue CMD_GAME_LOG_REPORT_REQ failed, data:\"%s\"", string(buff,size).c_str());
			return -1;
		}
		return (int)size;
	}
protected:
	CToolkit &m_toolkit;
	unsigned m_queueID;
	unsigned int m_desSvrID;
};

#endif
