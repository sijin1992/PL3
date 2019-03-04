#include <iostream>
#include <string.h>
#include <sstream>
#include "ini/ini_file.h"
#include "mysql_wrap/mysql_wrap.h"
#include "proto/userData.pb.h"
#include "common/msg_define.h"

using namespace std;

class CMysqlConfig
{
public:
	int procNum; //进程数量
	int readLimitPerSecond; //每秒读请求限制
	int writeLimitPerSecond; //每秒写请求限制
	char mysqlSvrIP[32];
	unsigned int mysqlSvrPort;
	char mysqlUser[128];
	char mysqlPassword[128];
	char mysqlDBPrefix[128];
	char mysqlSock[128];
	int mysqlDBModulus;
	//int mysqlDBStartIdx;
	//int mysqlDBEndIdx;
	char mysqlTablePrefix[128];
	int mysqlTableModulus;
	int mysqlKeepAlive;
	unsigned int queueID;
	int mysqltimeout;

	CMysqlConfig()
	{
		procNum = 0;
		readLimitPerSecond = 0;
		writeLimitPerSecond = 0;
		mysqlSvrIP[0] = 0;
		mysqlSvrPort = 0;
		mysqlUser[0] = 0;
		mysqlPassword[0] = 0;
		queueID = 0;
		mysqlDBPrefix[0] = 0;
		mysqlSock[0]=0;
		mysqlTablePrefix[0] = 0;
		mysqlDBModulus = 0;
		//mysqlDBStartIdx = 0;
		//mysqlDBEndIdx = 0;
		mysqlTableModulus = 0;
		mysqlKeepAlive = 0;
		mysqltimeout = -1;
	}

	void debug(ostream& os)
	{
		os << "CMysqlHelperConfig{" << endl;
		os << "procNum|" << procNum << endl;
		os << "readLimitPerSecond|" << readLimitPerSecond << endl;
		os << "writeLimitPerSecond|" << writeLimitPerSecond << endl;
		os << "mysqlSvrIP|" << mysqlSvrIP << endl;
		os << "mysqlSvrPort|" << mysqlSvrPort << endl;
		os << "mysqlUser|" << mysqlUser << endl;
		os << "mysqlPassword|" << mysqlPassword << endl;
		os << "queueID|" << queueID << endl;
		os << "mysqlSock|" << mysqlSock << endl;
		os << "mysqlDBPrefix|" << mysqlDBPrefix << endl;
		os << "mysqlTablePrefix|" << mysqlTablePrefix << endl;
		os << "mysqlDBModulus|" << mysqlDBModulus << endl;
		//os << "mysqlDBStartIdx|" << mysqlDBStartIdx << endl;
		//os << "mysqlDBEndIdx|" << mysqlDBEndIdx << endl;
		os << "mysqlTableModulus|" << mysqlTableModulus << endl;
		os << "mysqlKeepAlive|" << mysqlKeepAlive << endl;
		os << "mysqltimeout|" << mysqltimeout << endl;
		os << "}END CMysqlHelperConfig" << endl;
	}

	int read_from_ini(const char* file, const char* sectorName)
	{
		CIniFile oIni(file);
		if(!oIni.IsValid())
		{
			return -1;
		}

		return read_from_ini(oIni, sectorName);
	}
	
	int read_from_ini(CIniFile& oIni, const char* sectorName)
	{
		if(oIni.GetInt(sectorName, "PROC_NUM", 0, &procNum)!=0)
		{
			return -1;
		}

		if(oIni.GetInt(sectorName, "READ_LIMIT", 0, &readLimitPerSecond)!=0)
		{
			return -1;
		}

		if(oIni.GetInt(sectorName, "WRITE_LIMIT", 0, &writeLimitPerSecond)!=0)
		{
			return -1;
		}

		if(oIni.GetString(sectorName, "MYSQL_IP", "", mysqlSvrIP, sizeof(mysqlSvrIP))!=0)
		{
			return -1;
		}

		if(oIni.GetInt(sectorName, "MYSQL_PORT", 0, &mysqlSvrPort)!=0)
		{
			return -1;
		}

		if(oIni.GetString(sectorName, "MYSQL_USER", "", mysqlUser, sizeof(mysqlUser))!=0)
		{
			return -1;
		}
		
		if(oIni.GetString(sectorName, "MYSQL_PASSWORD", "", mysqlPassword, sizeof(mysqlPassword))!=0)
		{
			return -1;
		}

		if(oIni.GetInt(sectorName, "GLOBE_QUEUE_ID", 0, &queueID)!=0)
		{
			return -1;
		}

		if(oIni.GetString(sectorName, "MYSQL_SOCK", "", mysqlSock, sizeof(mysqlSock))!=0)
		{
			return -1;
		}

		if(oIni.GetString(sectorName, "MYSQL_DB_NAME_PRE", "", mysqlDBPrefix, sizeof(mysqlDBPrefix))!=0)
		{
			return -1;
		}

		if(oIni.GetString(sectorName, "MYSQL_TABLE_NAME_PRE", "", mysqlTablePrefix, sizeof(mysqlTablePrefix))!=0)
		{
			return -1;
		}

		if(oIni.GetInt(sectorName, "MYSQL_DB_MODULUS", 0, &mysqlDBModulus)!=0)
		{
			return -1;
		}

		
		if(oIni.GetInt(sectorName, "MYSQL_TABLE_MODULUS", 0, &mysqlTableModulus)!=0)
		{
			return -1;
		}

		if(oIni.GetInt(sectorName, "MYSQL_KEEPALIVE", 0, &mysqlKeepAlive)!=0)
		{
			return -1;
		}

		if(oIni.GetInt(sectorName, "MYSQL_TIMEOUT", 0, &mysqltimeout)!=0)
		{
			return -1;
		}

		return 0;
	}
};


char g_sqlBuff[MSG_BUFF_LIMIT*2+1024];

int doSelect(const CMysqlConfig& config, int dbIdx, int tableIdx)
{
	MysqlDB theDB;
	char dbnameBuff[256];
	snprintf(dbnameBuff, sizeof(dbnameBuff), "%s_%d", config.mysqlDBPrefix, dbIdx);
	if( theDB.Connect(config.mysqlSvrIP, config.mysqlUser, config.mysqlPassword, dbnameBuff, config.mysqlSvrPort) != 0)
	{
		cout <<  "db Connect fail " << dbnameBuff << endl;
		return -1;
	}

	unsigned long sqlLen = snprintf(g_sqlBuff, sizeof(g_sqlBuff), "select user_name, user_data_0 from %s_%d", 
		config.mysqlTablePrefix, tableIdx);

	MysqlResult result;
	if(theDB.Query(g_sqlBuff, sqlLen, &result) != 0)
	{
		cout <<  "theDB->query: " << theDB.GetErr() << endl;
		return -1;
	}

	//cout << "recordnum:" << result.RowNum() << endl;

	UserData thedata;
	for(int i=0; i< result.RowNum(); ++i)
	{
		char** rcd = result.FetchNext();
		unsigned long fieldlen = 0;
		if(result.FieldLength(1, fieldlen)!=0)
		{
			cout << "FieldLength fail" << endl;
			return -1;
		}

	//	cout << "user= " << rcd[0] << ",fieldlen=" << fieldlen << endl;

		thedata.Clear();
		if(!thedata.ParseFromArray(rcd[1], fieldlen))
		{
			cout << "thedata.ParseFromArray fail" << endl;
			return -1;
		}
		
		cout << rcd[0] << " " << thedata.roleinfo().level() << endl;

	}

	return 0;
}

int main(int argc, char **argv)
{
	if(argc < 2)
	{
		cout << argv[0] << " mysql_helper_ini" <<endl;
		return 0;
	}

	CIniFile oIni(argv[1]);
	if(!oIni.IsValid())
	{
		cout << "read ini " << argv[1] << "fail" << endl;
		return 0;
	}

	//config
	CMysqlConfig config;
	if(config.read_from_ini(oIni, "MYSQL_HELPER")!=0)
	{
		cout << "config.read_from_ini fail" << endl;
		return 0;
	}
	
	//config.debug(cout);

	int dbtotal = config.mysqlDBModulus;
	int tabletotal = config.mysqlTableModulus;

	if(argc > 2)
	{
		dbtotal = atoi(argv[2]);
	}

	if(argc > 3)
	{
		tabletotal = atoi(argv[3]);
	}

	for(int i=0; i<dbtotal; ++i)
	{
		for(int j=0; j<tabletotal; ++j)
		{
			if(doSelect(config, i , j) !=0)
			{
				return 0;
			}
		}
	}

	return 1;
}



