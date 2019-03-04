#include "mysql_proxy.h"
#include <iconv.h>

CMysqlProxy::CMysqlProxy()
{
	mNoEscape = false;
}

CMysqlProxy::~CMysqlProxy()
{
	MysqlDBMap::iterator itDB = mDBMap.begin();
	while( itDB != mDBMap.end() )
	{
		delete itDB->second;
		itDB++;
	}
	mDBMap.clear();

	MysqlTableMap::iterator itTab = mTableMap.begin();
	while( itTab != mTableMap.end() )
	{
		delete itTab->second;
		itTab++;
	}
	mTableMap.clear();
}

int CMysqlProxy::init(CMysqlProxyConfig &config, bool initTable)
{
	mConfig = config;

	return 0;
}

MysqlDB* CMysqlProxy::initDB(const string &dbName)
{
	MysqlDB* theDB;
	if(mConfig.mysqlKeepAlive)
	{
		//找到对应的链接
		theDB = getDB(dbName);
		if( NULL == theDB )
		{
			theDB = new MysqlDB;
			addDB(dbName, theDB);
		}
		if(!theDB->IsConnected())
		{
			theDB->SetEncoding("utf8");
			theDB->SetTimeOut(mConfig.mysqltimeout);
			if(theDB->Connect(mConfig.mysqlSvrIP, mConfig.mysqlUser, mConfig.mysqlPassword, dbName.c_str(), mConfig.mysqlSvrPort, true, mConfig.mysqlSock) != 0)
			{
				LOG(LOG_ERROR, "db Connect fail %s", theDB->GetErr());
				return NULL;
			}
			/*
			std::string useUtf8 = "SET NAMES UTF8;";
			theDB->Query(useUtf8.c_str(), useUtf8.length());
			*/
		}
	}
	else
	{
		theDB = new MysqlDB;
		if(theDB == NULL)
		{
			LOG(LOG_ERROR, "new MysqlDB fail");
			return NULL;
		}
		theDB->SetEncoding("utf8");
		if( theDB->Connect(mConfig.mysqlSvrIP, mConfig.mysqlUser, mConfig.mysqlPassword, dbName.c_str(), mConfig.mysqlSvrPort) != 0)
		{
			LOG(LOG_ERROR, "db Connect fail %s", theDB->GetErr());
			delete theDB;
			return NULL;
		}
		/*
		std::string useUtf8 = "SET NAMES UTF8;";
		theDB->Query(useUtf8.c_str(), useUtf8.length());
		*/
	}

	return theDB;
}

void CMysqlProxy::freeDB(MysqlDB*& theDB)
{
	if(!mConfig.mysqlKeepAlive && theDB)
	{
		delete theDB;
		theDB = NULL;
	}
}

void CMysqlProxy::addDB(const string &dbName, MysqlDB *pDB)
{
	assert(pDB != NULL);
	MysqlDBMap::iterator it = mDBMap.find(dbName);
	if( it != mDBMap.end() )
	{
		return;
	}
	mDBMap.insert(std::make_pair(dbName, pDB));
}

void CMysqlProxy::addTable(CMysqlTableWrapper *pTable)
{
	assert(pTable != NULL);
	MysqlTableMap::iterator it = mTableMap.find(pTable->getTableType());
	if( it != mTableMap.end() )
	{
		return;
	}
	mTableMap.insert(std::make_pair(pTable->getTableType(), pTable));
}

int CMysqlProxy::update(time_t nowTime)
{
	/*
	MysqlTableMap::iterator it = mTableMap.begin();
	while( it != mTableMap.end() )
	{
		CMysqlTableWrapper *pTable = it->second;
		if( pTable->update(nowTime) != 0 )
		{
			LOG(LOG_ERROR, "Table:%d update failed", pTable->getTableType());
		}
		it++;
	}
	*/
	return 0;
}

void CMysqlProxy::setNoEscape(bool flag)
{
	mNoEscape = flag;
}

string CMysqlProxy::getEscapedData(const string &dbName, const string &data)
{
	CMemGuard escapeMem;
	char* escapeData;
	unsigned long escapeDataLen;
	std::string realData;
	MysqlDB* theDB = NULL;
	while(true) //释放方便
	{
		//处理请求
		theDB = initDB(dbName);
		if(theDB == NULL)
		{
			LOG(LOG_ERROR, "initDB failed, dbName:%s", dbName.c_str());
			break;
		}

		theDB->Escape(data.data(), data.length(), escapeData, escapeDataLen);
		escapeMem.add(escapeData);
		realData.assign(escapeData, escapeDataLen);
		break;
	}
	freeDB(theDB);
	return realData;
}

MysqlDB *CMysqlProxy::getDB(const string &dbName)
{
	MysqlDBMap::iterator it = mDBMap.find(dbName);
	if( it == mDBMap.end() )
	{
		return NULL;
	}
	return it->second;
}

CMysqlTableWrapper *CMysqlProxy::getTable(TableType type)
{
	MysqlTableMap::iterator it = mTableMap.find(type);
	if( it == mTableMap.end() )
	{
		return NULL;
	}
	return it->second;
}

int CMysqlProxy::query(const string &dbName, const string &sql, MysqlResult &result)
{
	MysqlDB* theDB = NULL;
	bool hasError = false;
	while(true) //释放方便
	{
		//处理请求
		theDB = initDB(dbName);
		if(theDB == NULL)
		{
			LOG(LOG_ERROR, "initDB failed, dbName:%s", dbName.c_str());
			return -1;
		}

		CMemGuard escapeMem;
		char* escapeSql;
		unsigned long escapeSqlLen;

		const char* data = sql.c_str();
		unsigned long dataLen = sql.length();

		std::string realSql;
		if( !mNoEscape )
		{
			theDB->Escape(data, dataLen, escapeSql, escapeSqlLen);
			escapeMem.add(escapeSql);
			realSql.assign(escapeSql, escapeSqlLen);
		}
		else
		{
			realSql = sql;
		}

		if( !mNoEscape )
		{
			strutil::replaceAll(realSql, "\\'", "'");
		}

		if(gDebugFlag)
			LOG(LOG_DEBUG, "mNoEscape:%d, sql:%s, realSql:%s", mNoEscape, data, realSql.c_str());
	
		int affectedRows;
		MysqlResult *pMysqlResult = NULL;
		if( sql.find("select") != sql.npos|| sql.find("SELECT") != sql.npos )
		{
			pMysqlResult = &result;
		}
		START_QUERY_TIME
			if(theDB->Query(realSql.c_str(), realSql.length(), pMysqlResult, &affectedRows) != 0)
			{
				LOG(LOG_ERROR, "theDB->query: %s", theDB->GetErr());
				hasError = true;
				break;
			}
		END_QUERY_TIME
		if(m_interval > SLOW_MS)
		{
			LOG(LOG_ERROR, "QUERY|SLOW|%d", m_interval);
		}
		result.SetAffectRowNum(affectedRows);

		if(gDebugFlag)
			LOG(LOG_DEBUG, "query ok| row=%d", result.RowNum());
		break;
	}
	//处理完，非长链释放
	freeDB(theDB);
	if( hasError )
	{
		return -1;
	}
	return 0;
}

string CMysqlProxy::parseMysqlString(const string &mysqlStr)
{
	string utf8Str;
	gbk_utf8(mysqlStr, utf8Str);
	return utf8Str;
}

string CMysqlProxy::toMysqlString(const string &stdStr)
{
	//utf-8 转 gbk
	string gbk8Str = stdStr;
	utf8_gbk(gbk8Str);
	return gbk8Str;
}

time_t CMysqlProxy::parseMysqlDateTime(const string &mysqlTime)
{
	return CTimeUtil::FromTimeString(mysqlTime.c_str());
}

string CMysqlProxy::toMysqlDateTime(time_t time)
{
	return CTimeUtil::TimeString(time);
}

int CMysqlProxy::parseMysqlInt(const string &valueStr)
{
	int value;
	std::istringstream iss(valueStr);
	iss >> value;
	return value;
}

string CMysqlProxy::toMysqlInt(int value)
{
	stringstream os;
	os << value;
	return os.str();
}

CMysqlProxy::int64 CMysqlProxy::parseMysqlBigInt(const string &mysqlBigInt)
{
	int64 value;
	std::istringstream iss(mysqlBigInt);
	iss >> value;
	return value;
}

string CMysqlProxy::toMysqlBigInt(int64 value)
{
	stringstream os;
	os << value;
	return os.str();
}

int CMysqlProxy::codeConvert(const char* from_charset,const char* to_charset, const char* inbuf, size_t inleft, char* outbuf, size_t& outleft)
{
	char** pin = const_cast<char**>(&inbuf);
	char** pout = &outbuf;
	iconv_t cd = iconv_open(to_charset, from_charset);
	if (cd == 0)
		return -1;

	while (true)
	{
		int ret = iconv(cd, pin, &inleft, pout, &outleft);
		if (ret < 0)
		{
			return -1;
		}

		break;
	}

	iconv_close(cd);
	return 0;
}


int CMysqlProxy::gbk_utf8(const string& gbkStr, string& utf8Str)
{
	const char* inbuf = gbkStr.c_str();
	size_t inleft = gbkStr.length();
	char outbuf[4096];
	size_t outleft = sizeof(outbuf)-1;

	if( codeConvert("gbk", "utf-8",inbuf,inleft,outbuf,outleft) != 0)
	{
		return -1;
	}

	outbuf[sizeof(outbuf)-outleft-1] = 0;
	utf8Str = outbuf;

	return 0;
}

int CMysqlProxy::utf8_gbk(string& str)
{
	const char* inbuf = str.c_str();
	size_t inleft = str.length();
	char outbuf[4096];
	size_t outleft = sizeof(outbuf)-1;

	
	if( codeConvert("utf-8", "gbk",inbuf,inleft,outbuf,outleft) != 0)
	{
		return -1;
	}

	outbuf[sizeof(outbuf)-outleft-1] = 0;

	//LOG(LOG_ERROR, "inbuf:%s outbuff:%s", inbuf, outbuf);

	str = outbuf;

	return 0;
}

