#ifndef __LOG_H__
#define __LOG_H__
#include <map>
#include <string>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>
#include "../ini/ini_file.h"
#include <iostream>
#include <stdio.h>
#include "writer_proxy.h"
using namespace std;
//add by bool TRACE级别借用debug，纯粹是调试时跟踪用的
#define LOG_TRACE LOG_DEBUG

enum LOG_LEVEL
{
	LOG_INFO = 0,	//可供分析和挖掘的数据
	LOG_ERROR = 1,	//发生的错误
	LOG_DEBUG = 2,	 //用来调试和跟踪的数据
	LOG_EXT_INFO = 3,	// 分析用户行为
	LOG_LEVEL_NUM
};

enum LOG_PROXY_TYPE
{//值不能改哦
	LOG_LOCAL = 0, //直接写文件
	LOG_SERVER = 1, //通过共享内存队列给logserver
	LOG_SERVER_LOCAL =2 //优先给队列，不行的话再local，防止悲剧发生
};

struct LOG_CONFIG
{
	string logPath; //日志根目录，默认LOG_PTAH
	int globeLogLevel; //全局的log level限制，默认是LOG_DEBUG
	int proxyType; //默认是LOG_LOCAL
	int fileLock; //是否需要加文件锁，默认是0
	string defaultModule;
	LOG_CONFIG();
	LOG_CONFIG(CIniFile& oIni, const char* sectorName);
	void read_from_ini(CIniFile& oIni, const char* sectorName);
	void debug(ostream& out);
};

class CLogWriter
{
	public:
		static const char* LOG_PATH;
		static const unsigned int LOG_LINE_SIZE = 100*1024;
		static const int FILE_SIZE_CHECK_COUNT = 1000; //每1000次循环查一次文件大小
		static const unsigned int LOG_FILE_SIZE = 1024*(2*1024*1024 -(LOG_LINE_SIZE/1024+1)*FILE_SIZE_CHECK_COUNT); 

		struct FILE_INFO
		{
			int hour; //精确到小时的时间,用来比较是否需要切换日志
			int fd; //fd
			int seq; //按LOG_FILE_SIZE分文件的序列
			string subdir; //日志子目录(info error debug)
			FILE_INFO()
			{
				fd = -1;
				seq = 0;
				hour = 0;
			}
		};

		struct MODULE_INFO
		{
			int logLevel;
			FILE_INFO files[LOG_LEVEL_NUM];
			MODULE_INFO()
			{
				files[LOG_INFO].subdir = "info";
				files[LOG_ERROR].subdir = "error";
				files[LOG_DEBUG].subdir = "debug";
				files[LOG_EXT_INFO].subdir = "ext_info";
			}
			void closeFD()
			{
				for(int i=0; i<LOG_LEVEL_NUM; ++i)
				{
					if(files[i].fd != -1)
					{
						::close(files[i].fd);
						files[i].fd = -1;
					}
				}
			}
		};

		typedef map<string, MODULE_INFO> MODULE_MAP;
		
	public:

		CLogWriter();

		~CLogWriter();

		//打开一个日志模块，路径位于config.logPath/moduleName/
		int open(const char* moduleName, int logLevel);

		//绑定一个时间地址，作为日志时间
		inline void bind_time(const timeval* ptheTime, const char* ptheHourstr)
		{
			m_ptheTime = ptheTime;
			m_ptheHourstr = ptheHourstr;
		}
		
		//绑定一个配置
		inline void bind_config(LOG_CONFIG* pconfig)
		{
			m_pconfig = pconfig;
		}

		//切换到已经打开的模块日志，如果没有打开过返回-1
		int shift_module(const char* moduleName);

		//写日志，把m_buff内容写到文件中
		int write(const char* buff, unsigned int len, int loglevel);

		//写日志，把m_buff内容写到文件中
		int write_inner(const char* buff, unsigned int len, int loglevel);

		//关闭指定的module，NULL则关闭当前的module，当前module被关闭，第一个打开的module成为当前module
		int close(const char* moduleName = NULL);

	protected:
		//allowseq表示无论当前时间对应的文件是否已存在，使用seq重新打开新文件
		int open_fd(const char* moduleName, FILE_INFO& fileInfo, bool allowseq=false);

		int check_dir(const char* path);

	public:
		char m_errmsg[256];
		
	protected:
		LOG_CONFIG* m_pconfig;
		const timeval *m_ptheTime;
		const char* m_ptheHourstr;
		MODULE_MAP m_mapModule;
		MODULE_MAP::iterator m_curModule;
		int m_write_cnt;
};


class CLogPipe
{
	public:
		typedef map<string, int> LOG_LEVEL_MAP;
		
	public:
		CLogPipe();

		int open(const char* moduleName, int logLevel);
		
		int write(const char* buff, unsigned int len, int loglevel);

		int shift_module(const char* moduleName);

		inline void bind_time(const timeval* ptheTime, const char* ptheHourstr)
		{
			m_ptheTime = ptheTime;
			m_ptheHourstr = ptheHourstr;
		}

		inline void bind_config(LOG_CONFIG* pconfig)
		{
			m_pconfig = pconfig;
		}
		
	protected:
		const timeval *m_ptheTime;
		const char* m_ptheHourstr;
		LOG_CONFIG* m_pconfig;
		LOG_LEVEL_MAP::iterator m_curModule;
		LOG_LEVEL_MAP m_mapModule;
};


//logpoxy对外服务，根据不同的策略，可以写到共享内存队列中，直接写文件
class CLogProxy
{
	public:
		CLogProxy();
		inline void set_config(LOG_CONFIG& config)
		{
			m_config = config;
		}
		
		//打开一个日志模块，路径位于config.logPath/moduleName/
		int open(const char* moduleName=NULL, int logLevel=LOG_DEBUG);

		//绑定一个时间地址，作为日志时间
		inline void bind_time(const timeval* ptheTime)
		{
			m_ptheTime = ptheTime;
		}

		//切换到已经打开的模块日志，如果没有打开过返回-1
		int shift_module(const char* moduleName);

		//写日志，把m_buff内容写到文件中
		int write(int loglevel);

		//关闭指定的module，NULL则关闭当前的module，当前module被关闭，第一个打开的module成为当前module
		int close(const char* moduleName = NULL);

		static string make_hour_string(time_t nowtime);

		inline void set_pid(pid_t pid)
		{
			m_pid = pid;
		}

		inline void set_writer_proxy(CWriterProxy *writer)
		{
			m_writer_proxy = writer;
		}

		inline void update_now()
		{
			if(m_ptheTime == NULL)
			{
				gettimeofday(&m_timecache, NULL);
			}
			else
			{
				m_timecache = *m_ptheTime;
			}

			if(m_cachehourtag != m_timecache.tv_sec/3600)
			{
				m_cachehourtag = m_timecache.tv_sec/3600;
				struct tm * ptm = localtime(&m_timecache.tv_sec);
				snprintf(m_cachehourstring, sizeof(m_cachehourstring), "%04d%02d%02d%02d", ptm->tm_year+1900, ptm->tm_mon+1, ptm->tm_mday, ptm->tm_hour);
			}
		}

		inline const char* head_str()
		{
			update_now();

			if(m_pid < 0)
				set_pid(getpid());

			int min = (m_timecache.tv_sec%3600)/60;
			int usec = m_timecache.tv_usec;
			int sec = m_timecache.tv_sec%60;
			snprintf(m_headstr, sizeof(m_headstr), "%s:%02d:%02d.%06d|%d"
				, m_cachehourstring, min, sec, usec
				, m_pid);
			return m_headstr;
		}

	protected:
		CLogWriter m_writer;
		CLogPipe m_pipe;
		LOG_CONFIG m_config;
		char m_headstr[1024];
		const timeval *m_ptheTime;
		timeval m_timecache; //传递给m_writer, m_pipe;
		char m_cachehourstring[16];
		int m_cachehourtag;
		pid_t m_pid;
		CWriterProxy *m_writer_proxy;

	public:
		char m_errmsg[256];
		char m_buff[CLogWriter::LOG_LINE_SIZE];
		unsigned m_len;
};


//使用者如是调用
//使用LOG_TIME可以绑定一个外部的时间，否则每次都调用gettimeofday
//第一次LOG日志确定当前进程id，
//fork的时候小心了，可以调用重设LOG_SET_PID(-1)
//debug,info,error分目录打日志，每个小时一个日志，日志接近2G切换新文件

extern CLogProxy gLogObj;

#define LOG_CONFIG_SET(config) gLogObj.set_config(config)
#define LOG_OPEN(module, level) gLogObj.open(module, level)
#define LOG_OPEN_DEFAULT(nullValue) gLogObj.open(nullValue, LOG_DEBUG)
#define LOG_TIME(timePointer) gLogObj.bind_time(timePointer)
#define LOG_SET_PID(pid) gLogObj.set_pid(pid)
#define LOG_SET_WRITER_PROXY(writerProxy) gLogObj.set_writer_proxy(writerProxy)
#define LOG_MODULE(module) gLogObj.shift_module(module)
#define LOG(loglevel, format, args...)  (gLogObj.m_len = snprintf(gLogObj.m_buff, sizeof(gLogObj.m_buff), "%s|%s|%d|"format"\r\n", gLogObj.head_str(),__FILE__,__LINE__,##args))>0?gLogObj.write(loglevel): -1
//#define LOG(loglevel, format, args...) (gLogObj.m_len = snprintf(gLogObj.m_buff, sizeof(gLogObj.m_buff), "%s|%d|"format"\r\n",__FILE__,__LINE__,##args))>0?gLogObj.write(loglevel): -1


#define LOG_CLOSE(module) gLogObj.close(module)
#define LOG_GET_ERRMSGSTRING gLogObj.m_errmsg

#define LOG_STAT LOG_EXT_INFO
#include "log_stat.h"

#endif

