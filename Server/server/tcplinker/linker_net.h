#ifndef __LINKER_NET_H__
#define __LINKER_NET_H__

#include <sys/epoll.h>
#include "net/tcpwrap.h"
#include <errno.h>
#include <string.h>
//简单定制下epoll，使用LT模式
extern int gDebug;
class CLinkerNet
{
public:
	static const int MAX_FD = 1024;
	static const int EPOLL_TIME = 5;
	static const int SND_BUFF_SIZE=128*1024;
	static const int RCV_BUFF_SIZE=128*1024;

public:
	CLinkerNet()
	{
		m_events = NULL;
		m_epollFD = -1;
		m_eventCount = 0;
		m_listenFD = -1;
		m_lastEventNum = 0;
		m_fetchIt = 0;
	}
	
	~CLinkerNet()
	{
		//关闭已建立的fd
		
		
		//关闭listen
		if(m_listenFD >= 0)
		{
			del_event(m_listenFD);
			close(m_listenFD);
		}
		
		//关闭epoll
		if(m_epollFD >= 0)
		{
			close(m_epollFD);
			m_epollFD = -1;
		}
		
		//删除接收事件的数组
		if(m_events != NULL)
		{
			delete[] m_events;
			m_events = NULL;
		}

	}

	int init(const char* listenIP, short listenPort)
	{
		int ret = epoll_create(MAX_FD);
		if(ret < 0)
		{
			LOG(LOG_ERROR, "epoll_create(MAX_FD) %d(%s)", errno, strerror(errno));
			return -1;
		}

		m_events = new epoll_event[MAX_FD];
		if(!m_events)
		{
			LOG(LOG_ERROR, "new epoll_event fail");
			return -1;
		}

		m_epollFD = ret;

		CTcpListenSocket s;
		ret = s.init();
		if(ret < 0)
		{
			LOG(LOG_ERROR, "CTcpListenSocket::init %s", s.errmsg());
			return -1;
		}
		
		ret = s.set_nonblock();
		if(ret < 0)
		{
			LOG(LOG_ERROR, "CTcpListenSocket::set_nonblock %s", s.errmsg());
			return -1;
		}

		//reuse
		ret = s.set_reuse_addr();
		if(ret < 0)
		{
			LOG(LOG_ERROR, "CTcpListenSocket::set_reuse_addr %s", s.errmsg());
			return -1;
		}

		ret = s.listen(listenIP, listenPort);
		if(ret < 0)
		{
			LOG(LOG_ERROR, "CTcpListenSocket::listen %s", s.errmsg());
			return -1;
		}

		int fd = s.get_socket();
	
		//epoll加入
		if(add_event(fd, EPOLLIN) < 0)
			return -1;	

		//接管生命期
		m_listenFD = s.pass_socket();

		if(gDebug)
		{
			LOG(LOG_DEBUG, "[%d]listen", m_listenFD);
		}

		return 0;
	}

	int do_poll(int timeMili = EPOLL_TIME)
	{
		int maxIntr = 3;
		int ret = 0;
		m_lastEventNum = 0;
		m_fetchIt = 0;
		while(maxIntr--)
		{
			ret = epoll_wait(m_epollFD, m_events, MAX_FD, timeMili);
			if(ret < 0)
			{
				if(errno == EINTR)
				{
					//中断重试
					continue;
				}
				else
				{
					LOG(LOG_ERROR,	"epoll_wait %d(%s)", errno, strerror(errno));
					return -1; //通知调用者，epoll有问题
				}
			}
			
			m_lastEventNum = ret;
			//ok的
			break;
		}

		if(ret < 0)
		{
			LOG(LOG_ERROR, "too many interrupt");
			return -1;
		}

		//处理事件
//if(ret > 0)
//	LOG(LOG_INFO, "do_poll=%d", ret);
		return 0;
	}

	bool fetch_event(epoll_event*& ptheEvent)
	{
		if(m_fetchIt<0 || m_fetchIt >= m_lastEventNum)
		{
			return false;
		}

		ptheEvent = &(m_events[m_fetchIt]);
		++m_fetchIt;
		return true;
	}

	inline bool is_listen_fd(epoll_event* ptheEvent)
	{
		return ptheEvent->data.fd == m_listenFD;
	}


	int do_accept(int& fd)
	{
		sockaddr_in sk;
		socklen_t len = sizeof(sk);

		int ret = 0;
		int maxIntr = 3;
		while(maxIntr--)
		{
			ret = accept(m_listenFD, (sockaddr*)&sk, &len);
			if(ret < 0)
			{
				if(errno == EINTR)
				{
					continue;
				}

				LOG(LOG_ERROR, "accept(%d)  %d(%s)", m_listenFD, errno, strerror(errno));
				return -1;
			}

			break;
		}

		if(ret < 0)
		{
			LOG(LOG_ERROR,"too many interrupts");
			return -1;
		}

		if(gDebug)
		{
			LOG(LOG_DEBUG, "[%d]accpet", ret);
		}

		CTcpSocket theSocket;
		theSocket.set_socket(ret);
		if(theSocket.set_nonblock()!=0)
		{
			LOG(LOG_ERROR, "fd=%d set_nonblock %s", ret, theSocket.errmsg());
			return -1;
		}
		
		if(theSocket.set_rcv_buffsize(RCV_BUFF_SIZE)!=0)
		{
			LOG(LOG_ERROR, "fd=%d set_rcv_buffsize %s", ret, theSocket.errmsg());
			return -1;
		}

		//epoll加入
		fd = theSocket.pass_socket();
		if(add_event(fd, EPOLLIN) < 0)
		{
			close(fd);
			return -1;
		}	

		return 0;
	}

	//返回-1错误，0=立即可用，1=需要等待
	int do_connect(int& fd, string ip, unsigned short port, bool forceWait)
	{
		int ret = 0;
		CTcpClientSocket client;
		ret = client.init();
		if(ret < 0)
		{
			LOG(LOG_ERROR, "CTcpClientSocket init fail %s", client.errmsg());
			return -1;
		}

		if(client.set_nonblock()!=0)
		{
			LOG(LOG_ERROR, "CTcpClientSocket set_nonblock fail %s", client.errmsg());
			return -1;
		}

		if(client.set_snd_buffsize(CLinkerNet::SND_BUFF_SIZE) != 0)
		{
			LOG(LOG_ERROR, "CTcpClientSocket set_snd_buffsize(%d) fail %s", CLinkerNet::SND_BUFF_SIZE, client.errmsg());
			return -1;
		}

		int maxintr = 3;
		int cret = 0;
		while(maxintr--)
		{
			ret = client.connect(ip, port);
			if(ret != 0)
			{
				if(gDebug)
				{
					LOG(LOG_DEBUG, "[%d]connect, ret=%d, %s", client.get_socket(), ret, client.errmsg());
				}
				if(errno == EINTR)
					continue;
				else if(errno != EINPROGRESS)
				{
					LOG(LOG_ERROR, "errmsg:%s", client.errmsg());
					return -1;
				}
				else
				{
					cret = 1;
				}
				
				break;
			}
			else
			{
				cret = 0;
				break;
			}
		}

		if(ret < 0 && cret!=1)
		{
			LOG(LOG_ERROR, "too many interrupts");
			return -1;
		}

		//传递给fd
		fd = client.pass_socket();
		int events = EPOLLIN;
		//epoll加入
		if(cret==1 || !forceWait)
		{
			//要等可写
			events |= EPOLLOUT;
		}
		
		ret= add_event(fd, events);
		
		if(gDebug)
		{
			LOG(LOG_DEBUG, "[%d]cret=%d, forceWait=%d, add_event(%d)=%d",fd, cret, forceWait, events,ret);
		}

		if(ret < 0)
		{
			close(fd);
			fd = -1;
			return -1;
		}	

		return cret;
	}


	void close_fd(int fd)
	{
		if(gDebug)
		{
			LOG(LOG_DEBUG, "[%d] closed", fd);
		}
		del_event(fd);
		shutdown(fd, SHUT_RDWR);
		close(fd);
	}

	int add_event(int fd, unsigned int flag)
	{
		if(m_eventCount >= MAX_FD)
		{
			LOG(LOG_ERROR, "add_event current(%u) >= max(%u)", m_eventCount, MAX_FD);
			return -1;
		}
		
		struct epoll_event ev;
		ev.events = flag;
		ev.data.fd = fd;
		int ret = epoll_ctl(m_epollFD, EPOLL_CTL_ADD, fd, &ev);
		if(ret < 0)
		{
			LOG(LOG_ERROR, "epoll_ctl(EPOLL_CTL_ADD) %d(%s)", errno, strerror(errno));
			return -1;
		}

		++m_eventCount;
		return 0;
	}

	int del_event(int fd)
	{
		epoll_event ignored;
		if(epoll_ctl(m_epollFD, EPOLL_CTL_DEL, fd, &ignored) < 0)
		{
			LOG(LOG_ERROR, "epoll_ctl(EPOLL_CTL_DEL)  %d(%s)", errno, strerror(errno));
			return -1;
		}

		if(m_eventCount>0)
			--m_eventCount;

		return 0;
	}

	int modify_event(int fd, unsigned int flag)
	{
		struct epoll_event ev;
		ev.events = flag;
		ev.data.fd = fd;
		int ret = epoll_ctl(m_epollFD, EPOLL_CTL_MOD, fd, &ev);
		if(ret < 0)
		{
			LOG(LOG_ERROR, "epoll_ctl(EPOLL_CTL_MOD) %d(%s)", errno, strerror(errno));
			return -1;
		}

		return 0;
	}

protected:
	epoll_event * m_events;//epoll用的events
	int m_epollFD;
	int m_eventCount;
	int m_listenFD;
	int m_lastEventNum;
	int m_fetchIt;
};

#endif

