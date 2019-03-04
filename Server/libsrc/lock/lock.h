//locktypeÌá¹©lock£¬unlock²Ù×÷
#ifndef __LOCK_NONE_H__
#define __LOCK_NONE_H__
#include <iostream>
using namespace std;

class CLock
{
	public:
		virtual void lock()
		{
			//cout << "-----------lock--------------" << endl;
		}

		virtual void unlock()
		{
			//cout << "-----------unlock--------------" << endl;
		}

	virtual ~CLock() {}
};

#endif

