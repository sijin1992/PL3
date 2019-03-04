#include "common/queue_pipe.h"
#include "ini/ini_file.h"
#include <iostream>
#include <string>
using namespace std;

/*
* 查看pipe状态的工具
*/

int help(const char* self)
{
	cout << self << " [somedir/queue_pipe.ini queueID]" << endl;
	return 0;
}

int main(int argc, char** argv)
{
	if(argc < 2)
	{
		return help(argv[0]);
	}

	CPIPEConfigInfo pipeconfig;
	if(pipeconfig.set_config(argv[1])!= 0)
	{
		cout << "parse ini fail " << endl;
		return 0;
	}


	int queueID = -1;
	if(argc > 2)
	{
		queueID = atoi(argv[2]);
	}

	if(queueID < 0)
	{
		CPIPEConfigInfo::MAP_PIPE_CONFIG::iterator it;
		CPIPEConfigInfo::MAP_PIPE_CONFIG::iterator itEnd;
		pipeconfig.get_begin(it);
		pipeconfig.get_end(itEnd);
		for(; it!=itEnd; ++it)
		{
			cout << "--------------------------------------------" << endl;
			cout << "ID=" << it->first << endl;
			it->second.debug(cout);
			CDequePIPE thePipe;
			if(thePipe.init(pipeconfig, it->first, true)!=0)
			{
				cout << "init fail" << endl;
			}
			else
			{
				cout << "init active=true" << endl << endl;
				cout << "the read queue:" << endl;
				thePipe.m_deque_r.debug(cout, true);
				cout << endl;
				cout << "the write queue:" << endl;
				thePipe.m_deque_w.debug(cout, true);
				cout << endl;
			}
		}
	}
	else
	{
		CDequePIPE thePipe;
		if(thePipe.init(pipeconfig, queueID, true)!=0)
		{
			cout << "init fail" << endl;
		}
		else
		{
			cout << "init active=true" << endl << endl;
			cout << "the read queue:" << endl;
			thePipe.m_deque_r.debug(cout, true);
			cout << endl;
			cout << "the write queue:" << endl;
			thePipe.m_deque_w.debug(cout, true);
			cout << endl;
		}
	}
		

	return 1;
}

