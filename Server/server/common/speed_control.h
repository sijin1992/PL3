#ifndef __SPEED_CONTROL_H__
#define __SPEED_CONTROL_H__

#include <unistd.h>
#include <sys/time.h>

class CSpeedControl
{
	public:
		CSpeedControl();
	
		void set(unsigned int timeIntervalMS, unsigned int limitCount);
		
		bool checkLimit();

		inline unsigned int thelimit()
		{
			return m_limitCount;
		}
		
	protected:
		
		timeval m_lastCheck;
		unsigned int m_lastCount;
		unsigned int m_limitCount;
		unsigned int m_timeIntervalMS;
};

#endif

