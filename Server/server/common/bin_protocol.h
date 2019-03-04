#ifndef __BIN_PROTOCOL_H__
#define __BIN_PROTOCOL_H__

#include "msg_define.h"

class CBinProtocol
{
	public:
		CBinProtocol()
		{
			m_buff = NULL;
			m_bufflen = 0;
		}


		CBinProtocol(char* buff, int bufflen)
		{
			bind(buff, bufflen);
		}
		
		inline void bind(char* buff, int bufflen)
		{
			m_buff = buff;
			m_bufflen = bufflen;
		}

		inline bool valid()
		{
			return (m_bufflen >= (int)sizeof(BIN_PRO_HEADER)) && (head()->valid()) && ((int)(head()->parse_len()) == m_bufflen);
		}

		inline BIN_PRO_HEADER* head()
		{
			return (BIN_PRO_HEADER*)(m_buff);
		}

		inline char* packet()
		{
			return packet_len() > 0 ? m_buff + sizeof(BIN_PRO_HEADER) : NULL;
		}

		inline int packet_len()
		{
			return m_bufflen - sizeof(BIN_PRO_HEADER);
		}

		inline int total_len(int packetLen)
		{
			return packetLen + sizeof(BIN_PRO_HEADER);
		}

		inline char* buff()
		{
			return m_buff;
		}

		inline int buff_len()
		{
			return m_bufflen;
		}

	protected:
		char* m_buff;
		int m_bufflen;
};

#endif

