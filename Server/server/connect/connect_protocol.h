#ifndef __CONNECT_PROTOCOL_H__
#define __CONNECT_PROTOCOL_H__

#include "../common/msg_define.h"

class CConnectProtocol
{
	public:
		CConnectProtocol()
		{
			m_buff = NULL;
			m_bufflen = 0;
		}


		CConnectProtocol(char* buff, int bufflen)
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
			return m_bufflen >= (int)(sizeof(MSG_SESSION));
		}

		inline MSG_SESSION* session()
		{
			return (MSG_SESSION*)(m_buff);
		}

		inline char* packet()
		{
			return packet_len()>0 ? m_buff + sizeof(MSG_SESSION) : NULL;
		}

		inline int packet_len()
		{
			return m_bufflen - sizeof(MSG_SESSION);
		}

		inline int total_len(int packetLen)
		{
			return packetLen + sizeof(MSG_SESSION);
		}

	protected:
		char* m_buff;
		int m_bufflen;
};

#endif

