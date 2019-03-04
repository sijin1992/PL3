/*
 * @file    process_manager.cpp
 * @brief    从comm/process_manager/搬过来的
 * @author   marszhang@tencent.com
 * @date     2010-11-24
 *
 * @note    	想修改，但是怕映像别人，所以copy代码再改喽
 *
 */

#include <stdio.h>
#include <string.h>
#include <time.h>
#include <errno.h>
#include <sys/wait.h>
#include "process_manager.h"
#include <iostream>
#include <sys/types.h>
#include <signal.h>

using namespace std;
void CProcessManager::for_safe()
{
	time_t now = time(NULL);
cout << "lasttime(" << m_lastTime << ") now(" << now << ")" << endl;

	if(now < m_lastTime+m_limitPeriod)
	{
cout << "in limitPeriod: count(" << m_limitCount << ") limit(" << m_limitTimes << ") inccount(" << m_incCount << ")" << endl;
	
		if(++m_limitCount >= m_limitTimes)
		{
			//需要sleep，完了之后重置lasttime
			sleep(m_sleepBase+m_sleepInc*m_incCount);
			++m_incCount;
			m_limitCount = 0;
			m_lastTime = time(NULL);
		}
		else
		{
		}
	}
	else
	{
cout << "over limitPeriod" << endl;
		m_incCount = 0;
		m_limitCount = 0;
		m_lastTime = now;
	}

}

CProcessManager::CProcessManager( )
{
	m_iChildNum		= 16;
	m_piStopFlag		= NULL;
	m_limitPeriod = 1;
	m_limitTimes = 1;
	m_sleepBase = 5;
	m_sleepInc = 5;
	m_stdoutput = true;
	m_limitCount = 0;
	m_lastTime = time(NULL);
	m_incCount = 0;
	m_childs = NULL;
}


CProcessManager::~CProcessManager()
{
	if(m_childs)
	{
		delete[] m_childs;
	}
}

int CProcessManager::run( int argc, char *argv[] )
{
	//create process entity
	int errcout = 0;
	for (unsigned int i = 0; i < m_iChildNum; )
	{
		int iPid = fork();
		if ( iPid < 0 )
		{
			if(m_stdoutput)
				printf( "ERR: CProcessManager::Run() fork failed! ERRMSG:%s\n", strerror( errno ) );
			if( ++errcout <= 3)
			{
				continue;
			}
			else
			{
				break;
				if(m_stdoutput)
					printf( "ERR: CProcessManager::Run() fork fail more than 3, break\n" );
			}
		}
		else if ( iPid > 0 )
		{
			i++;
			on_child_start(iPid);
			errcout = 0;
		}
		else if ( iPid == 0 )
		{
			int iRet = entity( argc, argv );
			if ( iRet < 0 )
			{
				if(m_stdoutput)
					printf( "ERR: CProcessManager::Entity() return < 0. RetValue = %d\n", iRet );
			}

			_exit( iRet );
		}
	}

	while(m_piStopFlag == NULL || *m_piStopFlag == 0)
	{
		//monitor all child processes
		int iStatus = 0;
		int iPid = waitpid( -1, &iStatus, WUNTRACED );
		if(iPid == -1)
		{
			if(errno == EINTR)
				continue;
			else
			{
				if(m_stdoutput)
					printf( "waitpid fail %d %s\n", errno, strerror(errno) );
				break;
			}
		}
		
		on_child_end(iPid);

		if ( WIFEXITED( iStatus ) != 0 )
		{
			if(m_stdoutput)
				printf( "NOTICE: -----PID: %d exited normally!\n", iPid );
			continue;
		}
		else if ( WIFSIGNALED( iStatus ) != 0 )
		{
			if(m_stdoutput)
				printf( "NOTICE: -----PID: %d exited bacause of signal ID: [%d] has not been catched!\n", iPid, WTERMSIG( iStatus ) );			
		}
		else if ( WIFSTOPPED( iStatus ) != 0 )
		{

			if(m_stdoutput)
				printf( "NOTICE: -----PID: %d exited because of stoped! ID: [%d]\n", iPid, WSTOPSIG( iStatus ) );
		}
		else
		{
			if(m_stdoutput)
				printf( "NOTICE: -----PID: %d exited abnormally!\n", iPid );
		}

		//Add Entity
		add_entity( argc, argv );
		
		//增加一个保护机制，如果程序是core掉的，保证不疯狂启动。。。
		for_safe();
	}

	close_childs();

	return SUCCESS;
}

void CProcessManager::close_childs()
{
	if(m_childs)
	{
		for(unsigned int i=0; i<m_iChildNum; ++i)
		{
			if(m_childs[i] != -1)
			{
				kill(m_childs[i], SIGTERM);
			}
		}
	}
}

void CProcessManager::on_child_start(pid_t id)
{
	if(m_childs)
	{
		for(unsigned int i=0; i<m_iChildNum; ++i)
		{
			if(m_childs[i] == -1)
			{
				m_childs[i] = id;
				break;
			}
		}
	}
}

void CProcessManager::on_child_end(pid_t id)
{
	if(m_childs)
	{
		for(unsigned int i=0; i<m_iChildNum; ++i)
		{
			if(m_childs[i] == id)
			{
				m_childs[i] = -1;
				break;
			}
		}
	}
}

int CProcessManager::add_entity( int argc, char *argv[] )
{
	int iPid = fork();
	if ( iPid < 0 )
	{
		if(m_stdoutput)
			printf( "ERR: CProcessManager::Run() fork failed! ERRMSG:%s\n", strerror( errno ) );
		return ERROR;
	}
	else if ( iPid == 0 )
	{
		int iRet = entity( argc, argv );
		if ( iRet < 0 )
		{
			if(m_stdoutput)
				printf( "ERR: CProcessManager::Entity() return < 0. RetValue = %d\n", iRet );
		}

		if(m_stdoutput)
			printf( "NOTICE: ----Add Entity: %d----\n", getpid() );

		_exit( iRet );
	}

	on_child_start(iPid);

	return SUCCESS;
}

