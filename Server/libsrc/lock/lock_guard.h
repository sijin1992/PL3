#ifndef __LOCK_GUARD_H__
#define __LOCK_GUARD_H__

#include "lock.h"
class CLockGuard
{
	public:
		CLockGuard(CLock& theLockObj):m_lockObj(theLockObj)
		{
			m_lockObj.lock();
		}
		
		~CLockGuard()
		{
			m_lockObj.unlock();
		}
	protected:
		CLock& m_lockObj;
};

#endif
