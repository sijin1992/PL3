#ifndef __CALCULAGRAPH_H__
#define __CALCULAGRAPH_H__

#include <sys/time.h>
#include <iostream>

class CCalculagraph
{
public:
	CCalculagraph(std::ostream& out): os(out)
	{
		restart();
	}
	
	~CCalculagraph()
	{
		stop();
	}
	
	void restart()
	{
		gettimeofday(&start_t, NULL);
		started = true;
	}
	
	void stop()
	{
		if(started)
		{
			gettimeofday(&end_t, NULL);
			if(end_t.tv_usec >= start_t.tv_usec)
			{
				os << "[used: " << (end_t.tv_sec - start_t.tv_sec) << "s, " << end_t.tv_usec - start_t.tv_usec << "us]";
			}
			else
			{
				os << "[used: " << (end_t.tv_sec - start_t.tv_sec-1) << "s, " << 1000000+end_t.tv_usec - start_t.tv_usec << "us]";
			}
			started = false;
		}
	}
	
protected:
	bool started;
	timeval start_t;
	timeval end_t;
	std::ostream& os;
};

#endif
