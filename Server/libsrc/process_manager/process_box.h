#ifndef __PROCESS_BOX_H__
#define __PROCESS_BOX_H__

#include <vector>
#include <sys/types.h> 
#include <sys/wait.h> 
#include <unistd.h>
#include <errno>
#include <log/log.h>

using namespace std;

class CProcessBoxTask
{
	public:
		virtual ~CProcessBoxTask()
		{
		}
		
		virtual int run()
		{
			return 0;
		}
};

class CProcessBox
{
	public:
		CProcessBox()
		{
			m_forkTimes = 0;
			m_stdoutput = true;
			m_log = true;
		}

		void close_log()
		{
			m_log = false;
		}

		void close_output()
		{
			m_stdoutput = false;
		}
		
		int run_task(CProcessBoxTask& task)
		{
			pid_t ret = fork();
			if(ret < 0)
			{
				return -1;
			}
			else if(ret == 0)
			{
				//вс╫ЬЁл
				exit(task.run());
			}
			else
			{
				m_forkTimes++;
				return 0;
			}
		}

		void wait_task()
		{
			int iStatus;
			for(int i=0; i<m_forkTimes; ++i)
			{
				pid_t iPid = waitpid( -1, &iStatus, WUNTRACED );
				if(iPid == -1)
				{
					if(errno == EINTR)
					{
						--i;
						continue;
					}
					else
					{
						if(m_stdoutput)
							printf( "waitpid fail %d %s\n", errno, strerror(errno) );
						if(m_log)
							LOG(LOG_INFO, "waitpid fail %d %s",  errno, strerror(errno) );
						break;
					}
				}
				
				if ( WIFEXITED( iStatus ) != 0 )
				{
					if(m_stdoutput)
						printf( "NOTICE: -----PID: %d exited normally!\n", iPid );
					if(m_log)
						LOG(LOG_INFO,"NOTICE: -----PID: %d exited normally!", iPid );
				}
				else if ( WIFSIGNALED( iStatus ) != 0 )
				{
					if(m_stdoutput)
						printf( "NOTICE: -----PID: %d exited bacause of signal ID: [%d] has not been catched!\n", iPid, WTERMSIG( iStatus ) );			
					if(m_log)
						LOG(LOG_INFO,  "NOTICE: -----PID: %d exited bacause of signal ID: [%d] has not been catched!", iPid, WTERMSIG( iStatus ) );
				}
				else if ( WIFSTOPPED( iStatus ) != 0 )
				{
					if(m_stdoutput)
						printf( "NOTICE: -----PID: %d exited because of stoped! ID: [%d]\n", iPid, WSTOPSIG( iStatus ) );
					if(m_log)
						LOG(LOG_INFO, "NOTICE: -----PID: %d exited because of stoped! ID: [%d]", iPid, WSTOPSIG( iStatus ) );
				}
				else
				{
					if(m_stdoutput)
						printf( "NOTICE: -----PID: %d exited abnormally!\n", iPid );
					if(m_log)
						LOG(LOG_INFO, "NOTICE: -----PID: %d exited abnormally!", iPid );
				}			
			}
		}

	protected:
		int m_forkTimes;
		bool m_stdoutput;
		bool m_log;
};

#endif

