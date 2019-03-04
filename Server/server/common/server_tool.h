#ifndef __SERVER_TOOL_H__
#define __SERVER_TOOL_H__

#include <unistd.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/time.h>
#include <sys/resource.h>
#include "ini/ini_file.h"
#include "log/log.h"
#include <stdlib.h>

class CServerTool
{
	public:
		static int run_by_ini(CIniFile* poIni, const char* sectorName)
		{
			int ret;
			int isDaemon=1;
			char lockPath[1024] = {0};
			if(poIni && sectorName)
			{
				poIni->GetInt(sectorName, "DAEMON", 1, &isDaemon);
				poIni->GetString(sectorName, "LOCK", "", lockPath, sizeof(lockPath));
			}
			
			if(isDaemon)
			{
				ret = daemon();
				if(ret != 0)
				{
					LOG(LOG_ERROR, "daemon()=%d",  ret);
					return ret;
				}
			}

			if(*lockPath != 0)
			{
				ret = filelock(lockPath);
				if(ret != 0)
				{
					LOG(LOG_ERROR, "filelock(%s)=%d", lockPath, ret);
					return ret;
				}
			}

			return 0;
		}
		
		static int daemon()
		{
			pid_t pid = fork();

			if (pid == -1)
			{
				return -1;
			}
			else if (pid != 0)
			{
				exit(0);
			}

			if(setsid() == -1)
				return -1;
			
			signal(SIGHUP, SIG_IGN);

			pid = fork();
			if (pid != 0)
			{
			    exit(1); 
			}

			umask(0);

			return 0;
		}

		static void ignore(int sigvalue)
		{
			signal(sigvalue, SIG_IGN);
		}

		static void sighandle(int sigvalue, sighandler_t handle)
		{
			struct sigaction stSiga;
			memset(&stSiga, 0, sizeof(stSiga));
			stSiga.sa_handler = handle;
			sigaction(sigvalue, &stSiga, NULL);
		}

		static int filelock(const char* file)
		{
			int iRetVal = 0;

			if ((NULL == file)||(file[0] == '\0'))
			{
				return -1;
			}


			int iPidFD;
			if ((iPidFD = open(file, O_RDWR | O_CREAT, 0644)) == -1)
			{
				return -2;
			}

			struct flock stLock;
			stLock.l_type = F_WRLCK;
			stLock.l_whence = SEEK_SET;
			stLock.l_start = 0;
			stLock.l_len = 1;

			iRetVal = fcntl(iPidFD, F_SETLK, &stLock);
			if (iRetVal == -1)
			{
				return -3;
			}

			char szLine[16] = {0};
			snprintf(szLine, sizeof(szLine), "%d\n", getpid());
			ftruncate(iPidFD, 0);
			write(iPidFD, szLine, strlen(szLine));

			return 0;
		}

		static int ensure_max_fds(int maxFds)
		{
			struct rlimit fdmaxrl;
			int ret = getrlimit(RLIMIT_NOFILE, &fdmaxrl);
			if(ret != 0)
				return -1;

			if((unsigned int)maxFds < fdmaxrl.rlim_cur)
			{
				return 0;
			}

			fdmaxrl.rlim_cur = maxFds+1;
			fdmaxrl.rlim_max = maxFds+1;

			ret = setrlimit(RLIMIT_NOFILE, &fdmaxrl);
			if(ret != 0)
				return -1;
			
			return 0;
		}

		static void server_param_safe(int& value, int min, int max, int defval)
		{
			if(value > max || value < min)
			{
				cout << "int value not valid, set to " << defval << endl;
				value = defval;
			}
		}

		static void server_param_safe(unsigned int& value, unsigned int min, unsigned int max, unsigned int defval)
		{
			if(value > max || value < min)
			{
				cout << "unsigned int value not valid, set to " << defval << endl;
				value = defval;
			}
		}

};

#endif

