#define DEBUG
#include "../timer.h" 
#include <iostream>
#include <sstream>
#include "../../time/calculagraph.h"
#include <stdlib.h>

using namespace std;

void xxtimeout(CTimerPool<int>& oTimer)
{
	cout << "timeout------------------------------------------------------" << endl;

	vector<unsigned int> vtimerID;
	vector<int> vtimerData;
	int ret = oTimer.check_timer(vtimerID, vtimerData);
	if(ret != 0)
	{
		cout << "check_timer=" << ret << endl;
	}
	else
	{
		for(unsigned int i=0; i<vtimerID.size(); ++i)
		{
			cout << "timer[" << i << "]=" << vtimerID[i] << " data=" << vtimerData[i] << endl;
		}
	}

	oTimer.debug(cout);
}

int main(int argc , char** argv)
{
#if 1
	unsigned int  memsize = CTimerPool<int>::mem_size(2);
	char* mem = new char[memsize];
	CTimerPool<int> oTimer(mem, memsize, 2);

	cout << "init------------------------------------------------------" << endl;
	oTimer.debug(cout);

	if(!oTimer.valid())
	{
		cout << "error" << endl;
	}
	else
	{
		if(argc < 2)
		{
			unsigned int  timerIDs[3];
			for(int i=0; i<3; ++i)
			{
				int data = i+1;
				int ret = oTimer.set_timer(timerIDs[i], data, 0, i+1);
				if(ret != 0)
				{
					cout << i << " set_timer = " << ret << endl;
					break;
				}
			}
			cout << "add 3------------------------------------------------------" << endl;
			oTimer.debug(cout);

			sleep(1);
			xxtimeout(oTimer);

			cout << "del ------------------------------------------------------" << endl;
			int ret = oTimer.del_timer(timerIDs[1]);
			if(ret != 0)
			{
				cout << "del_timer = " << ret << endl;
			}
			oTimer.debug(cout);
		
			sleep(1);
			xxtimeout(oTimer);
		}
		else
		{
			int interval = atoi(argv[1]);
			unsigned int timeID;
			int data=1;
			cout << "set timer for " << interval << " second=" << oTimer.set_timer_s(timeID,data, interval, NULL);
			for(int i=0; i<= interval+1; ++i)
			{
				sleep(1);
				cout << "at[" << i << "]" << endl;
				xxtimeout(oTimer);
			}
		}
	}
#else 

	//压力测试
	//涉及到秒了
	unsigned int imax = 1000000;
	unsigned int  memsize = CTimerPool<int>::mem_size(imax);
	char* mem = new char[memsize];
	CTimerPool<int> oTimer(mem, memsize, imax);
	int data;
	unsigned int timerID;
	int ret;
	
	CCalculagraph occ(cout);
	for(int i=0; i<imax; ++i)
	{
		data = i+1;
		ret = oTimer.set_timer(timerID, data, 0, i+1);
		if(ret != 0)
		{
			cout << i << " set_timer = " << ret << endl;
			break;
		}
	}
	occ.stop();

	vector<unsigned int> vtimerID;
	vector<int> vtimerData;
	vtimerID.reserve(imax/100);
	vtimerData.reserve(imax/100);

	cout << "check" << endl;
	
	occ.restart();
	ret = oTimer.check_timer(vtimerID, vtimerData);
	if(ret != 0)
	{
		cout << "check_timer=" << ret << endl;
	}
	else
	{
		cout << "timeout nodenum=" << vtimerID.size() << endl; 
	}
	occ.stop();

	usleep(50000);
	cout << endl << "after usleep(50000) check" << endl;

	occ.restart();
	ret = oTimer.check_timer(vtimerID, vtimerData);
	if(ret != 0)
	{
		cout << "check_timer=" << ret << endl;
	}
	else
	{
		cout << "timeout nodenum=" << vtimerID.size() << endl; 
	}
	occ.stop();

	usleep(500000);
	cout <<  endl << "after usleep(500000) check" << endl;

	occ.restart();
	ret = oTimer.check_timer(vtimerID, vtimerData);
	if(ret != 0)
	{
		cout << "check_timer=" << ret << endl;
	}
	else
	{
		cout << "timeout nodenum=" << vtimerID.size() << endl; 
	}
	occ.stop();

	sleep(3);
	cout <<  endl << "after sleep(3) check" << endl;

	occ.restart();
	ret = oTimer.check_timer(vtimerID, vtimerData);
	if(ret != 0)
	{
		cout << "check_timer=" << ret << endl;
	}
	else
	{
		cout << "timeout nodenum=" << vtimerID.size() << endl; 
	}
	occ.stop();

	sleep(7);
	cout <<  endl << "after sleep(7) check" << endl;

	occ.restart();
	ret = oTimer.check_timer(vtimerID, vtimerData);
	if(ret != 0)
	{
		cout << "check_timer=" << ret << endl;
	}
	else
	{
		cout << "timeout nodenum=" << vtimerID.size() << endl; 
	}
	occ.stop();

	//oTimer.debug(cout);
	for(int i=0; i<imax/10*1000;++i)
	{
		sleep(10);
		cout << "every 10s" << endl;
		occ.restart();
		ret = oTimer.check_timer(vtimerID, vtimerData);
		if(ret != 0)
		{
			cout << "check_timer=" << ret << endl;
		}
		else
		{
			cout << "timeout nodenum=" << vtimerID.size() << endl; 
		}
		occ.stop();
		cout << endl;
	}
	
#endif

	delete[] mem;
	return 0;
}

