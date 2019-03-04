#ifndef __EPOLL_TCP_SERVER_H__
#define __EPOLL_TCP_SERVER_H__

#include <sys/time.h>
#include <vector>
#include <map>
#include <sys/epoll.h>
#include "mem_alloc/mem_alloc.h"
#include "mem_alloc/mem_buff.h"
#include "struct/timer.h"
#include <iostream>
#include "time/time_util.h"
#include "log/log.h"
#include <stdio.h>

//如果有的话不行用map
#include <ext/hash_map>
using namespace __gnu_cxx;

using namespace std;

//协议解析的接口, 不想搞模板了，继承吧。
class CPacketInterface
{
public:
	static const int RET_OK = 0; //没有异常发生
	static const int RET_PACKET_NOT_VALID = -1; //协议包非法
	static const int RET_PACKET_NEED_MORE_BYTES = -2; //协议包需要更多的字节

	/**
	* 让server判断如何分包，on_read中调用
	* return:
	* RET_OK,  pack_len返回整个包长
	* RET_PACKET_NOT_VALID  无法解析包，整个buff将被舍弃
	* RET_PACKET_NEED_MORE_BYTES server将继续读，一般没有收完包头时返回这个
	* server处理逻辑: RET_PACKET_NEED_MORE_BYTES or buff_len < pack_len, 继续read
	*					 buff_len >= pack_len server转发包，然后剩下的buff内容当作下一个包
	*/
	virtual int get_packet_len(const char* buff, unsigned int buffLen, unsigned int& packetLen) = 0;
	virtual ~CPacketInterface() {}

};

class CControlInterface;

class CEpollWrap
{
	public:

		friend class CControlInterface;
		typedef union tagUnSessionID
		{
			unsigned long long id;
			struct
			{
				unsigned int ip;
				unsigned short port;
				unsigned short seq;
			}tcpaddr; 
		}UN_SESSION_ID;

		static const int TYPE_LISTEN = 1;
		static const int TYPE_ACCEPT = 2;

		//可配置，
		//包不要超过这个大小为好,fd的writeBuff和readBuff根据这个做基础大小。
		//最大不能超过SIZE_BUFF_LIMIT
		//对应变量
		//unsigned int m_packSize; 
		//unsigned int m_packSizeLimit; 
		static const unsigned int SIZE_PACKET_DEFAULT = 8096;
		static const unsigned int SIZE_BUFF_LIMIT = 8096*64;


		struct LIMIT_STATE
		{
			unsigned int pollinCount; //总的pollin事件发生次数
			unsigned int lastPollinCount; //最近一次扫描的事件发生次数
			unsigned long long recvBytes; //总的接受字节数
			unsigned long long lastRecvBytes; //最近一次扫描的接收的字节数
			timeval createTime; //创建时间
			timeval lastActiveTime; //上次活跃时间
			timeval lastCheckTime; //上次检查时间
			LIMIT_STATE()
			{
				pollinCount = 0;
				lastPollinCount = 0;
				recvBytes = 0;
				lastRecvBytes = 0;
				memset(&createTime, 0, sizeof(createTime));
				memset(&lastActiveTime, 0, sizeof(lastActiveTime));
				memset(&lastCheckTime, 0, sizeof(lastCheckTime));
			}
			
			void debug(ostream& out)
			{
				out << "LIMIT_STATE{" << endl;
				out << "pollinCount|" << pollinCount << endl;
				out << "lastPollinCount|" << lastPollinCount << endl;
				out << "recvBytes|" << recvBytes << endl;
				out << "lastRecvBytes|" << lastRecvBytes << endl;
				out << "createTime|" << createTime.tv_sec << "s," << createTime.tv_usec << "us" << endl;
				out << "lastActiveTime|" << lastActiveTime.tv_sec << "s," << lastActiveTime.tv_usec << "us" << endl;
				out << "lastCheckTime|" << lastCheckTime.tv_sec << "s," << lastCheckTime.tv_usec << "us" << endl;
				out << "}end LIMIT_STATE" << endl;
			}
		};


		struct FDINFO
		{
			int fd;
			int type; //见上面的定义
			UN_SESSION_ID sessionID; //对话id
			LIMIT_STATE state; //一些状态信息
			unsigned int timerID; //绑定的timerID
			CMemBuff writeBuff;
			CMemBuff readBuff;

			void debug(ostream& os)
			{
				os << "FDINFO{" << endl;
				os << "fd|" << fd << endl;
				os << "type|" << type << endl;
				os << "sessionID|" << sessionID.id << "|" << sessionID.tcpaddr.ip << " " << sessionID.tcpaddr.port << " " << sessionID.tcpaddr.seq << endl;
				state.debug(os);
				os << "timerID|" << timerID << endl;
				os << "write|";
				writeBuff.debug(cout);
				os << endl << "read|";
				readBuff.debug(cout);
				os << endl << "} end FDINFO" << endl;
			}
		};
		
//typedef map<int,FDINFO> FDINFO_MAP_TYPE;
typedef hash_map<int,FDINFO> FDINFO_MAP_TYPE;
		
	public:
		CEpollWrap(CPacketInterface* ppack, CControlInterface* pcontrol, timeval* ptimeSource);

		~CEpollWrap();	

		
		//modify pack limit
		inline void set_pack_buff_size(unsigned int limitSize, unsigned int startSize=SIZE_PACKET_DEFAULT)
		{
			m_packSizeLimit = limitSize;
			if(startSize >= limitSize)
				m_packSize = limitSize;
			else
				m_packSize = startSize;
		}
		
		//创建epoll,使用ET还是LT，默认LT
		//Timer跟idleTimeout限制有关, 默认开启,关闭之后减少一些内存消耗，但idleTimeout无法生效
		int create(unsigned int size,  bool useET = false, bool enableTimer = false);


		//为客户端链接设置限制
		//checkIntervalS检查的时间段长度(秒)
		//limitPollinCount可读事件次数限制
		//limitRecvBytes读取字节数目限制
		//idleTimeoutS空闲超时
		//任意参数为0=不限制
		//达到任意条件则关闭链接
		inline void set_session_limit(unsigned int checkIntervalS, unsigned int limitPollinCount, unsigned int limitRecvBytes, unsigned int idleTimeoutS)
		{
			m_checkIntervalS = checkIntervalS;
			m_limitPollinCount = limitPollinCount;
			m_limitRecvBytes = limitRecvBytes;
			m_idleTimeoutS = idleTimeoutS;
		}
		
		//为server添加listen端口
		int add_listen(string ip, unsigned int port);
		
		//开始poll
		int do_poll(unsigned int time_sec, unsigned int time_microsec);

		//写入包
		//先尝试直接写fd，如果会阻塞就放入buffer中
		//return 0 ok, -1 fail
		int write_packet(int fd, unsigned long long sessionID, const char* packet, unsigned int packetLen);

		//关闭链接
		int close_fd(int fd, unsigned long long sessionID);

		inline FDINFO_MAP_TYPE& getmap()
		{
			return m_mapFD;
		}

		inline const char* errmsg()
		{
			return m_errmsg;
		}

		void debug(ostream& os)
		{
			FDINFO_MAP_TYPE::iterator it;
			os << "CEpollWrap{" << endl;
			os << "m_epollFD|" << m_epollFD << endl;
			os << "m_seq|" << m_seq << endl;
			os << "m_useET|" << m_useET << endl;
			os << "m_event_max|" << m_event_max << endl;
			os << "m_packSize|" << m_packSize << endl;
			os << "m_mapFD|" << endl;
			for(it=m_mapFD.begin(); it!=m_mapFD.end(); ++it)
			{
				os << it->first << endl;
				it->second.debug(os);
				os << "---------------" << endl;
			}
			os << "} end CEpollWrap" << endl;
		}
		
	protected:
		//向epoll加入fd
		int add_event(int fd, unsigned int flag);
		//从epoll中删除fd
		int del_event(int fd);
		int modify_event(int fd, unsigned int flag);

	private:
		//顾名思义吧。。。
		void on_listen(FDINFO* pinfo);

		void on_write(FDINFO* pinfo);
		void on_read(FDINFO* pinfo);

		//被动关闭
		void close_session(FDINFO* pinfo, bool cancelTimer=true);


		//set_timer
		inline  unsigned int set_timer(int fd, unsigned int timeS)
		{
			if(!m_ptimer)
				return 0;
			unsigned int timeID = 0;
//LOG(LOG_INFO, "set_timer_s %u, %d, %u, %ld", timeID,  fd, timeS, m_ptimenow->tv_sec);
			if(m_ptimer->set_timer_s(timeID, fd, timeS, m_ptimenow) !=0)
			{
				m_ptimer->passerr(m_errmsg, sizeof(m_errmsg));
				LOG(LOG_ERROR, "set timer fail %s", m_errmsg);
			}
			return timeID;
		}

		//cancel_timer
		inline void cancel_timer(unsigned int timeID)
		{
			if(!m_ptimer)
				return;
//LOG(LOG_INFO, "cancel_timer %u", timeID);
			m_ptimer->del_timer(timeID);
		}

		//timeout
		void timeout();
		
	protected:
		int m_epollFD; //epoll的fd
		FDINFO_MAP_TYPE m_mapFD; //管理链接的map
		FDINFO_MAP_TYPE::iterator m_mapIt; //迭代器
		
		char m_errmsg[512]; //错误信息
		unsigned short m_seq; //序列号生成
		bool m_useET; //是否使用epoll et
		epoll_event * m_events;//epoll用的events
		unsigned int m_event_max;//epoll支持的最大链接数
		unsigned int m_event_current; //当前的event数
		CMemAlloc m_alloc; //读写缓存的内存分配器
		CPacketInterface* m_pPack;
		CControlInterface* m_pControl;
		unsigned int m_packSize; //包缓存创建大小
		unsigned int m_packSizeLimit; //包最大大小
		timeval* m_ptimenow;
		unsigned int m_checkIntervalS;
		unsigned int m_limitPollinCount;
		unsigned int m_limitRecvBytes;
		unsigned int m_idleTimeoutS;
		CTimerPool<int>* m_ptimer;
		char* m_ptimerMem;
};

class CControlInterface
{
public:
	//以下接口是accept到的链接的数据回调接口
	/*
	* 当server收到一个完整的包之后传递给interface
	* return 0 或者-1
	*/
	virtual int pass_packet(int fd, unsigned long long sessionID, const char* packet, unsigned int packet_len) = 0;

	/*
	* 通知control，有fd链接的
	*/
	virtual void on_connect(int fd, unsigned long long sessionID) = 0;

	/*
	* 通知control，有fd关闭了
	*/
	virtual void on_close(int fd, unsigned long long sessionID) = 0;

	/**
	*以下是为额外的hook
	*/
	
	/*
	* create结束前调用0=ok，其他返回则create报错。
	* 可以加入其它的fd
	*/
	virtual int hook_create(CEpollWrap* host) {return 0;}

	/*
	* epoll的fd不在host->m_mapFD中或者类型不是预定义的则调用之
	* pinfo不存在则为null
	* flag是epoll事件
	*/
	virtual void hook_poll(CEpollWrap* host, int fd, unsigned int flag, CEpollWrap::FDINFO* pinfo) {}
	
	virtual ~CControlInterface() {}
};


#endif

