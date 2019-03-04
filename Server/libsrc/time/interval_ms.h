#ifndef __INTERVAL_MS_H__
#define __INTERVAL_MS_H__

#include <sys/time.h>
#include <string.h>

class CIntervalMs
{
public:
	CIntervalMs()
	{
		memset(&m_theTime, 0x0, sizeof(m_theTime));
	}

	static void update(timeval* pTime, timeval* pnow=NULL)
	{
		timeval now;
		if(pnow)
			now = *pnow;
		else
			gettimeofday(&now, NULL);
		*pTime = now;
	}
	
	static bool check_timeout(timeval* pTime, int intervalMs, bool updateWhenTimeout, timeval* pnow=NULL)
	{
		timeval now;
		if(pnow)
			now = *pnow;
		else
			gettimeofday(&now, NULL);
		time_t s = pTime->tv_sec + intervalMs/1000;
		suseconds_t us = (intervalMs%1000)*1000 + pTime->tv_usec;
		if(us >= 1000000)
		{
			s += 1;
			us -= 1000000;
		}
		
		if(now.tv_sec > s)
		{
			if(updateWhenTimeout)
			{
				*pTime = now;
			}
			return true;
		}
		else if(now.tv_sec == s && now.tv_usec > us)
		{
			if(updateWhenTimeout)
			{
				*pTime = now;
			}
			return true;
		}
		
		return false;
	}
	
	inline bool check_timeout(int intervalMs, bool updateWhenTimeout, timeval* pnow=NULL)
	{
		return check_timeout(&m_theTime, intervalMs, updateWhenTimeout, pnow);
	}

	inline void update_self(timeval* pnow=NULL)
	{
		return update(&m_theTime, pnow);
	}
	
protected:
	timeval m_theTime;
};

#endif
