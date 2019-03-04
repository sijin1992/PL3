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
//add by bool TRACE�������debug�������ǵ���ʱ�����õ�
#define LOG_TRACE LOG_DEBUG

enum LOG_LEVEL
{
	LOG_INFO = 0,	//�ɹ��������ھ������
	LOG_ERROR = 1,	//�����Ĵ���
	LOG_DEBUG = 2,	 //�������Ժ͸��ٵ�����
	LOG_EXT_INFO = 3,	// �����û���Ϊ
	LOG_LEVEL_NUM
};

enum LOG_PROXY_TYPE
{//ֵ���ܸ�Ŷ
	LOG_LOCAL = 0, //ֱ��д�ļ�
	LOG_SERVER = 1, //ͨ�������ڴ���и�logserver
	LOG_SERVER_LOCAL =2 //���ȸ����У����еĻ���local����ֹ���緢��
};

struct LOG_CONFIG
{
	string logPath; //��־��Ŀ¼��Ĭ��LOG_PTAH
	int globeLogLevel; //ȫ�ֵ�log level���ƣ�Ĭ����LOG_DEBUG
	int proxyType; //Ĭ����LOG_LOCAL
	int fileLock; //�Ƿ���Ҫ���ļ�����Ĭ����0
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
		static const int FILE_SIZE_CHECK_COUNT = 1000; //ÿ1000��ѭ����һ���ļ���С
		static const unsigned int LOG_FILE_SIZE = 1024*(2*1024*1024 -(LOG_LINE_SIZE/1024+1)*FILE_SIZE_CHECK_COUNT); 

		struct FILE_INFO
		{
			int hour; //��ȷ��Сʱ��ʱ��,�����Ƚ��Ƿ���Ҫ�л���־
			int fd; //fd
			int seq; //��LOG_FILE_SIZE���ļ�������
			string subdir; //��־��Ŀ¼(info error debug)
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

		//��һ����־ģ�飬·��λ��config.logPath/moduleName/
		int open(const char* moduleName, int logLevel);

		//��һ��ʱ���ַ����Ϊ��־ʱ��
		inline void bind_time(const timeval* ptheTime, const char* ptheHourstr)
		{
			m_ptheTime = ptheTime;
			m_ptheHourstr = ptheHourstr;
		}
		
		//��һ������
		inline void bind_config(LOG_CONFIG* pconfig)
		{
			m_pconfig = pconfig;
		}

		//�л����Ѿ��򿪵�ģ����־�����û�д򿪹�����-1
		int shift_module(const char* moduleName);

		//д��־����m_buff����д���ļ���
		int write(const char* buff, unsigned int len, int loglevel);

		//д��־����m_buff����д���ļ���
		int write_inner(const char* buff, unsigned int len, int loglevel);

		//�ر�ָ����module��NULL��رյ�ǰ��module����ǰmodule���رգ���һ���򿪵�module��Ϊ��ǰmodule
		int close(const char* moduleName = NULL);

	protected:
		//allowseq��ʾ���۵�ǰʱ���Ӧ���ļ��Ƿ��Ѵ��ڣ�ʹ��seq���´����ļ�
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


//logpoxy������񣬸��ݲ�ͬ�Ĳ��ԣ�����д�������ڴ�����У�ֱ��д�ļ�
class CLogProxy
{
	public:
		CLogProxy();
		inline void set_config(LOG_CONFIG& config)
		{
			m_config = config;
		}
		
		//��һ����־ģ�飬·��λ��config.logPath/moduleName/
		int open(const char* moduleName=NULL, int logLevel=LOG_DEBUG);

		//��һ��ʱ���ַ����Ϊ��־ʱ��
		inline void bind_time(const timeval* ptheTime)
		{
			m_ptheTime = ptheTime;
		}

		//�л����Ѿ��򿪵�ģ����־�����û�д򿪹�����-1
		int shift_module(const char* moduleName);

		//д��־����m_buff����д���ļ���
		int write(int loglevel);

		//�ر�ָ����module��NULL��رյ�ǰ��module����ǰmodule���رգ���һ���򿪵�module��Ϊ��ǰmodule
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
		timeval m_timecache; //���ݸ�m_writer, m_pipe;
		char m_cachehourstring[16];
		int m_cachehourtag;
		pid_t m_pid;
		CWriterProxy *m_writer_proxy;

	public:
		char m_errmsg[256];
		char m_buff[CLogWriter::LOG_LINE_SIZE];
		unsigned m_len;
};


//ʹ�������ǵ���
//ʹ��LOG_TIME���԰�һ���ⲿ��ʱ�䣬����ÿ�ζ�����gettimeofday
//��һ��LOG��־ȷ����ǰ����id��
//fork��ʱ��С���ˣ����Ե�������LOG_SET_PID(-1)
//debug,info,error��Ŀ¼����־��ÿ��Сʱһ����־����־�ӽ�2G�л����ļ�

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

