#include "log.h"
#include <sys/time.h> 
#include <time.h> 
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h> 
#include <errno.h>
#include <string.h>
#include <iostream>
#include "../lock/lock_guard.h"
#include "../lock/lock_file.h"
using namespace std;

#define GET_SYS_ERRMSG(prefix, errmsg, len) snprintf(errmsg, len, "%s %d %s", prefix, errno, strerror(errno))
const char* CLogWriter::LOG_PATH = "/usr/local/log/";

//config
LOG_CONFIG::LOG_CONFIG()
{
	globeLogLevel = LOG_DEBUG;
	logPath = CLogWriter::LOG_PATH;
	proxyType = LOG_LOCAL;
	fileLock = 0;
}

LOG_CONFIG::LOG_CONFIG(CIniFile& oIni, const char* sectorName)
{
	read_from_ini(oIni, sectorName);
}

void LOG_CONFIG::debug(ostream& out)
{
	out << "LOG_CONFIG{" << endl;
	out << "globeLogLevel|" << globeLogLevel << endl;
	out << "logPath|" << logPath << endl;
	out << "proxyType|" << proxyType << endl;
	out << "fileLock|" << fileLock << endl;
	out << "defaultModule|" << defaultModule << endl;
	out << "}END LOG_CONFIG" << endl;
}

void LOG_CONFIG::read_from_ini(CIniFile& oIni, const char* sectorName)
{
	char theLogPath[1024];
	char module[128];
	int theProxyType = 0;
	int glogLevel = 0;
	int theFileLock = 0;
	oIni.GetString(sectorName, "LOG_PATH", CLogWriter::LOG_PATH, theLogPath, sizeof(theLogPath));
	oIni.GetString(sectorName, "LOG_MODULE", "XXX", module, sizeof(module));
	oIni.GetInt(sectorName, "LOG_PROXY_TYPE", LOG_LOCAL, &theProxyType);
	oIni.GetInt(sectorName, "LOG_LEVEL", LOG_DEBUG, &glogLevel);
	oIni.GetInt(sectorName, "FILE_LOCK", 0, &theFileLock);
	if(glogLevel < LOG_INFO || glogLevel >= LOG_LEVEL_NUM )
	{
		glogLevel = LOG_DEBUG;
	}

	if(theProxyType < LOG_LOCAL || theProxyType > LOG_SERVER_LOCAL)
	{
		theProxyType = LOG_LOCAL;
	}

	if(theFileLock != 0 )
	{
		fileLock = 1;
	}
	else
	{
		fileLock = 0;
	}
	
	logPath = theLogPath;
	globeLogLevel = glogLevel;
	proxyType = theProxyType;
	defaultModule = module;
}


//--------------------------------------------------CLogWriter---------------------------------------------
CLogWriter::CLogWriter()
{
	m_ptheTime = NULL;
	m_pconfig = NULL;
	m_curModule = m_mapModule.end();
	m_errmsg[0] = 0;
	m_write_cnt = 0;
}

int CLogWriter::open(const char* moduleName, int logLevel)
{
	if(logLevel > LOG_LEVEL_NUM)
		return -1;

	if(m_mapModule.find(moduleName) != m_mapModule.end())
	{
		snprintf(m_errmsg, sizeof (m_errmsg), "%s has opend", moduleName);
		return -1;
	}

	MODULE_INFO moduleInfo;
	moduleInfo.logLevel = logLevel;
	int ret;

	char dirName[1024];
	string path;
	if(m_pconfig)
	{
		path = m_pconfig->logPath;
	}
	else
	{
		path = LOG_PATH;
	}

	snprintf(dirName, sizeof(dirName), "%s/%s", path.c_str(), moduleName);
	ret = check_dir(dirName);
	if(ret != 0)
		return -1;
	
	for(unsigned int i=0; i<LOG_LEVEL_NUM; ++i)
	{
		snprintf(dirName, sizeof(dirName), "%s/%s/%s", path.c_str(), moduleName, moduleInfo.files[i].subdir.c_str());
		ret = check_dir(dirName);
		if(ret != 0)
			return -1;
	/*写时再去open	
		ret = open_fd(moduleName, moduleInfo.files[i]);
		if(ret != 0)
		{
			return -1;
		}
	*/	
	}

	//map操作
	m_mapModule[moduleName] = moduleInfo;
	m_curModule = m_mapModule.find(moduleName);
	return 0;
	
}


int CLogWriter::shift_module(const char* moduleName)
{
	MODULE_MAP::iterator newModule = m_mapModule.find(moduleName);
	if(newModule != m_mapModule.end())
	{
		m_curModule = newModule;
		return 0;
	}

	return -1;
}

int CLogWriter::write(const char* buff, unsigned int len, int loglevel)
{
	if(m_curModule == m_mapModule.end())
		return -1;

	if(loglevel > LOG_LEVEL_NUM)
		return -1;

	//检查配置的loglevel
	if( (m_pconfig && loglevel > m_pconfig->globeLogLevel) || loglevel > m_curModule->second.logLevel)
	{
		return 0;
	}

	//看下时间对不对
	int ret = open_fd(m_curModule->first.c_str(),m_curModule->second.files[loglevel]);
	if(ret != 0)
		return -1;

	int fd = m_curModule->second.files[loglevel].fd;
	
	//检查大小,不必要那么勤快
	if(++m_write_cnt >= FILE_SIZE_CHECK_COUNT)
	{
		m_write_cnt = 0;
		struct stat statbuf;
		ret = fstat(fd, &statbuf);
		if(ret != 0)
			return -1;
			
		if((unsigned int)(statbuf.st_size) > LOG_FILE_SIZE)
		{
			ret = open_fd(m_curModule->first.c_str(),m_curModule->second.files[loglevel], true);
			if(ret != 0)
				return -1;
			fd = m_curModule->second.files[loglevel].fd;
		}
	}

	if(m_pconfig && m_pconfig->fileLock)
	{
	//貌似write buff不满的情况下，本身就是原子操作。不建议用锁
		CLockFile lock;
		lock.init(fd);
		CLockGuard guard(lock);
		return  ::write(fd, buff, len);
	}
	else
	{
		return  ::write(fd, buff, len);
	}
}

CLogWriter::~CLogWriter()
{
	MODULE_MAP::iterator it;
	for(it = m_mapModule.begin(); it != m_mapModule.end(); ++it)
	{
		it->second.closeFD();
	}
}


int CLogWriter::close(const char* moduleName)
{
	MODULE_MAP::iterator theIt;
	bool self = false;
	string name;

	if(moduleName != NULL)
	{
		theIt = m_mapModule.find(moduleName);
		if(theIt == m_mapModule.end())
			return 0;
			
		if(theIt == m_curModule)
		{
			self = true;
		}
		else
		{
			name = m_curModule->first;
		}
	}
	else
	{
		theIt = m_curModule;
		self = true;
	}

	theIt->second.closeFD();
	m_mapModule.erase(theIt);
	if(self)
	{
		m_curModule = m_mapModule.begin();
	}
	else
	{
		m_curModule = m_mapModule.find(name);
	}

	return 0;
}

int CLogWriter::check_dir(const char* path)
{
	struct stat statbuf;
	int ret = stat(path, &statbuf);
	if(ret != 0)
	{
		if(errno == ENOENT)
		{
			//mkdir
			ret = mkdir(path, 0777);
			if(ret != 0)
			{
				GET_SYS_ERRMSG("mkdir=",m_errmsg, sizeof(m_errmsg));
				return -1;
			}
		}
		else
		{
			GET_SYS_ERRMSG("stat=",m_errmsg, sizeof(m_errmsg));
			return -1;
		}
	}
	else
	{
		if(!S_ISDIR(statbuf.st_mode))
		{
			snprintf(m_errmsg, sizeof(m_errmsg), "%s not dir", path);
			return -1;
		}
	}

	return 0;
}

int CLogWriter::open_fd(const char* moduleName,  FILE_INFO& fileInfo, bool allowseq)
{
	char fileName[1024];
	string path;
	if(m_pconfig)
	{
		path = m_pconfig->logPath;
	}
	else
	{
		path = LOG_PATH;
	}

	int hour = (m_ptheTime->tv_sec)/3600;
	if(hour != fileInfo.hour)
	{
		fileInfo.seq = 0;
		fileInfo.hour = hour;
	}
	else
	{
		if(!allowseq)
			return 0;
		++ fileInfo.seq;
	}

	
	if(fileInfo.seq == 0)
		snprintf(fileName, sizeof(fileName), "%s/%s/%s/%s.log", path.c_str(), moduleName, fileInfo.subdir.c_str(), m_ptheHourstr);
	else
		snprintf(fileName, sizeof(fileName), "%s/%s/%s/%s.%d.log", path.c_str(), moduleName, fileInfo.subdir.c_str(), m_ptheHourstr, fileInfo.seq);

	if(fileInfo.fd >= 0)
		::close(fileInfo.fd);
		
	fileInfo.fd = ::open(fileName, O_WRONLY | O_CREAT| O_APPEND, 0666);
	if(fileInfo.fd < 0)
	{
		GET_SYS_ERRMSG("open=",m_errmsg, sizeof(m_errmsg));
		return -1;
	}

	return 0;
}

//--------------------------------------------------CLogPipe---------------------------------------------
CLogPipe::CLogPipe()
{
	m_ptheTime = NULL;
	m_pconfig = NULL;
	m_curModule = m_mapModule.end();
}

int CLogPipe::open(const char* moduleName, int logLevel)
{
	if(logLevel > LOG_LEVEL_NUM)
		return -1;
	//简化逻辑，允许同一个modulename open多次，最后一次为准
	m_mapModule[moduleName] = logLevel;
	m_curModule = m_mapModule.find(moduleName);
	return 0;
}


int CLogPipe::shift_module(const char* moduleName)
{
	LOG_LEVEL_MAP::iterator newModule = m_mapModule.find(moduleName);
	if(newModule != m_mapModule.end())
	{
		m_curModule = newModule;
		return 0;
	}

	return -1;
}

int CLogPipe::write(const char* buff, unsigned int len, int loglevel)
{
	//检查配置的loglevel
	if( (m_pconfig && loglevel > m_pconfig->globeLogLevel) || loglevel > m_curModule->second)
	{
		return 0;
	}
	//TODO...
	return -1;
}

//--------------------------------------------------CLogProxy---------------------------------------------

CLogProxy::CLogProxy()
{
	m_len= 0;
	m_writer.bind_config(&m_config);
	m_pipe.bind_config(&m_config);
	m_errmsg[0] = 0;
	m_headstr[0] = 0;
	m_ptheTime = NULL;
	m_pid = -1;
	m_cachehourtag = 0;
	m_writer_proxy = NULL;
}

int CLogProxy::open(const char* moduleName, int logLevel)
{
	//绑定时间
	if(m_config.proxyType == LOG_LOCAL || m_config.proxyType == LOG_SERVER_LOCAL)
	{
		m_writer.bind_time(&m_timecache, m_cachehourstring);
	}

	if(m_config.proxyType == LOG_SERVER || m_config.proxyType == LOG_SERVER_LOCAL)
	{
		m_pipe.bind_time(&m_timecache, m_cachehourstring);
	}

	//获取下时间
	update_now();
	
	int ret;
	if(moduleName == NULL)
	{
		moduleName = m_config.defaultModule.c_str();
	}
	
	if(m_config.proxyType == LOG_LOCAL)
	{
		ret = m_writer.open(moduleName, logLevel);
		if(ret != 0)
		{
			snprintf(m_errmsg, sizeof(m_errmsg), "%s", m_writer.m_errmsg);
		}
		return ret;
	}
	else  if(m_config.proxyType == LOG_SERVER )
	{
		return m_pipe.open(moduleName, logLevel);
	}
	else if( m_config.proxyType == LOG_SERVER_LOCAL)
	{
		ret = m_writer.open(moduleName, logLevel);
		if(ret != 0)
		{
			snprintf(m_errmsg, sizeof(m_errmsg), "%s", m_writer.m_errmsg);
			return ret;
		}
		return m_pipe.open(moduleName, logLevel);
	}
	
	snprintf(m_errmsg, sizeof(m_errmsg), "m_config.proxyType=%d not valid", m_config.proxyType);
	return -1;
}

int CLogProxy::shift_module(const char* moduleName)
{
	int ret = 0;
	if(m_config.proxyType == LOG_LOCAL)
	{
		ret = m_writer.shift_module(moduleName);
		if(ret != 0)
		{
			snprintf(m_errmsg, sizeof(m_errmsg), m_writer.m_errmsg);
		}
		return ret;
	}
	else if(m_config.proxyType == LOG_SERVER)
	{
		return m_pipe.shift_module(moduleName);
	}
	else if(m_config.proxyType == LOG_SERVER_LOCAL)
	{
		ret = m_writer.shift_module(moduleName);
		if(ret != 0)
		{
			snprintf(m_errmsg, sizeof(m_errmsg), m_writer.m_errmsg);
			return ret;
		}
		return m_pipe.shift_module(moduleName);
	}

	snprintf(m_errmsg, sizeof(m_errmsg), "m_config.proxyType=%d not valid", m_config.proxyType);
	return -1;
}

int CLogProxy::write(int loglevel)
{
	int ret = 0;

	if(m_config.proxyType == LOG_LOCAL)
	{
		ret = m_writer.write(m_buff, m_len, loglevel);
		if(ret != 0)
		{
			snprintf(m_errmsg, sizeof(m_errmsg), m_writer.m_errmsg);
		}
	}
	else if(m_config.proxyType == LOG_SERVER)
	{
		ret = m_pipe.write(m_buff, m_len, loglevel);
	}
	else  if(m_config.proxyType == LOG_SERVER_LOCAL)
	{
		if(m_pipe.write(m_buff, m_len, loglevel) != 0)
		{
			ret = m_writer.write(m_buff, m_len, loglevel);
			if(ret != 0)
			{
				snprintf(m_errmsg, sizeof(m_errmsg), m_writer.m_errmsg);
			}
		}
	}
	else
	{
		snprintf(m_errmsg, sizeof(m_errmsg), "m_config.proxyType=%d not valid", m_config.proxyType);
		return -1;
	}
	
	//用代理写数据
	if( m_writer_proxy != NULL )
	{
		m_writer_proxy->writeData(m_buff, m_len, loglevel);
	}

	return ret;
}

int CLogProxy::close(const char* moduleName)
{
	int ret;
	if(m_config.proxyType == LOG_LOCAL || m_config.proxyType == LOG_SERVER_LOCAL)
	{
		ret = m_writer.close(moduleName);
		if(ret != 0)
		{
			snprintf(m_errmsg, sizeof(m_errmsg), m_writer.m_errmsg);
		}
		return ret;
	}

	return 0;
}


CLogProxy gLogObj;


