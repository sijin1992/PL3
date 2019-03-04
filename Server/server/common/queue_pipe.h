#ifndef __DEQUE_PIPE_H__
#define __DEQUE_PIPE_H__

#include "lock/lock_sem.h"
#include "struct/mem_dequeue.h"
#include "shm/shm_wrap.h"
#include "ini/ini_file.h"
#include "log/log.h"
#include <map>
#include "common/server_tool.h"
#include <iostream>
using namespace std;

#define QUEUE_LOG_INFO_CNT 10000

struct PIPE_CONFIG_ITEM
{
	key_t shmkey_r;
	unsigned int dequesize_r;
	key_t shmkey_w;
	unsigned int dequesize_w;
	int activeLock;
	int passiveLock;

	void debug(ostream& os);
};

class CPIPEConfigInfo
{
	public:

		typedef map<int, PIPE_CONFIG_ITEM> MAP_PIPE_CONFIG;
		
	public:
		int set_config(CIniFile& oIni);

		int set_config(const char* iniFilePath);

		//isActive=ture read,write方向与配置一致，否则相反
		//semKey借用shmKey，activeLock和passiveLock控制是否要加锁，active用shmkey_r，passive用shmkey_w
		int get_config(int globeID, bool isActive, key_t &shmkey_r, unsigned int &dequesize_r, key_t &shmkey_w, unsigned int &dequesize_w, key_t& semKey);

		void debug(ostream& os);
		
		inline void get_begin(MAP_PIPE_CONFIG::iterator& it)
		{
			it = m_mapConfig.begin();
		}

		inline void get_end(MAP_PIPE_CONFIG::iterator& it)
		{
			it = m_mapConfig.end();
		}

	protected:
		MAP_PIPE_CONFIG m_mapConfig;
		
};

class CDequePIPE
{
	public:
		CDequePIPE();

		int init(CPIPEConfigInfo& config, unsigned int id, bool isActive);

		int init(key_t shmkey_r, unsigned int dequesize_r, key_t shmkey_w, unsigned int dequesize_w, key_t* psemLockKey = NULL);

		//return 0=ok <0 error 1=full
		inline int write(const char* buff, unsigned int len)
		{
			int ret = m_deque_w.push(buff, len);
			if(ret < 0)
			{
				if(ret != CDeque::ERR_DEQUE_FULL)
				{
					snprintf(m_errmsg, sizeof(m_errmsg), "m_deque_w.push=%d", ret);
					return -1;
				}
				else
				{
					return 1;
				}
			}

			if( (++m_sendcnt)%QUEUE_LOG_INFO_CNT == 0)
			{
				LOG(LOG_INFO, "SENDCNT=%lu", m_sendcnt);
			}

			return 0;
		}

		//len是输入输出参数,buff是足够大的内存
		//return 0=ok  -1=CDeque::error,  1=empty 2=too large
		inline int read(char* buff, unsigned int &len)
		{
			unsigned int poplen = 0;
			int ret = m_deque_r.pop(buff, len, &poplen);
			if(ret < 0)
			{
				if(ret== CDeque::ERR_DEQUE_EMPTY)
				{
					return 1;
				}
				else if(ret == CDeque::ERR_LARGE_DATA)
				{
					return 2;
				}
				else
				{
					snprintf(m_errmsg, sizeof(m_errmsg), "m_deque_r.pop=%d", ret);
					m_deque_r.clear();
					return -1;
				}
			}

			len = poplen;

			if( (++m_recvcnt)%QUEUE_LOG_INFO_CNT == 0)
			{
				LOG(LOG_INFO, "RECVCNT=%lu", m_recvcnt);
			}

			return 0;
		}

		//返回new出来的内存和长度
		//0=ok -1=CDeque::error,  1=empty 
		inline int read_new(char*& buff, unsigned int &len)
		{
			int ret = m_deque_r.pop(buff, &len);
			if(ret < 0)
			{
				if(ret != CDeque::ERR_DEQUE_EMPTY)
				{
					snprintf(m_errmsg, sizeof(m_errmsg), "m_deque_r.pop=%d", ret);
					m_deque_r.clear();
					return -1;
				}
				else
				{
					return 1;
				}
			}

			return 0;
		}

		inline const char* errmsg()
		{
			return m_errmsg;
		}
		
	protected:
		int init_one_side(CShmWrapper& shm, CDeque& deque, key_t shmkey, unsigned int dequesize);

	public:
		CDeque m_deque_r;
		CDeque m_deque_w;

	protected:
		CShmWrapper m_shm_r;
		CShmWrapper m_shm_w;
		char m_errmsg[256];
		CLockSem m_lock;
		unsigned long m_recvcnt;
		unsigned long m_sendcnt;
};




#endif

