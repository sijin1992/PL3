#include "epoll_wrap.h"
#include <sys/epoll.h>
#include <errno.h>
#include <string.h>
#include "tcpwrap.h"
#include <fcntl.h>
#include <assert.h>


CEpollWrap::CEpollWrap(CPacketInterface* ppack, CControlInterface* pcontrol,  timeval* ptimeSource)
{
	m_epollFD = -1;
	m_errmsg[0] = 0;
	m_seq = 0;
	m_events = NULL;
	m_event_max = 0;
	m_packSize = SIZE_PACKET_DEFAULT;
	m_packSizeLimit = SIZE_BUFF_LIMIT;
	m_pPack = ppack;
	m_pControl = pcontrol;
	m_event_current = 0;
	m_ptimenow = ptimeSource;
	m_checkIntervalS = 0;
	m_limitPollinCount = 0;
	m_limitRecvBytes = 0;
	m_idleTimeoutS = 0;
	m_ptimer = NULL;
	m_ptimerMem = NULL;
}

CEpollWrap::~CEpollWrap()
{
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
		m_event_max = 0;
	}
//关闭所有的fd
	for(m_mapIt = m_mapFD.begin(); m_mapIt!=m_mapFD.end(); ++m_mapIt)
	{
		close(m_mapIt->first);
	}

	m_mapFD.clear();
//关闭timer
	if(m_ptimer != NULL)
	{
		delete m_ptimer;
		m_ptimer = NULL;
	}

	if(m_ptimerMem != NULL)
	{
		delete[] m_ptimerMem;
		m_ptimerMem = NULL;
	}
}


int CEpollWrap::create(unsigned int size,  bool useET, bool enableTimer)
{
	int ret = epoll_create(size);
	if(ret < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "epoll_create(%u) %d(%s)", size, errno, strerror(errno));
		return -1;
	}

	m_epollFD = ret;
	m_useET = useET;

	m_events = new epoll_event[size];
	assert(m_events);
	m_event_max = size;

	if(enableTimer)
	{
		unsigned int memsize = CTimerPool<int>::mem_size(size);
		m_ptimerMem = new char[memsize];
		memset(m_ptimerMem, 0x0, memsize);
		assert(m_ptimerMem);
		m_ptimer = new CTimerPool<int>(m_ptimerMem, memsize, size, m_ptimenow);

		if(!m_ptimer->valid())
		{
			m_ptimer->passerr(m_errmsg, sizeof(m_errmsg));
			return -1;
		}
	}

	if(m_pControl->hook_create(this) != 0)
		return -1;

	return 0;
}

int CEpollWrap::add_listen(string ip, unsigned int port)
{
	if(m_epollFD < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "epoll not created");
		return -1;
	}

	CTcpListenSocket s;
	int ret = s.init();
	if(ret < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "CTcpListenSocket::init %s", s.errmsg());
		return -1;
	}
	
	ret = s.set_nonblock();
	if(ret < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "CTcpListenSocket::set_nonblock %s", s.errmsg());
		return -1;
	}

	//reuse
	ret = s.set_reuse_addr();
	if(ret < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "CTcpListenSocket::set_reuse_addr %s", s.errmsg());
		return -1;
	}

	ret = s.listen(ip, port);
	if(ret < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "CTcpListenSocket::listen %s", s.errmsg());
		return -1;
	}
	
	int fd = s.get_socket();

	//epoll加入
	if(add_event(fd, EPOLLIN) < 0)
		return -1;
	
	FDINFO info;
	info.fd = fd;
	info.type = TYPE_LISTEN;
	info.sessionID.tcpaddr.ip = s.getSK()->sin_addr.s_addr;
	info.sessionID.tcpaddr.port = s.getSK()->sin_port;
	info.sessionID.tcpaddr.seq = m_seq++;
	info.state.createTime = *m_ptimenow;
	info.state.lastActiveTime = *m_ptimenow;
	info.timerID = 0;
	
	m_mapFD[fd] = info; //插入到map中
	s.pass_socket();//临时对象不再管理这个fd

	return 0;
}



int CEpollWrap::do_poll(unsigned int time_sec, unsigned int time_microsec)
{
	if(m_idleTimeoutS > 0)
		timeout();
		
	if(m_epollFD < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "epoll not created");
		return -1;
	}

	int time_mili = time_sec*1000+time_microsec/1000;
	if(time_mili < 0)
		time_mili = -1;

	unsigned int maxIntr = 3;
	int ret = 0;

	while(maxIntr--)
	{
		ret = epoll_wait(m_epollFD, m_events, m_event_max, time_mili);
		if(ret < 0)
		{
			if(errno == EINTR)
			{
				//中断重试
				continue;
			}
			else
			{
				snprintf(m_errmsg, sizeof(m_errmsg), "epoll_wait %d(%s)", errno, strerror(errno));
				return -1; //通知调用者，epoll有问题
			}
		}
		
		for(int i=0; i<ret; ++i)
		{
			int fd = m_events[i].data.fd;
			int bin = m_events[i].events & EPOLLIN;
			int bout = m_events[i].events & EPOLLOUT;
//cout << "*************" << endl;	
//cout << "DEBUG|" << fd << " has event|in " << bin << "|out " << bout << endl;
//cout << "*************" << endl;	
			m_mapIt = m_mapFD.find(fd);
			if(m_mapIt == m_mapFD.end())
			{
				//交给hook处理
				m_pControl->hook_poll(this, fd, m_events[i].events, NULL);
				continue;
			}

			FDINFO* pinfo = &(m_mapIt->second); //for short

			if(pinfo->type != TYPE_LISTEN && pinfo->type != TYPE_ACCEPT)
			{
				//交给hook处理
				m_pControl->hook_poll(this, fd, m_events[i].events, pinfo);
				continue;
			}

			if( m_events[i].events & EPOLLERR )
			{
				LOG(LOG_ERROR, "fd(%d) poll errer",  pinfo->fd);
				close_session(pinfo);
				continue;
			}

			if(m_events[i].events & EPOLLHUP)
			{
				LOG(LOG_ERROR,"fd(%d) epoll_hup closed",  pinfo->fd);
				close_session(pinfo);
				continue;
			}
			
			if(bin)
			{
				if(pinfo->type == TYPE_LISTEN)
				{
					//listen的内部处理
					on_listen(pinfo);
				}
				else
				{
					on_read(pinfo);
				}
			}
	
			if(bout)
			{
				on_write(pinfo);
			}
			
	
		}

		//处理完毕了
		break;
	}

	if(ret < 0)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "epoll_wait intr more than %d", maxIntr);
		return -1; //通知调用者，epoll有问题
	}
	
	return 0;
}

int CEpollWrap::add_event(int fd, unsigned int flag)
{
	if(m_event_current >= m_event_max)
	{
		LOG(LOG_ERROR, "add_event current(%u) >= max(%u)", m_event_current, m_event_max);
		return -1;
	}
	
	struct epoll_event ev;
	if(m_useET)
		ev.events = EPOLLET;
	else
		ev.events = 0;

	ev.events |= flag;
	ev.data.fd = fd;
	int ret = epoll_ctl(m_epollFD, EPOLL_CTL_ADD, fd, &ev);
	if(ret < 0)
	{
		LOG(LOG_ERROR, "epoll_ctl(EPOLL_CTL_ADD) %d(%s)", errno, strerror(errno));
		return -1;
	}

	++m_event_current;

	//LOG(LOG_DEBUG, "fd(%d) add event %d", fd, flag);

	return 0;
}

int CEpollWrap::del_event(int fd)
{
	epoll_event ignored;
	if(epoll_ctl(m_epollFD, EPOLL_CTL_DEL, fd, &ignored) < 0)
	{
		LOG(LOG_ERROR, "epoll_ctl(EPOLL_CTL_DEL)  %d(%s)", errno, strerror(errno));
		return -1;
	}

	//LOG(LOG_DEBUG, "fd(%d) del event", fd);

	if(m_event_current>0)
		--m_event_current;

	return 0;
}

int CEpollWrap::modify_event(int fd, unsigned int flag)
{
	struct epoll_event ev;
	if(m_useET)
		ev.events = EPOLLET;
	else
		ev.events = 0;

	ev.events |= flag;
	ev.data.fd = fd;
	int ret = epoll_ctl(m_epollFD, EPOLL_CTL_MOD, fd, &ev);
	if(ret < 0)
	{
		LOG(LOG_ERROR, "epoll_ctl(EPOLL_CTL_MOD) %d(%s)", errno, strerror(errno));
	}

	//LOG(LOG_DEBUG, "fd(%d) mod event %d", fd, flag);

	return ret;
}


void CEpollWrap::on_listen(FDINFO* pinfo)
{
//cout << "DEBUG|on_listen--------------------------" << endl; pinfo->debug(//cout); cout << "--------------------------" << endl;
	sockaddr_in sk;
	socklen_t len = sizeof(sk);

	int ret = 0;
	int maxintr =3;
	while(maxintr--)
	{
		ret = accept(pinfo->fd, (sockaddr*)&sk, &len);
		if(ret < 0)
		{
			if(errno == EINTR)
			{
				continue;
			}

			LOG(LOG_ERROR, "accept(%d)  %d(%s)", pinfo->fd, errno, strerror(errno));
			return;
		}

		break;
	}

	if(ret < 0)
	{
		LOG(LOG_ERROR, "too many interrupts");
		return;
	}
	
	CTcpSocket theSocket;
	theSocket.set_socket(ret);
	if(theSocket.set_nonblock()!=0)
	{
		LOG(LOG_ERROR, "fd=%d set_nonblock %s", ret, theSocket.errmsg());
		close(ret);
		return;
	}


	//epoll加入
	if(add_event(theSocket.pass_socket(), EPOLLIN) < 0)
	{
		close(ret);
		return;
	}

	FDINFO info;
	info.fd = ret;
	info.type = TYPE_ACCEPT;
	info.sessionID.tcpaddr.ip = sk.sin_addr.s_addr;
	info.sessionID.tcpaddr.port = sk.sin_port;
	info.sessionID.tcpaddr.seq = m_seq++;
	info.state.createTime = *m_ptimenow;
	info.state.lastActiveTime = *m_ptimenow;

	if(m_idleTimeoutS > 0)
	{
		info.timerID = set_timer(info.fd, m_idleTimeoutS);
	}

	m_mapFD[info.fd] = info; //插入到map中
	m_pControl->on_connect(info.fd, info.sessionID.id);
}

void CEpollWrap::on_write(FDINFO* pinfo)
{
//cout << "DEBUG|on_write--------------------------" << endl; pinfo->debug(cout); cout << "-------------------------" << endl;

	if(!pinfo->writeBuff.inited())
	{
		//恢复成只等待可读
		modify_event(pinfo->fd,EPOLLIN);
		return;
	}

	//如果writebuff中有数据就写,外部已经判断了
	if(pinfo->writeBuff.len() != 0)
	{
	//为了信号打断
		while(true)
		{
			char* buff = pinfo->writeBuff.data();
			unsigned int len = pinfo->writeBuff.len();
			int ret = write(pinfo->fd, buff, len);
			//LOG(LOG_DEBUG, "on_write write(%d)=%d", pinfo->fd, ret);
			if(ret < 0)
			{
				if(errno == EINTR)
				{
					continue;
				}
				else if(errno == EPIPE)
				{
					//LOG(LOG_DEBUG, "write(%d)  %d(%s)",  pinfo->fd, errno, strerror(errno));
					close_session(pinfo);
					return;
				}
				else if(errno == EAGAIN || errno == EWOULDBLOCK)
				{
					break;
				}
				else
				{
					//错误log，走不到吧
					LOG(LOG_ERROR, "write(%d)  %d(%s)",  pinfo->fd, errno, strerror(errno));
					break;				
				}
			}
			else
			{
				//去掉写掉的buff
				pinfo->writeBuff.mv_head(ret);
				break;
			}

			break;
		}
	}
	
	//写了没剩下的就destroy
	if(pinfo->writeBuff.len() == 0)
	{
		pinfo->writeBuff.destroy();
		//恢复成只等待可读
		modify_event(pinfo->fd,EPOLLIN);
	}
	else
	{
		//重新排列下
		pinfo->writeBuff.resize();
	}
}

void CEpollWrap::on_read(FDINFO* pinfo)
{
//cout << "DEBUG|on_read-----------------------" << endl; pinfo->debug(cout); cout << "-------------------------" << endl;

	if(!(pinfo->readBuff.inited()))
	{
		pinfo->readBuff.init(m_packSize, &m_alloc);
	}

	unsigned int totalRead = 0;

	//要读到干干净净
	bool nomore = false;
	while(!nomore) //保护下left
	{
		//现在的buff过小
		if(pinfo->readBuff.left() == 0)
		{
			if(pinfo->readBuff.doubleExt(m_packSizeLimit) != 0)
			{
				//日志
				LOG(LOG_ERROR, "%s", "read buff full!!! cleared");
				//超过限制了，丢弃buff
				pinfo->readBuff.clear();
			}
		}

		//开始的位置
		char* buff = pinfo->readBuff.data() + pinfo->readBuff.len();
		unsigned int left = pinfo->readBuff.left();

		int ret = read(pinfo->fd, buff, left);
		//LOG(LOG_DEBUG, "read(%d)=%d", pinfo->fd, ret);
		if(ret < 0)
		{
			if(errno == EINTR)
			{
				continue;
			}
			else if(errno == EAGAIN || errno == EWOULDBLOCK)
			{
				//没得读了
				break;
			}
			else
			{
				//错误log，走不到吧
				LOG(LOG_ERROR, "read(%d)  %d(%s)",  pinfo->fd, errno, strerror(errno));
				break;
			}
		}
		else if(ret == 0)
		{
			//read=0，对方关闭链接
			//关闭
			//LOG(LOG_DEBUG, "read(%d)=0 closed",  pinfo->fd);
			close_session(pinfo);			
			return;
		}
		else
		{
			totalRead += ret;
			//非阻塞的读，返回字节数小于buff大小就是没的读了
			if((unsigned int)ret < left)
			{
				nomore = true;
			}
			
			//有读到数据
			//使buff中新读到的数据有效
			pinfo->readBuff.mv_tail(ret);

			//解析包的长度
			for(int kkk=0; kkk<100; ++kkk)// 100够了
			{
				unsigned int packLen = 0;
				int packRet = m_pPack->get_packet_len(pinfo->readBuff.data(), pinfo->readBuff.len(), packLen);
				if(packRet == CPacketInterface::RET_OK)
				{
					//packLen有效
					if(pinfo->readBuff.len() < packLen)
					{
						//需要读取更多
						break;
					}
					else
					{
						//分包
						int controlRet = m_pControl->pass_packet(pinfo->fd, pinfo->sessionID.id, pinfo->readBuff.data(), packLen);
						if(controlRet<0)
						{
							//错误日志
							LOG(LOG_ERROR, "m_pControl->pass_packet(%d, %llu, %u) error ",  pinfo->fd, pinfo->sessionID.id, packLen);
						}
						else if(controlRet == 1)
						{
							//close connection
							close_fd(pinfo->fd, pinfo->sessionID.id);
							return;
						}

						
						//LOG(LOG_DEBUG, "m_pControl->pass_packet(%d, %llu, %u) ok ",  pinfo->fd, pinfo->sessionID.id, packLen);
						//去掉已经传递的数据
						pinfo->readBuff.mv_head(packLen);

						//有下一个包的数据,重整buff内部结构
						if(pinfo->readBuff.len() > 0)
							pinfo->readBuff.resize();
						else
							break; //不用分包了
					}
				}
				else if(packRet == CPacketInterface::RET_PACKET_NEED_MORE_BYTES)
				{
					//需要读更多的情况
					break;
				}
				else
				{
					//错误日志
					LOG(LOG_ERROR, "m_pControl->get_packet_len(%d) = %d ",  pinfo->fd, packRet);
					//丢弃
					pinfo->readBuff.clear();
					break;
				}
			}
		}
	}

	//如果这次读完，buff空了就释放掉，节约一点是一点
	if(pinfo->readBuff.len() == 0)
	{
		pinfo->readBuff.destroy();
	}

	//check 一下是否超过限制
	pinfo->state.pollinCount += 1;
	pinfo->state.recvBytes += totalRead;


	pinfo->state.lastActiveTime = *m_ptimenow;

	if(m_checkIntervalS > 0  //按时间段的 =0其实就是一个时间段，不重置
		&& TIMEVAL_SECOND_INTERVAL_PASSED(pinfo->state.lastActiveTime, pinfo->state.lastCheckTime, (int)m_checkIntervalS)
	)
	{
		//有超过检查期限，重置
		pinfo->state.lastPollinCount = 1;
		pinfo->state.lastRecvBytes = totalRead;
		pinfo->state.lastCheckTime = pinfo->state.lastActiveTime;
	}
	else
	{
		pinfo->state.lastPollinCount += 1;
		pinfo->state.lastRecvBytes += totalRead;
		
		if(m_limitPollinCount > 0 && pinfo->state.lastPollinCount >= m_limitPollinCount)
		{
			LOG(LOG_ERROR, "session(%d, %llu)|limit|pollin|%u in %u seconds",  
				pinfo->fd, pinfo->sessionID.id, m_limitPollinCount, m_checkIntervalS);
			close_session(pinfo);
			return;
		}

		if(m_limitRecvBytes > 0 && pinfo->state.lastRecvBytes >= m_limitRecvBytes)
		{
			LOG(LOG_ERROR, "session(%d, %llu)|limit|bytes|%u in %u seconds",  
				pinfo->fd, pinfo->sessionID.id, m_limitRecvBytes, m_checkIntervalS);
			close_session(pinfo);
			return;
		}
	}


	
}

int CEpollWrap::close_fd(int fd, unsigned long long sessionID)
{
	m_mapIt = m_mapFD.find(fd);
	if(m_mapIt == m_mapFD.end())
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "fd=%d not in map", fd);
		return -1;
	}

	FDINFO* pinfo = &(m_mapIt->second); //for short
	if(sessionID != pinfo->sessionID.id)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "fd=%d sessionID(%llu)!=packSessionID(%llu)", fd, pinfo->sessionID.id, sessionID);
		return -1;
	}

	del_event(fd);
	shutdown(fd, SHUT_RDWR);
	close(fd);
	//删除timer
	if(m_idleTimeoutS != 0)
	{
		cancel_timer(pinfo->timerID);
	}
	//pinfo的生命期在erase之后就没有了哦，一定要return
	m_mapFD.erase(fd);
	return 0;
}


int CEpollWrap::write_packet(int fd, unsigned long long sessionID, const char* packet,unsigned int packetLen)
{
//cout << "########################" << endl;
	//检查fd和sessionID
	m_mapIt = m_mapFD.find(fd);
	if(m_mapIt == m_mapFD.end())
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "fd=%d not in map", fd);
		return -1;
	}

	FDINFO* pinfo = &(m_mapIt->second); //for short
	if(sessionID != pinfo->sessionID.id)
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "fd=%d sessionID(%llu)!=packSessionID(%llu)", fd, pinfo->sessionID.id, sessionID);
		return -1;
	}

	//buff空的话尝试直接写
	const char* buff = packet;
	unsigned int len = packetLen;
	if(!pinfo->writeBuff.inited() || pinfo->writeBuff.len() == 0)
	{
		while(len > 0)
		{
			int ret = write(fd, buff, len);
			//LOG(LOG_DEBUG, "derect write(%d)=%d", fd, ret);
			if(ret < 0)
			{
				if(errno == EINTR)
				{
					continue;
				}
				else if(errno == EPIPE)
				{
					//关闭链接
					snprintf(m_errmsg, sizeof(m_errmsg), "fd=%d session=%llu write EPIPE closed", fd, sessionID);
					close_session(pinfo);
					return -1;
				}
				else if(errno == EAGAIN || errno == EWOULDBLOCK)
				{
					break;
				}
				else
				{
					snprintf(m_errmsg, sizeof(m_errmsg), "fd=%d session=%llu write %d %s", fd, sessionID, errno, strerror(errno));
					break;				
				}
			}
			else
			{
				buff += ret;
				len -= ret;
			}
		}
	}

	//没写完加入写buff中
	if(len > 0)
	{
		unsigned int usedLen = 0;
		if(pinfo->writeBuff.inited())
			usedLen = pinfo->writeBuff.len();

		unsigned int atLeastLen = len+usedLen;
		if(atLeastLen > m_packSizeLimit)
		{
			//超出长度限制了
			snprintf(m_errmsg, sizeof(m_errmsg), "fd=%d session=%llu buffered(%u) and new(%u) > limit(%u)", 
				fd, sessionID, usedLen, len, m_packSizeLimit);
			return -1;				
		}

		//建议长度
		unsigned int suggestLen = atLeastLen + m_packSize;
		if(suggestLen > m_packSizeLimit)
			suggestLen = m_packSizeLimit;
				
		
		//初始化
		if(!(pinfo->writeBuff.inited()))
		{
			pinfo->writeBuff.init(suggestLen, &m_alloc);
		}

		//检查长度
		if(pinfo->writeBuff.left() < len)
		{
			//扩大长度
			pinfo->writeBuff.resize(suggestLen);
		}

		//需要等可写
		modify_event(fd, EPOLLOUT|EPOLLIN);

		unsigned int wr = pinfo->writeBuff.write(buff, len);
		if(wr != len)
		{
			//impossbile
			LOG(LOG_ERROR, "%s", "pinfo->writeBuff.write fail");
			return -1;
		}
		
		//LOG(LOG_DEBUG, "derect write(%d, %llu) to buff(%d)", fd, sessionID, len);
	}
	else
	{
		//LOG(LOG_DEBUG, "derect write(%d, %llu) ok", fd, sessionID);
	}

	return 0;
}

void CEpollWrap::close_session(FDINFO* pinfo, bool cancelTimer)
{
	//关闭链接
	del_event(pinfo->fd);
	shutdown(pinfo->fd, SHUT_RDWR);
	close(pinfo->fd);

	//通知关闭
	m_pControl->on_close(pinfo->fd, pinfo->sessionID.id);

	//删除timer
	if(m_idleTimeoutS != 0 && cancelTimer)
	{
		cancel_timer(pinfo->timerID);
	}

	//要特别注意，pinfo的生命期哦，map.erase之后就消失了!!!
	m_mapFD.erase(pinfo->fd);
}

void CEpollWrap::timeout()
{
	int fd = 0;
	if(!m_ptimer)
	{
		return;
	}
	
	vector<unsigned int> vtimerID;
	vector<int> vtimerData;
	vtimerID.reserve(100);
	vtimerData.reserve(100);
	int ret = m_ptimer->check_timer(vtimerID, vtimerData, m_ptimenow);
	if(ret != 0)
	{
		m_ptimer->passerr(m_errmsg, sizeof(m_errmsg));
		LOG(LOG_ERROR, "check_timer %s", m_errmsg);
		return;
	}

	//使用timmer
	for(unsigned int i=0; i<vtimerID.size(); ++i)
	{
		fd = vtimerData[i]; //超时的
//LOG(LOG_INFO, "fd=%d timeout", fd);
		m_mapIt = m_mapFD.find(fd);
		if(m_mapIt != m_mapFD.end())
		{
			FDINFO* pinfo = &(m_mapIt->second); //for short
			//是否超过了
			if(TIMEVAL_SECOND_INTERVAL_PASSED(*m_ptimenow, pinfo->state.lastActiveTime, (int)m_idleTimeoutS))
			{
				LOG(LOG_ERROR, "session(%d, %llu)|limit|idle|%u seconds",  
					pinfo->fd, pinfo->sessionID.id, m_idleTimeoutS);
				close_session(pinfo, false);
			}
			else
			{
				//1s内的误差
				int time = pinfo->state.lastActiveTime.tv_sec + (int)m_idleTimeoutS - (*m_ptimenow).tv_sec;
				if(time <= 0)
				{
					LOG(LOG_ERROR, "session(%d, %llu)|limit|idle|%u seconds",  
						pinfo->fd, pinfo->sessionID.id, m_idleTimeoutS);
					close_session(pinfo, false);
				}
				else
				{
					//继续扫
					pinfo->timerID = set_timer(fd, time);
				}
			}
		}
	}
}

