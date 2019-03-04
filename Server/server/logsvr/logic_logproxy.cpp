#include "logic_logproxy.h"
#include "mysql_proxy.h"
#include "StringHelper.h"

extern CMysqlProxy gMysqlProxy;

char CLogicLogProxy::sBuff[LOG_STR_BUFF_SIZE] = {};
const char *CLogicLogProxy::sDBName = "db_star_log";
void CLogicLogProxy::on_init()
{

}

int CLogicLogProxy::on_active(CLogicMsg& msg)
{
	if(gDebugFlag)
	{
		LOG(LOG_INFO, "CLogicLogProxy[%u] recv cmd[0x%x]", m_id, m_ptoolkit->get_cmd(msg));
	}

	char *data = msg.body();
	unsigned int size = msg.head()->bodySize;
	std::string orgStr(data, size);
	StringVector strVec;
	StringHelper::splitStringIntoVec(strVec, orgStr, "|");
	
	unsigned len = sizeof(sBuff);
	if( StringHelper::toSql(strVec, sBuff, len) != 0 )
	{
		return RET_DONE;
	}
	std::string sqlStr(sBuff, len);
	if( sqlStr.empty() )
	{
		//LOG(LOG_ERROR, "sqlstr is empty, orgStr:%s", orgStr.c_str());
		return RET_DONE;
	}
	//LOG(LOG_DEBUG, "orgStr:%s, sqlStr:%s", orgStr.c_str(), sqlStr.c_str());
	
	//sqlStr = gMysqlProxy.toMysqlString(sqlStr);
	MysqlResult result;
	if( gMysqlProxy.query(sDBName, sqlStr, result) != 0 )
	{
		LOG(LOG_ERROR, "query sDBName:%s, sqlStr:%s failed.", sDBName, sqlStr.c_str());
	}
	else
	{
		//int rowNum = result.GetAffectRowNum();
		//LOG(LOG_DEBUG, "query success rowNum:%d sDBName:%s, sqlStr:%s", rowNum, sDBName, sqlStr.c_str());
	}

	return RET_DONE;
}

//对象销毁前调用一次
void CLogicLogProxy::on_finish()
{
}

CLogicProcessor* CLogicLogProxy::create()
{
	return new CLogicLogProxy;
}
