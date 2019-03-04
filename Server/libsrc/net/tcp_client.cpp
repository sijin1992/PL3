#include "tcp_client.h"
#include <string.h>

char CTcpClient::m_errmsg[256];

CTcpClient::CONFIG::CONFIG()
{
	autoReconnect = true;
	errClose = 3;
	tryTimes = 1;
	randIP = true;
	timeout = 0;
	useSelect = false;
	ignoreSIGPIPE = true;
	sndBuffSize = -1;
	rcvBuffSize = -1;
}

CTcpClient::CTcpClient()
{
	m_ipCount = 0;
	m_curIdx = 0;
	m_errcount = 0;
	m_closed = true;

	m_errmsg[0] = 0;
}

const char* CTcpClient::errmsg()
{	
	strncpy(m_errmsg, m_socket.errmsg(), sizeof(m_errmsg));
	return m_errmsg;
}

int CTcpClient::init(bool doConnect)
{
	if (m_config.ignoreSIGPIPE)
	{
		::signal(SIGPIPE, SIG_IGN);
	}
	else
	{
		::signal(SIGPIPE, SIG_DFL);
	}
	int ret = m_socket.init();
	if (ret == 0)
	{
		if (doConnect)
		{
			ret = do_connect();
		}
	}
	return ret;
}

int CTcpClient::do_connect()
{
	int ret = m_socket.connect(m_config.ips[m_curIdx], m_config.ports[m_curIdx]);
	if (ret < 0)
	{
		m_closed = true;
	}
	else
	{
		m_closed = false;
	}
	return ret;
}

int CTcpClient::close()
{
	int ret = m_socket.close();
	if (ret < 0)
	{
		m_closed = true;
	}
	else
	{
		m_closed = false;
	}
	return ret;
}

int CTcpClient::send(const char* src, int len)
{
	return m_socket.write(src, len);
}

int CTcpClient::recieve(char* dst, int len)
{
	return m_socket.read(dst, len);
}
