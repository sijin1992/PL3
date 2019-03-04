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

//����еĻ�������map
#include <ext/hash_map>
using namespace __gnu_cxx;

using namespace std;

//Э������Ľӿ�, �����ģ���ˣ��̳аɡ�
class CPacketInterface
{
public:
	static const int RET_OK = 0; //û���쳣����
	static const int RET_PACKET_NOT_VALID = -1; //Э����Ƿ�
	static const int RET_PACKET_NEED_MORE_BYTES = -2; //Э�����Ҫ������ֽ�

	/**
	* ��server�ж���ηְ���on_read�е���
	* return:
	* RET_OK,  pack_len������������
	* RET_PACKET_NOT_VALID  �޷�������������buff��������
	* RET_PACKET_NEED_MORE_BYTES server����������һ��û�������ͷʱ�������
	* server�����߼�: RET_PACKET_NEED_MORE_BYTES or buff_len < pack_len, ����read
	*					 buff_len >= pack_len serverת������Ȼ��ʣ�µ�buff���ݵ�����һ����
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

		//�����ã�
		//����Ҫ���������СΪ��,fd��writeBuff��readBuff���������������С��
		//����ܳ���SIZE_BUFF_LIMIT
		//��Ӧ����
		//unsigned int m_packSize; 
		//unsigned int m_packSizeLimit; 
		static const unsigned int SIZE_PACKET_DEFAULT = 8096;
		static const unsigned int SIZE_BUFF_LIMIT = 8096*64;


		struct LIMIT_STATE
		{
			unsigned int pollinCount; //�ܵ�pollin�¼���������
			unsigned int lastPollinCount; //���һ��ɨ����¼���������
			unsigned long long recvBytes; //�ܵĽ����ֽ���
			unsigned long long lastRecvBytes; //���һ��ɨ��Ľ��յ��ֽ���
			timeval createTime; //����ʱ��
			timeval lastActiveTime; //�ϴλ�Ծʱ��
			timeval lastCheckTime; //�ϴμ��ʱ��
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
			int type; //������Ķ���
			UN_SESSION_ID sessionID; //�Ի�id
			LIMIT_STATE state; //һЩ״̬��Ϣ
			unsigned int timerID; //�󶨵�timerID
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
		
		//����epoll,ʹ��ET����LT��Ĭ��LT
		//Timer��idleTimeout�����й�, Ĭ�Ͽ���,�ر�֮�����һЩ�ڴ����ģ���idleTimeout�޷���Ч
		int create(unsigned int size,  bool useET = false, bool enableTimer = false);


		//Ϊ�ͻ���������������
		//checkIntervalS����ʱ��γ���(��)
		//limitPollinCount�ɶ��¼���������
		//limitRecvBytes��ȡ�ֽ���Ŀ����
		//idleTimeoutS���г�ʱ
		//�������Ϊ0=������
		//�ﵽ����������ر�����
		inline void set_session_limit(unsigned int checkIntervalS, unsigned int limitPollinCount, unsigned int limitRecvBytes, unsigned int idleTimeoutS)
		{
			m_checkIntervalS = checkIntervalS;
			m_limitPollinCount = limitPollinCount;
			m_limitRecvBytes = limitRecvBytes;
			m_idleTimeoutS = idleTimeoutS;
		}
		
		//Ϊserver���listen�˿�
		int add_listen(string ip, unsigned int port);
		
		//��ʼpoll
		int do_poll(unsigned int time_sec, unsigned int time_microsec);

		//д���
		//�ȳ���ֱ��дfd������������ͷ���buffer��
		//return 0 ok, -1 fail
		int write_packet(int fd, unsigned long long sessionID, const char* packet, unsigned int packetLen);

		//�ر�����
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
		//��epoll����fd
		int add_event(int fd, unsigned int flag);
		//��epoll��ɾ��fd
		int del_event(int fd);
		int modify_event(int fd, unsigned int flag);

	private:
		//����˼��ɡ�����
		void on_listen(FDINFO* pinfo);

		void on_write(FDINFO* pinfo);
		void on_read(FDINFO* pinfo);

		//�����ر�
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
		int m_epollFD; //epoll��fd
		FDINFO_MAP_TYPE m_mapFD; //�������ӵ�map
		FDINFO_MAP_TYPE::iterator m_mapIt; //������
		
		char m_errmsg[512]; //������Ϣ
		unsigned short m_seq; //���к�����
		bool m_useET; //�Ƿ�ʹ��epoll et
		epoll_event * m_events;//epoll�õ�events
		unsigned int m_event_max;//epoll֧�ֵ����������
		unsigned int m_event_current; //��ǰ��event��
		CMemAlloc m_alloc; //��д������ڴ������
		CPacketInterface* m_pPack;
		CControlInterface* m_pControl;
		unsigned int m_packSize; //�����洴����С
		unsigned int m_packSizeLimit; //������С
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
	//���½ӿ���accept�������ӵ����ݻص��ӿ�
	/*
	* ��server�յ�һ�������İ�֮�󴫵ݸ�interface
	* return 0 ����-1
	*/
	virtual int pass_packet(int fd, unsigned long long sessionID, const char* packet, unsigned int packet_len) = 0;

	/*
	* ֪ͨcontrol����fd���ӵ�
	*/
	virtual void on_connect(int fd, unsigned long long sessionID) = 0;

	/*
	* ֪ͨcontrol����fd�ر���
	*/
	virtual void on_close(int fd, unsigned long long sessionID) = 0;

	/**
	*������Ϊ�����hook
	*/
	
	/*
	* create����ǰ����0=ok������������create����
	* ���Լ���������fd
	*/
	virtual int hook_create(CEpollWrap* host) {return 0;}

	/*
	* epoll��fd����host->m_mapFD�л������Ͳ���Ԥ����������֮
	* pinfo��������Ϊnull
	* flag��epoll�¼�
	*/
	virtual void hook_poll(CEpollWrap* host, int fd, unsigned int flag, CEpollWrap::FDINFO* pinfo) {}
	
	virtual ~CControlInterface() {}
};


#endif

