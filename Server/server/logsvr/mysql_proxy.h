#ifndef __MYSQL_PROXY_H__
#define __MYSQL_PROXY_H__
#include <iostream>
#include <string.h>
#include <sstream>
#include "ini/ini_file.h"
#include "log/log.h"
#include "mysql_wrap/mysql_wrap.h"
#include "common/msg_define.h"
#include "common/sleep_control.h"
#include "common/mem_guard.h"
#include "common/speed_control.h"
#include <sys/time.h>
#include "mysql_table_wrapper.h"
#include "time/time_util.h"
#include "string/strutil.h"

using namespace std;
/*
* 负责与mysql之间的交互
*
*/
extern int gDebugFlag;

class CMysqlProxyConfig
{
public:
	int readLimitPerSecond; //每秒读请求限制
	int writeLimitPerSecond; //每秒写请求限制
	char mysqlSvrIP[32];
	unsigned int mysqlSvrPort;
	char mysqlUser[128];
	char mysqlPassword[128];
	char mysqlSock[128];
	char mysqlTablePrefix[128];
	int mysqlKeepAlive;
	int mysqltimeout;
	char dbNameLog[128];
	char tabNameLogDeposit[128];
	char tabNameLogBindInfo[128];
	char tabNameLogBattleCheat[128];
	char tabNameLogMarketSell[128];
	char tabNameLogUserInfo[128];
	char tabNameLogIssueInfo[128];

	CMysqlProxyConfig()
	{
		readLimitPerSecond = 0;
		writeLimitPerSecond = 0;
		mysqlSvrIP[0] = 0;
		mysqlSvrPort = 0;
		mysqlUser[0] = 0;
		mysqlPassword[0] = 0;
		mysqlSock[0]=0;
		mysqlTablePrefix[0] = 0;
		mysqlKeepAlive = 0;
		mysqltimeout = -1;
		dbNameLog[0] = 0;
		tabNameLogDeposit[0] = 0;
		tabNameLogBindInfo[0] = 0;
		tabNameLogMarketSell[0] = 0;
		tabNameLogUserInfo[0] = 0;
	}

	void debug(ostream& os)
	{
		os << "CMysqlProxyConfig{" << endl;
		os << "readLimitPerSecond|" << readLimitPerSecond << endl;
		os << "writeLimitPerSecond|" << writeLimitPerSecond << endl;
		os << "mysqlSvrIP|" << mysqlSvrIP << endl;
		os << "mysqlSvrPort|" << mysqlSvrPort << endl;
		os << "mysqlUser|" << mysqlUser << endl;
		os << "mysqlPassword|" << mysqlPassword << endl;
		os << "mysqlSock|" << mysqlSock << endl;
		os << "mysqlTablePrefix|" << mysqlTablePrefix << endl;
		os << "mysqlKeepAlive|" << mysqlKeepAlive << endl;
		os << "mysqltimeout|" << mysqltimeout << endl;
		os << "dbNameLog|" << dbNameLog << endl;
		os << "tabNameLogDeposit|" << tabNameLogDeposit << endl;
		os << "tabNameLogBindInfo|" << tabNameLogBindInfo << endl;
		os << "tabNameLogBattleCheat|" << tabNameLogBattleCheat << endl; 
		os << "tabNameLogMarketSell|" << tabNameLogMarketSell << endl;
		os << "tabNameLogUserInfo|" << tabNameLogUserInfo << endl; 
		os << "}END CMysqlProxyConfig" << endl;
	}

	int read_from_ini(const char* file, const char* sectorName)
	{
		CIniFile oIni(file);
		if(!oIni.IsValid())
		{
			LOG(LOG_ERROR, "read ini %s fail", file);
			return -1;
		}

		return read_from_ini(oIni, sectorName);
	}
	
	int read_from_ini(CIniFile& oIni, const char* sectorName)
	{
		if(oIni.GetInt(sectorName, "READ_LIMIT", 0, &readLimitPerSecond)!=0)
		{
			LOG(LOG_ERROR, "%s.READ_LIMIT not found", sectorName);
			return -1;
		}

		if(oIni.GetInt(sectorName, "WRITE_LIMIT", 0, &writeLimitPerSecond)!=0)
		{
			LOG(LOG_ERROR, "%s.WRITE_LIMIT not found", sectorName);
			return -1;
		}

		if(oIni.GetString(sectorName, "MYSQL_IP", "", mysqlSvrIP, sizeof(mysqlSvrIP))!=0)
		{
			LOG(LOG_ERROR, "%s.MYSQL_IP not found", sectorName);
			return -1;
		}

		if(oIni.GetInt(sectorName, "MYSQL_PORT", 0, &mysqlSvrPort)!=0)
		{
			LOG(LOG_ERROR, "%s.MYSQL_PORT not found", sectorName);
			return -1;
		}

		if(oIni.GetString(sectorName, "MYSQL_USER", "", mysqlUser, sizeof(mysqlUser))!=0)
		{
			LOG(LOG_ERROR, "%s.MYSQL_USER not found", sectorName);
			return -1;
		}
		
		if(oIni.GetString(sectorName, "MYSQL_PASSWORD", "", mysqlPassword, sizeof(mysqlPassword))!=0)
		{
			LOG(LOG_ERROR, "%s.MYSQL_PASSWORD not found", sectorName);
			return -1;
		}

		if(oIni.GetString(sectorName, "MYSQL_SOCK", "", mysqlSock, sizeof(mysqlSock))!=0)
		{
			LOG(LOG_ERROR, "%s.MYSQL_SOCK not found", sectorName);
			return -1;
		}

		if(oIni.GetInt(sectorName, "MYSQL_KEEPALIVE", 0, &mysqlKeepAlive)!=0)
		{
			LOG(LOG_ERROR, "%s.MYSQL_KEEPALIVE not found", sectorName);
			return -1;
		}

		if(oIni.GetInt(sectorName, "MYSQL_TIMEOUT", 0, &mysqltimeout)!=0)
		{
			LOG(LOG_ERROR, "%s.MYSQL_TIMEOUT not found", sectorName);
			return -1;
		}

		if(oIni.GetString(sectorName, "MYSQL_DBNAME_LOG", "", dbNameLog, sizeof(dbNameLog))!=0)
		{
			LOG(LOG_ERROR, "%s.MYSQL_DBNAME_LOG not found", sectorName);
			return -1;
		}

		return 0;
	}
};

typedef map<TableType, CMysqlTableWrapper *> MysqlTableMap;
typedef map<string, MysqlDB *> MysqlDBMap;
class CMysqlProxy
{
	//必须配套使用
	#define START_QUERY_TIME gettimeofday(&start_t, NULL);
	#define END_QUERY_TIME gettimeofday(&end_t, NULL); \
		m_interval = (end_t.tv_sec - start_t.tv_sec)*1000 + (end_t.tv_usec - start_t.tv_usec)/1000;
		
	public:
		typedef ::google::protobuf::int64 int64; 
		CMysqlProxy();
		~CMysqlProxy();
		int init(CMysqlProxyConfig &config, bool initTable = true);
		int update(time_t nowTime);
		void setNoEscape(bool flag);
		string getEscapedData(const string &dbName, const string &data);

		MysqlDB *getDB(const string &dbName);
		CMysqlTableWrapper *getTable(TableType type);
		int query(const string &dbName, const string &sql, MysqlResult &result);

		static string parseMysqlString(const string &mysqlStr);
		static string toMysqlString(const string &stdStr);

		static time_t parseMysqlDateTime(const string &mysqlTime);
		static string toMysqlDateTime(time_t time);

		static int parseMysqlInt(const string &valueStr);
		static string toMysqlInt(int value);

		static int64 parseMysqlBigInt(const string &mysqlBigInt);
		static string toMysqlBigInt(int64 value);

		static int codeConvert(const char* from_charset,const char* to_charset, const char* inbuf, size_t inleft, char* outbuf, size_t& outleft);
		static int gbk_utf8(const string& gbkStr, string& utf8Str);
		static int utf8_gbk(string& str);

	protected:
		MysqlDB* initDB(const string &dbName);
		void freeDB(MysqlDB*& theDB);

		void addDB(const string &dbName, MysqlDB *pDB);	
		void addTable(CMysqlTableWrapper *pTable);
	protected:
		MysqlDBMap mDBMap;
		unsigned long readcnt;
		unsigned long writecnt;
		unsigned long totalcnt;
		unsigned long readlimited;
		unsigned long writelimited;
		CMysqlProxyConfig mConfig;
		timeval start_t;
		timeval end_t;
		int m_interval;
		MysqlTableMap mTableMap;
		bool mNoEscape;
		static const int SLOW_MS=10;
};

#endif 

