#ifndef __LINKER_IO_H__
#define __LINKER_IO_H__
/*
* fd读写与buffer
*/

#include "logic/msg.h"
#include "logic/toolkit.h"
#include "common/msg_define.h"
#include <errno.h>
#include <string.h>
#include "linker_net.h"
extern int gDebug;

//断断续续的改，逻辑分割的不清楚，阿门

class CLinkerWriter
{

public:
	CLinkerWriter()
	{
		clean();
		m_inconnect = false;
		m_port = 0;
	}

	inline void clean()
	{
		m_fd = -1;
		m_dataStart = 0;
		m_dataEnd = 0;
	}


	//return 0 ok, -1有错误,1=会阻塞，返回一个等待可读的fd
	int test_send(CLogicMsg& msg, CLinkerNet& theNet)
	{
		int ret = 0;
		if(m_fd < 0)
		{
			//尚未链接
			ret = do_connect(theNet);
			if(ret == 0)
			{
				//继续发送
			}
			else 
			{
				//缓存
				add_to_buff(msg.buff(),msg.data_len(), theNet);
				return 1;
			}
		}

		//有未发送完的消息，直接缓存
		if(used_len() > 0)
		{
			add_to_buff(msg.buff(),msg.data_len(), theNet);
			return 1;
		}

		//send
		int writeLen = 0;
		ret = write_once(msg.buff(),msg.data_len(),writeLen);
		if(ret == 0)
		{
			return 0;
		}
		else if(ret == 1)
		{
			add_to_buff(msg.buff()+writeLen, msg.data_len()-writeLen, theNet);
			//send_buffer完全拿空的时候才会modify掉out
			//所以只要这里追加到空buff中才加上EPOLLOUT
			if(theNet.modify_event(m_fd, EPOLLIN|EPOLLOUT)!=0)
			{
				//只能shit了，下次发送触发继续等待
				LOG(LOG_ERROR, "shit modify_event(%d, EPOLLIN|EPOLLOUT) fail", m_fd);
			}
			return 1;
		}
		else if(ret == 2)
		{
			//链接断开，为了保证msg可靠，丢弃原来缓存的所有msg
			theNet.close_fd(m_fd);
			clean();
			add_to_buff(msg.buff(), msg.data_len(), theNet);
			//不管了，下次再发
			ret = do_connect(theNet, true);
			if(ret < 0)
				return -1;
			else
				return 1;			
		}
		else
			return -1;
	}


	//发送buff中的内容=0 ok，1=会被阻塞，-1=错误
	int buff_send(CLinkerNet& theNet)
	{
		int ret = 0;
		//如果还在链接中，那么是链接有返回了
		if(m_inconnect)
		{
			if(on_connect(theNet)!=0)
				return -1;
		}

		int len = used_len();
		int len_to_max = sizeof(m_buffer)-m_dataStart;
		int writeLen = 0;

		if(len == 0)
		{
			if(theNet.modify_event(m_fd, EPOLLIN)!=0)
				return -1;
			return 0;
		}
		
		if(len > len_to_max)
		{
			//分两次copy
			ret = write_once(m_buffer+m_dataStart, len_to_max, writeLen);
			if(ret == 0)
			{
				//发送完了，再发送一次...
				m_dataStart = (m_dataStart+len_to_max)%sizeof(m_buffer); //其实就是0
				len -= len_to_max;
				ret = write_once(m_buffer+m_dataStart, len, writeLen);
			}
		}
		else
		{
			ret = write_once(m_buffer+m_dataStart, len, writeLen);
		}

		if(ret == 0)
		{
			m_dataStart = (m_dataStart+writeLen)%sizeof(m_buffer);
			theNet.modify_event(m_fd, EPOLLIN); //失败的话，等下次再进来
			return 0;
		}
		else if(ret == 1)
		{
			m_dataStart = (m_dataStart+writeLen)%sizeof(m_buffer);
			return 1;
		}
		else if(ret == 2)
		{
			//链接断开，为了保证msg可靠，丢弃原来缓存的所有msg
			theNet.close_fd(m_fd);
			clean();
			//不管了，下次再发
			ret = do_connect(theNet, true);
			if(ret < 0)
				return -1;
			else
				return 1;
		}
		else
			return -1;

	}

	inline int get_fd()
	{
		return m_fd;
	}
	
	inline void set_svr(string ip,unsigned short port)
	{
		m_ip = ip;
		m_port = port;
	}

protected:
	//return 0=已经搞定，=1需要wait
	int do_connect(CLinkerNet& theNet, bool forceWait = false)
	{
		/*
		if(m_inconnect)
		{
			return 1;
		}
		*/
		//允许多次connect，防止对方没有响应时挂住

		if(m_port == 0)
		{
			LOG(LOG_ERROR, "do_connect port = 0");
			return -1;
		}
		
		int ret = theNet.do_connect(m_fd, m_ip, m_port, forceWait);
		if(ret < 0)
		{
			return -1;
		}
		else if(ret == 0)
		{
			return 0; //直接ok了
		}
		
		m_inconnect = true;
		return 1; //要等待
	}

	int on_connect(CLinkerNet& theNet)
	{
		m_inconnect = false;
		int iErr = -1;
		int iErrLen = sizeof(iErr);
		int ret = getsockopt(m_fd, SOL_SOCKET, SO_ERROR, (char *)&iErr, (socklen_t*)&iErrLen);
		if(ret != 0)
		{
			LOG(LOG_ERROR, "getsockopt()=%d fail Err(%d,%s)", ret, errno, strerror(errno));
			theNet.close_fd(m_fd);
			clean();
			return -1;
		}
		else
		{
			if(iErr!= 0)
			{
				LOG(LOG_ERROR, "connect(%d,%s)", iErr, strerror(iErr));
				theNet.close_fd(m_fd);
				clean();
				return -1;
			}
		}

		if(gDebug)
		{
			LOG(LOG_DEBUG, "[%d]connect ok", m_fd);
		}

		return 0;
	}

	//凡是add_to_buff意味着需要等待
	void add_to_buff(const char* buff, int len, CLinkerNet& theNet)
	{
		if(free_len() < len)
		{
			//那只能丢了
			LOG(LOG_ERROR, "buff free=%d, discard msg length=%d", free_len(), len);
			return;
		}

		int len_to_max = sizeof(m_buffer)-m_dataEnd;
		if(len_to_max >= len)
		{
			memcpy(m_buffer+m_dataEnd, buff, len);
		}
		else
		{
			memcpy(m_buffer+m_dataEnd, buff, len_to_max);
			memcpy(m_buffer, buff+len_to_max, len - len_to_max);
		}

		m_dataEnd = (m_dataEnd+len)%sizeof(m_buffer);

	}

	inline int used_len()
	{
		return (m_dataEnd+sizeof(m_buffer)-m_dataStart)%sizeof(m_buffer);
	}

	inline int free_len()
	{
		//有一格位置要作为结束标识
		return sizeof(m_buffer)-1-used_len();
	}

	//return -1=error, 0=ok, 1=wait 2=reconnect
	inline int write_once(char* buff, int len, int& writeLen)
	{
		int maxintr = 3;
		int ret = 0;
		writeLen = 0;
		while(--maxintr)
		{
			ret = write(m_fd, buff, len);
			if(ret < 0)
			{
				if(gDebug)
				{
					LOG(LOG_DEBUG, "[%d] write(%d) errno=%d strerror=%s", m_fd, len, errno, strerror(errno));
				}
				
				if(errno == EINTR)
				{
					continue;
				}
				else if(errno == EAGAIN)
				{
					return 1;
				}
				else if(errno == EPIPE)
				{
					//重新链接去
					return 2;
				}
				else
				{
					LOG(LOG_ERROR, "write(fd=%d) fail",m_fd );
					return -1;
				}
			}
			else
			{
				if(gDebug)
				{
					LOG(LOG_DEBUG, "[%d] write_once write(%d)=%d", m_fd, len, ret);
				}
				
				writeLen = ret;
				if(ret < len)
				{
					return 1;
				}
				else
				{
					//ok，立即返回了
					return 0;
				}
			}
		}

		LOG(LOG_ERROR, "too many intrrupts");		
		return -1;
	}

	

protected:
	//buff是循环的
	char m_buffer[MSG_BUFF_LIMIT*5];
	int m_dataStart;
	int m_dataEnd;
	int m_fd;
	unsigned short m_port;
	string m_ip;
	bool m_inconnect; //防止多次connect
};


class CLinkerReader
{
public:
	CLinkerReader()
	{
		m_bufferDataLen = 0;
		m_msgstart = 0;
	}
	
	//从CMsgQueue读msg并写到fd
	//return < 0 fail，=0 ok，=1会被阻塞 =2对方关闭了
	int test_recv(int fd, CLogicMsg& msg)
	{
		int ret = 0;

		//先看一下buffer中的内容有没有完整的消息
		if(get_from_buffer(msg) == 0)
		{
			return 0;
		}

		//没有就读一次
		int leftLen = sizeof(m_buffer) - m_bufferDataLen;
		int maxintr = 3;
		while(--maxintr)
		{
			if(gDebug)
			{
				LOG(LOG_DEBUG, "before read");
			}
			ret = read(fd, m_buffer+m_bufferDataLen, leftLen);
			
			if(ret < 0)
			{
				if(gDebug)
				{
					LOG(LOG_DEBUG, "[%d]test_recv read errno=%d strerror=%s", fd, errno, strerror(errno));
				}
				if(errno == EINTR)
				{
					continue;
				}
				else if(errno == EAGAIN)
				{
					return 1;
				}
				else
				{
					LOG(LOG_ERROR, "read(fd=%d) fail %d %s", fd, errno, strerror(errno));
					return -1;
				}
			}
			else
			{
				if(gDebug)
				{
					LOG(LOG_DEBUG, "[%d]test_recv read=%d", fd, ret);
				}
				if(ret == 0)
				{
					return 2;
				}
				else
				{
					m_bufferDataLen += ret;
					break;
				}
			}
		}


		if(ret < 0)
		{
			LOG(LOG_ERROR, "too many intrrupts");
			return -1;
		}

		return get_from_buffer(msg);
	}

protected:
	int get_from_buffer(CLogicMsg& msg)
	{
		if(m_bufferDataLen >= m_msgstart)
		{
			CLogicMsg tmp(m_buffer+m_msgstart, m_bufferDataLen-m_msgstart);
			if(tmp.valid())
			{
				//ok的,直接copy，msg大小有相同的限制，不比较了
				memcpy(msg.buff(), tmp.buff(),tmp.data_len());
				m_msgstart += tmp.data_len();
				return 0;
			}
			else
			{
				//小于一个msg，那么就移动一下
				int len = m_bufferDataLen-m_msgstart;
				if(len > 0)
				{
					memcpy(m_buffer, m_buffer+m_msgstart, len);
				}
					
				m_msgstart = 0;
				m_bufferDataLen = len;
			}
		}
		else
		{
			//不可能的
			LOG(LOG_ERROR, "m_bufferDataLen(%d) >= m_msgstart(%d) shit", m_bufferDataLen, m_msgstart);
			m_msgstart = 0;
			m_bufferDataLen = 0;
		}
		return 1;
	}

protected:
	//buff连续
	char m_buffer[MSG_BUFF_LIMIT*5];
	int m_msgstart;
	int m_bufferDataLen;
};

#endif

