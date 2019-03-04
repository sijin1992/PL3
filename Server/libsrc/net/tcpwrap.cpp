#include  "tcpwrap.h"
#include <fcntl.h>
#include <string.h>
#include <errno.h>
#include <stdio.h>

char CTcpSocket::m_errmsg[256];

string CTcpSocket::addr_to_str(in_addr_t addr)
{
	in_addr st;
	st.s_addr = addr;
	return inet_ntoa(st);
}

int CTcpSocket::str_to_addr(string str,  in_addr& addr)
{
	if(inet_aton(str.c_str(), &addr))
	{
		return 0;
	}
	else
	{
		return -1;
	}
}

int CTcpSocket::str_to_addr(string str, unsigned int& addrint)
{
	in_addr addr;
	if(inet_aton(str.c_str(), &addr))
	{
		addrint = addr.s_addr;
		return 0;
	}
	else
	{
		return -1;
	}
}


void CTcpSocket::set_addr(sockaddr_in& sockaddr, in_addr_t addr, unsigned short port)
{
	memset(&sockaddr, 0x0, sizeof(sockaddr));
	sockaddr.sin_family = AF_INET;
	sockaddr.sin_port = htons(port);
	sockaddr.sin_addr.s_addr = addr;
}

CTcpSocket::CTcpSocket()
{
	m_socket = -1;
	m_errmsg[0] = 0;
}

CTcpSocket::~CTcpSocket()
{	
	close();
}

int CTcpSocket::init()
{
	if(m_socket >= 0)
	{
		close();
	}

	m_socket = socket(AF_INET, SOCK_STREAM, 0);
	if(m_socket < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "socket() %d(%s)", errno, strerror(errno));
		return -1;
	}

	return 0;
}

int CTcpSocket::set_nonblock()
{
	if(m_socket < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "not inited");
		return -1;
	}
	
	int flags = fcntl(m_socket, F_GETFL, 0);
	if(flags < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "fcntl(F_GETFL) %d(%s)", errno, strerror(errno));
		return -1;
	}

	if(fcntl(m_socket, F_SETFL, flags | O_NONBLOCK) < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "fcntl(F_SETFL, %d) %d(%s)", flags, errno, strerror(errno));
		return -1;
	}

	return 0;
}

int CTcpSocket::set_rcv_timeout(unsigned int s/*秒*/, unsigned int us /*微秒*/)
{
	if(m_socket < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "not inited");
		return -1;
	}
	timeval tpstime;
	memset(&tpstime, 0x0, sizeof(tpstime));
	tpstime.tv_usec = us;
	tpstime.tv_sec = s;
	if(setsockopt(m_socket, SOL_SOCKET, SO_RCVTIMEO, &tpstime, sizeof(tpstime)) < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "setsockopt(SO_RCVTIMEO, (%u,%u)) %d(%s)", s, us, errno, strerror(errno));
		return -1;
	}
	return 0;
}

int CTcpSocket::set_snd_timeout(unsigned int s/*秒*/, unsigned int us /*微秒*/)
{
	if(m_socket < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "not inited");
		return -1;
	}
	timeval tpstime;
	memset(&tpstime, 0x0, sizeof(tpstime));
	tpstime.tv_usec = us;
	tpstime.tv_sec = s;
	if(setsockopt(m_socket, SOL_SOCKET, SO_SNDTIMEO, &tpstime, sizeof(tpstime)) < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "setsockopt(SO_SNDTIMEO, (%u,%u)) %d(%s)",  s, us, errno, strerror(errno));
		return -1;
	}
	return 0;
}

int CTcpSocket::set_snd_buffsize(int size)
{
	if(m_socket < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "not inited");
		return -1;
	}

	if(setsockopt(m_socket, SOL_SOCKET, SO_SNDBUF, &size, sizeof(int)) < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "setsockopt(SO_SNDBUF, (%d)) %d(%s)", size, errno, strerror(errno));
		return -1;
	}
	return 0;
}

int CTcpSocket::set_rcv_buffsize(int size)
{
	if(m_socket < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "not inited");
		return -1;
	}

	if(setsockopt(m_socket, SOL_SOCKET, SO_RCVBUF, &size, sizeof(int)) < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "setsockopt(SO_RCVBUF, (%d)) %d(%s)", size, errno, strerror(errno));
		return -1;
	}
	return 0;
}

int CTcpSocket::set_reuse_addr()
{
	if(m_socket < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "not inited");
		return -1;
	}

        int iEnable = 1;
        if(setsockopt(m_socket, SOL_SOCKET, SO_REUSEADDR, (char *) &iEnable, sizeof(iEnable)) < 0)
        {
		snprintf(m_errmsg, sizeof(m_errmsg), "setsockopt(SO_REUSEADDR) %d(%s)",  errno, strerror(errno));
		return -1;
        }
        return 0;
 }


int CTcpSocket::get_sock_name(in_addr_t& addr, unsigned short& port)
{
	if(m_socket < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "not inited");
		return -1;
	}
	sockaddr_in addr_in;
	socklen_t len = sizeof(addr_in);
	int ret = getsockname(m_socket, (sockaddr*)(&addr_in), &len);
	if(ret < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "getsockname %d(%s)", errno, strerror(errno));
		return -1;
	}

	addr = addr_in.sin_addr.s_addr;
	port = ntohs(addr_in.sin_port);
	
	return 0;
}

int CTcpSocket::get_peer_name(in_addr_t& addr, unsigned short& port)
{
	if(m_socket < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "not inited");
		return -1;
	}
	sockaddr_in addr_in;
	socklen_t len = sizeof(addr_in);
	int ret = getpeername(m_socket, (sockaddr*)(&addr_in), &len);
	if(ret < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "getpeername %d(%s)", errno, strerror(errno));
		return -1;
	}

	addr = addr_in.sin_addr.s_addr;
	port = ntohs(addr_in.sin_port);
	
	return 0;
}


int CTcpSocket::write(const char* buff, int len)
{
	if(m_socket < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "not inited");
		return -1;
	}
	
	int ret = ::write(m_socket, buff, len);
	if(ret < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "write  %d(%s)", errno, strerror(errno));
	}

	return ret;
}

int CTcpSocket::read(char* buff, int len)
{
	if(m_socket < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "not inited");
		return -1;
	}
	
	int ret = ::read(m_socket, buff, len);
	if(ret < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "read  %d(%s)", errno, strerror(errno));
	}

	return ret;
}

int CTcpSocket::read_until(char* buff, int len, const char* end, char*& pend)
{
	//留一个结束符的位置0
	pend = NULL;
	int ret = ::read(m_socket, buff, len);
	if(ret < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "read  %d(%s)", errno, strerror(errno));
	}
	else if(ret > 0)
	{
		int endLen = strlen(end);
		//自后向前匹配，end不会太长，所以不做优化了
		char* buffend = (buff+len-1);

		char* cur = buffend-endLen+1; //可能匹配的最后一个位置
		bool found = false;
		int pos = 0;
		for( int i=0; i<len-endLen; ++i, --cur)
		{
			for(pos = 0; pos < endLen; ++pos)
			{
				if(cur[pos] != end[pos])
				{
					break;
				}
			}
			
			if(pos == endLen)
			{
				found = true;
				break;
			}
		}

		if(found)
		{
			pend = cur;
		}		
	}

	return ret;
}

int CTcpSocket::close()
{
	if(m_socket < 0)
	{
		return 0;
	}
	
	//书上说，close要等改socket fd的引用为零的时候才关闭并发送结束分节，shutdown保证一定发送。
	shutdown(m_socket, SHUT_RDWR);
	int ret=0;
	int times=3;//保险
	if(m_socket >= 0)
	{
		while(times--)
		{
			if ((ret = ::close(m_socket)) == 0 || errno != EINTR)
			  	break;
		}
	}

	if(ret < 0 )
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "close fail %d(%s)", errno, strerror(errno));
	}
	else
		m_socket = -1;
	
	return ret;
}



int CTcpClientSocket::connect(string addr, unsigned short port)
{	
	if(m_socket < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "not inited");
		return -1;
	}
	
	m_addr = addr;
	m_port = port;
	in_addr addr_t;
	if(str_to_addr(addr, addr_t) != 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "str_to_addr(%s) fail not valid", addr.c_str());
		return -1;
	}

	set_addr(m_sk, addr_t.s_addr, port);
	int ret = ::connect(m_socket, (sockaddr*)&m_sk, sizeof(m_sk));
	if(ret < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "connect(%s(%u),%u)  %d(%s)", m_addr.c_str(), addr_t.s_addr, port, errno, strerror(errno));
	}


	return ret;
}

int CTcpListenSocket::listen(string addr, unsigned short port, int backLog)
{
	if(m_socket < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "not inited");
		return -1;
	}
	
	m_addr = addr;
	m_port = port;
	in_addr addr_t;
	if(str_to_addr(addr, addr_t) != 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "str_to_addr(%s) fail not valid", addr.c_str());
		return -1;
	}

	set_addr(m_sk, addr_t.s_addr, port);
	int ret = ::bind(m_socket, (sockaddr*)&m_sk, sizeof(m_sk));
	if(ret < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "bind(%s(%u),%u)  %d(%s)", m_addr.c_str(), addr_t.s_addr, port, errno, strerror(errno));
		return -1;
	}

	ret = ::listen(m_socket, backLog);
	if(ret < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "listen(%d)  %d(%s)", backLog, errno, strerror(errno));
	}

	return ret;
}

int CTcpListenSocket::accept(CTcpAcceptedSocket& newSocket)
{
	if(m_socket < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "not inited");
		return -1;
	}
	
	sockaddr_in* p = newSocket.getSK();
	socklen_t len = sizeof(*p);
	int ret = ::accept(m_socket, (sockaddr*)p, &len);
	if(ret < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "accept()  %d(%s)",  errno, strerror(errno));
	}
	else
	{
		newSocket.set_socket(ret);
	}

	return ret;
}


