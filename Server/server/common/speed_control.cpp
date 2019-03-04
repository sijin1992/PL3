#include "speed_control.h"

CSpeedControl::CSpeedControl()
{
	m_timeIntervalMS = 0;
	m_lastCheck.tv_sec = 0;
	m_lastCheck.tv_usec = 0;
	m_limitCount = 0;
	m_lastCount =0;
}

void CSpeedControl::set(unsigned int timeIntervalMS, unsigned int limitCount)
{
	m_limitCount = limitCount;
	m_timeIntervalMS = timeIntervalMS;
}

bool CSpeedControl::checkLimit()
{
	if(m_timeIntervalMS == 0)
	{
		return false;
	}

	timeval now;
	gettimeofday(&now, NULL);

	//if ³¬¹ýÊ±¼ä
	bool timeout = false;
	if(m_lastCheck.tv_sec == 0)
	{
		timeout = true;
	}
	else 
	{
		unsigned int diffMS;
		if(now.tv_usec >= m_lastCheck.tv_usec)
		{
			diffMS = (now.tv_sec - m_lastCheck.tv_sec)*1000 + (now.tv_usec - m_lastCheck.tv_usec)/1000;
		}
		else
		{
			diffMS = (now.tv_sec - m_lastCheck.tv_sec - 1)*1000 + (1000000+now.tv_usec - m_lastCheck.tv_usec)/1000;
		}

		if(diffMS >= m_timeIntervalMS)
		{
			timeout = true;
		}
	}

	if(timeout)
	{
		m_lastCount = 0;
		m_lastCheck = now;
	}
	else
	{
		if(m_lastCount == m_limitCount)
		{
			return false;
		}
		++m_lastCount;
	}

	return true;
}


