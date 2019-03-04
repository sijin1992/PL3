#ifndef __SHM_TIMER_H__
#define __SHM_TIMER_H__

#include "msg_define.h"
#include "struct/timer.h"
#include "ini/ini_file.h"
#include "log/log.h"
#include <iostream>
#include "shm/shm_wrap.h"
using namespace std;

template<typename TDATA> class CShmTimer
{
	public:
		CShmTimer()
		{
			m_ptimer = NULL;
			m_inited = false;
		}

		~CShmTimer()
		{
			if(m_ptimer)
			{
				delete m_ptimer;
				m_ptimer = NULL;
			}
		}

		typedef CTimerPool<TDATA> THE_TIMER_POOL;

		int init(key_t theKey, unsigned int num)
		{
			unsigned int memSize = THE_TIMER_POOL::mem_size(num);
			bool format = false;
			int ret = m_shm.get(theKey, memSize);
			if(ret == m_shm.SHM_EXIST)
			{
				if(m_shm.get_shm_size() != memSize)
				{
					LOG(LOG_INFO, "getshm(key=0x%x) size not %u formated", theKey, memSize);
					if(m_shm.remove(theKey)!=m_shm.SUCCESS)
					{
						LOG(LOG_ERROR, "remove(key=0x%x) fail", theKey);
						return -1;
					}

					ret = m_shm.get(theKey, memSize);
					format = true;
				}
			}
			else if(ret == m_shm.SUCCESS)
			{
				format = true;
			}

			if(ret == m_shm.ERROR)
			{
				LOG(LOG_ERROR, "getshm(key=%u) %s", theKey, m_shm.errmsg());
				return -1;
			}

			void* memStart = m_shm.get_mem();

			if(format)
			{
				THE_TIMER_POOL::clear(memStart);
			}
			
			m_ptimer = new THE_TIMER_POOL(memStart, memSize, num);
			if(!m_ptimer)
			{
				LOG(LOG_ERROR, "new THE_TIMER_POOL fail");
				return -1;
			}

			if(!(m_ptimer->valid()))
			{
				LOG(LOG_ERROR, "timer not valid %d %s", m_ptimer->m_err.errcode, m_ptimer->m_err.errstrmsg);
				return -1;
			}
			
			m_inited = true;
			return 0;
		}

		THE_TIMER_POOL* get_timer()
		{
			if(!m_inited)
			{
				LOG(LOG_ERROR, "not inited");
				return NULL;
			}
			return m_ptimer;
		}
		
	protected:
		THE_TIMER_POOL* m_ptimer;
		bool m_inited;
		CShmWrapper m_shm;
};

#endif

