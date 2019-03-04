#include "data_cache/data_cache_api.h"
#include <iostream>
#include <string.h>
#include <sstream>
#include "ini/ini_file.h"
#include "log/log.h"
#include "lock/lock_sem.h"
#include "logic/msg_queue.h"
#include "logic/toolkit.h"
#include "mysql_wrap/mysql_wrap.h"
#include "process_manager/process_manager.h"
#include "common/msg_define.h"
#include "common/server_tool.h"
#include "common/sleep_control.h"
#include "common/user_distribute.h"
#include "common/mem_guard.h"
#include "common/speed_control.h"
#include <sys/time.h>
#include "proto/inner_cmd.pb.h"

using namespace std;
/*
* mysql helper负责多进程读写mysql
* 每个mysql helper维护一个mysql链接
*/

int gstopflag = 0;
int gDebug=0;

class CMysqlHelperConfig
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
	//合服机制:合服之前每个sid对应一个db。合服之后就是对应几个db
	int sid_num;
	int sid_list[128];//应对合服，128个足够了吧

	CMysqlHelperConfig()
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
			LOG(LOG_ERROR, "read ini %s fail", file);
			return -1;
		}

		return read_from_ini(oIni, sectorName);
	}
	
	int read_from_ini(CIniFile& oIni, const char* sectorName)
	{
		if(oIni.GetInt(sectorName, "PROC_NUM", 0, &procNum)!=0)
		{
			LOG(LOG_ERROR, "%s.PROC_NUM not found", sectorName);
			return -1;
		}

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

		if(oIni.GetInt(sectorName, "GLOBE_QUEUE_ID", 0, &queueID)!=0)
		{
			LOG(LOG_ERROR, "%s.GLOBE_QUEUE_ID not found", sectorName);
			return -1;
		}

		if(oIni.GetString(sectorName, "MYSQL_SOCK", "", mysqlSock, sizeof(mysqlSock))!=0)
		{
			LOG(LOG_ERROR, "%s.MYSQL_SOCK not found", sectorName);
			return -1;
		}

		if(oIni.GetString(sectorName, "MYSQL_DB_NAME_PRE", "", mysqlDBPrefix, sizeof(mysqlDBPrefix))!=0)
		{
			LOG(LOG_ERROR, "%s.MYSQL_DB_NAME_PRE not found", sectorName);
			return -1;
		}

		if(oIni.GetString(sectorName, "MYSQL_TABLE_NAME_PRE", "", mysqlTablePrefix, sizeof(mysqlTablePrefix))!=0)
		{
			LOG(LOG_ERROR, "%s.MYSQL_TABLE_NAME_PRE not found", sectorName);
			return -1;
		}

		if(oIni.GetInt(sectorName, "MYSQL_DB_MODULUS", 0, &mysqlDBModulus)!=0)
		{
			LOG(LOG_ERROR, "%s.MYSQL_DB_MODULUS not found", sectorName);
			return -1;
		}

		/*
		if(oIni.GetInt(sectorName, "MYSQL_DB_START_IDX", 0, &mysqlDBStartIdx)!=0)
		{
			LOG(LOG_ERROR, "%s.MYSQL_DB_START_IDX not found", sectorName);
			return -1;
		}
		if(oIni.GetInt(sectorName, "MYSQL_DB_END_IDX", 0, &mysqlDBEndIdx)!=0)
		{
			LOG(LOG_ERROR, "%s.MYSQL_DB_END_IDX not found", sectorName);
			return -1;
		}
		*/
		
		if(oIni.GetInt(sectorName, "MYSQL_TABLE_MODULUS", 0, &mysqlTableModulus)!=0)
		{
			LOG(LOG_ERROR, "%s.MYSQL_TABLE_MODULUS not found", sectorName);
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

		if(oIni.GetInt(sectorName, "SID_NUM", 0, &sid_num)!=0)
		{
			LOG(LOG_ERROR, "%s.SID_NUM not found", sectorName);
			return -1;
		}
		char tag[32];
		for(int i = 1; i <= sid_num; ++i)
		{
			snprintf(tag, sizeof(tag), "SID_%d", i);
			if(oIni.GetInt(sectorName, tag, 0, &(sid_list[i - 1]))!=0)
			{
				LOG(LOG_ERROR, "%s.SID_%d not found", sectorName, i);
				return -1;
			}
		}

		return 0;
	}
};

struct ACTIVITY_REWARD_RESULT {
	int Result; //结果，=0表示获得奖励成功，<0出错，=-1表示没有资格，=-2表示已经领取奖励
	int TotalScore; //总积分（充值返利中为充值获得的总元宝数）
	int SubScore1;	//子积分（充值返利中为充值获得的真元宝数）
	ACTIVITY_REWARD_RESULT()
	{
		Result = -1;
		TotalScore = 0;
		SubScore1 = 0;
	}
};

CMysqlHelperConfig g_cdkey_mysql;

class CMysqlHelperProcess
{
	//必须配套使用
	#define START_QUERY_TIME gettimeofday(&start_t, NULL);
	#define END_QUERY_TIME gettimeofday(&end_t, NULL); \
		m_interval = (end_t.tv_sec - start_t.tv_sec)*1000 + (end_t.tv_usec - start_t.tv_usec)/1000;
		
	public:
		CMysqlHelperProcess()
		{
			m_DBidxStart = 0;
			m_DBidxEnd = 0;
			mCDKeyDB = NULL;
		}

		~CMysqlHelperProcess()
		{
			for(map<int, MysqlDB *>::iterator it = m_theDBPool.begin(); it != m_theDBPool.end(); it++)
			{
				if(it->second != NULL)
				{
					delete it->second;
					it->second = NULL;
				}
			}
			if( mCDKeyDB != NULL )
			{
				delete mCDKeyDB;
				mCDKeyDB = NULL;
			}
		}

		int on_get(USER_NAME& user, CMysqlHelperConfig& config, CDataBlockSet& theSet, int sid, int tableType=0)
		{
			MysqlDB* theDB = NULL;
			while(true) //释放方便
			{
				//处理请求
				theDB = initDB(config,user, sid);
				if(theDB == NULL)
				{
					theSet.save_only_result(true);
					break;
				}

				int tableIdx = CUserDistribute::table(user,config.mysqlDBModulus,config.mysqlTableModulus);
				CMemGuard escapeMemName;
				char* escapeData;
				unsigned long escapeDataLen;
				const char* data = user.str();
				unsigned long dataLen = strlen(data);
				theDB->Escape(data, dataLen, escapeData, escapeDataLen);
				escapeMemName.add(escapeData);

				//make sql
				int it = theSet.begin();
				int blockId;
				DataBlock * pBlock;
				bool errerbreak = false;
				bool first = true;
				ostringstream os;
				// 处理数据列
				while(theSet.fetch_block(it, blockId, pBlock))
				{
					if(!pBlock)
					{
						errerbreak = true;
						break;
					}

					if(first)
						first = false;
					else
						os << ",";
					os << "user_data_" << blockId;
				}

				if(errerbreak)
				{
					theSet.save_only_result(  true);
					break;
				}

				unsigned long sqlLen;
				if(tableType == 0)
				{
					sqlLen = snprintf(m_sqlBuff, sizeof(m_sqlBuff), "select %s from %s_%d where user_name=BINARY'%s';", 
						os.str().c_str(), 	config.mysqlTablePrefix, tableIdx, escapeData);
				}
				else
				{
					sqlLen = snprintf(m_sqlBuff, sizeof(m_sqlBuff), "select %s from tab_star_group_%d where user_name=BINARY'%s';", 
						os.str().c_str(), 	tableIdx,  escapeData);
				}

				if(gDebug)
					LOG(LOG_DEBUG, "%s", m_sqlBuff);
				
				MysqlResult result;
				START_QUERY_TIME
				if(theDB->Query(m_sqlBuff, sqlLen, &result) != 0)
				{
					LOG(LOG_ERROR, "theDB->query: %s", theDB->GetErr());
					theSet.save_only_result(  true);
					break;
				}
				END_QUERY_TIME
				if(m_interval > SLOW_MS)
				{
					LOG(LOG_ERROR, "%s|GET|SLOW|%d", user.str(), m_interval);
				}


				if(gDebug)
					LOG(LOG_DEBUG, "query ok| row=%d", result.RowNum());

				if(result.RowNum() == 0)
				{
					theSet.set_result(DataBlockSet::NO_DATA);
					theSet.save_only_result();
					break;
				}

				char** rcd = result.FetchNext();
				errerbreak = false;
				first = true;
				it = theSet.begin();
				int i=0;
				char* vol;
				unsigned long * lengthArray;
				int lengthNum; 
				result.FieldLengthArray(lengthArray, lengthNum);
				while(theSet.fetch_block(it, blockId, pBlock))
				{
					if(!pBlock)
					{
						errerbreak = true;
						break;
					}

					if(i>=lengthNum)
					{
						//shit
						LOG(LOG_ERROR, "FieldLengthArray lengthNum not right");
						errerbreak = true;
						break;
					}

					vol = rcd[i];
					if(vol)
						pBlock->mutable_buff()->assign(vol, lengthArray[i]);
					else
						*(pBlock->mutable_buff()) = "";
							
					++i;
				}

				if(errerbreak)
				{
					theSet.save_only_result(  true);
				}
				else
				{
					theSet.set_result(DataBlockSet::OK);
				}
				
				break;
			}
			
			//处理完，非长链释放
			freeDB(config, theDB);
			return 0;
		}

		int on_set(USER_NAME& user, CMysqlHelperConfig& config, CDataBlockSet& theSet, int sid, int tableType = 0)
		{
			MysqlDB* theDB = NULL;
			while(true) //释放方便
			{
				//处理请求
				theDB = initDB(config, user, sid);
				if(theDB == NULL)
				{
					theSet.save_only_result(  true);
					break;
				}
				
				int tableIdx = CUserDistribute::table(user, config.mysqlDBModulus, config.mysqlTableModulus);
				
				CMemGuard escapeMem;
				char* escapeData;
				unsigned long escapeDataLen;
				char* escapeName;
				unsigned long escapeNameLen;
				
				const char* data = user.str();
				unsigned long dataLen = strlen(data);
				theDB->Escape(data, dataLen, escapeName, escapeNameLen);
				escapeMem.add(escapeName);

				int it = theSet.begin();
				int blockId;
				DataBlock * pBlock;
				bool errerbreak = false;
				bool first = true;


				//组sql
				unsigned long sqlLen = 0;
				if(tableType == 0)
				{
					sqlLen = snprintf(m_sqlBuff, sizeof(m_sqlBuff), "update %s_%d set ", 
						config.mysqlTablePrefix, tableIdx);
				}
				else 
				{
					sqlLen = snprintf(m_sqlBuff, sizeof(m_sqlBuff), "update tab_star_group_%d set ", 
						tableIdx);
				}


				//填充val
				errerbreak = false;
				first = true;
				it = theSet.begin();
				char namebuff[64] = {0};
				while(theSet.fetch_block(it, blockId, pBlock))
				{
					if(!pBlock)
					{
						errerbreak = true;
						break;
					}
					
					const char* data = pBlock->buff().data();
					unsigned long dataLen = pBlock->buff().size();
					theDB->Escape(data, dataLen, escapeData, escapeDataLen);
					escapeMem.add(escapeData);

					if(first)
						first = false;
					else
					{
						if(add_sql_str(sqlLen, ",") != 0)
						{
							errerbreak = true;
							break;
						}
					}

					snprintf(namebuff, sizeof(namebuff), "user_data_%d = '", blockId);
					if(add_sql_str(sqlLen, namebuff) != 0)
					{
						errerbreak = true;
						break;
					}

					if(add_sql_val(sqlLen, escapeData, escapeDataLen)!=0)
					{
						errerbreak = true;
						break;
					}

					if(add_sql_str(sqlLen, "'")!=0)
					{
						errerbreak = true;
						break;
					}
				}
				
				if(errerbreak)
				{
					theSet.save_only_result(  true);
					break;
				}

				if(first)
				{
					LOG(LOG_ERROR, "update req has no data");
					break;
				}

				if(add_sql_str(sqlLen, " where user_name=BINARY'")!=0)
				{
					theSet.save_only_result(  true);
					break;
				}

				if(add_sql_val(sqlLen, escapeName, escapeNameLen) != 0)
				{
					theSet.save_only_result(  true);
					break;
				}
				
				if(add_sql_str(sqlLen, "';")!=0)
				{
					theSet.save_only_result(  true);
					break;
				}

				m_sqlBuff[sqlLen] = 0;
				if(gDebug)
					LOG(LOG_DEBUG, "%s", m_sqlBuff);

				int affectedRows = 0;
				START_QUERY_TIME
				int ret = theDB->Query(m_sqlBuff, sqlLen, NULL, &affectedRows);
				if(ret != 0)
				{
					LOG(LOG_ERROR, "theDB->update: %s", theDB->GetErr());
					if(ret == -2)
					{
						LOG(LOG_INFO, "%s|create|has data", user.str());
					}

					theSet.save_only_result(  true);
					break;
				}
				END_QUERY_TIME
				if(m_interval > SLOW_MS)
				{
					LOG(LOG_ERROR, "%s|UPDATE|SLOW|%d", user.str(), m_interval);
				}

				//replace的affectedRows=删除和插入的总和，affectedRows=1是新插入，>1是删除之后有插入
				if(gDebug)
					LOG(LOG_DEBUG, "update(user,affacted,dataLen)|%s|%d|%lu", user.str(), affectedRows, dataLen);

				theSet.set_result(DataBlockSet::OK);
				theSet.save_only_result();
				break;
			}

			//处理完，非长链释放
			freeDB(config, theDB);
			
			return 0;
		}

		int on_insert(USER_NAME& user, CMysqlHelperConfig& config, CDataBlockSet& theSet, int sid, int tableType=0)
		{
			MysqlDB* theDB = NULL;
			while(true) //释放方便
			{
				//处理请求
				theDB = initDB(config, user, sid);
				if(theDB == NULL)
				{
					theSet.save_only_result(  true);
					break;
				}
				
				int tableIdx = CUserDistribute::table(user, config.mysqlDBModulus, config.mysqlTableModulus);
				
				CMemGuard escapeMem;
				char* escapeData;
				unsigned long escapeDataLen;
				char* escapeName;
				unsigned long escapeNameLen;

				const char* data = user.str();
				unsigned long dataLen = strlen(data);
				theDB->Escape(data, dataLen, escapeName, escapeNameLen);
				escapeMem.add(escapeName);

				
				int it = theSet.begin();
				int blockId;
				DataBlock * pBlock;
				bool errerbreak = false;
				bool first = true;
				ostringstream osname;
				while(theSet.fetch_block(it, blockId, pBlock))
				{
					if(!pBlock)
					{
						errerbreak = true;
						break;
					}

					if(first)
						first = false;
					else
					{
						osname << ",";
					}

					osname << "user_data_" << blockId;
				}
				if(errerbreak)
				{
					theSet.save_only_result(  true);
					break;
				}

				//组sql
				unsigned long sqlLen;
				if(tableType == 0)
				{
					sqlLen = snprintf(m_sqlBuff, sizeof(m_sqlBuff), "insert into %s_%d(user_name, %s) values(BINARY'%s', '", 
						config.mysqlTablePrefix, tableIdx, osname.str().c_str(), escapeName);
				}
				else
				{
					sqlLen = snprintf(m_sqlBuff, sizeof(m_sqlBuff), "insert into tab_star_group_%d(user_name, %s) values(BINARY'%s', '", 
						tableIdx,  osname.str().c_str(), escapeName);
				}

				//填充val
				errerbreak = false;
				first = true;
				it = theSet.begin();
				while(theSet.fetch_block(it, blockId, pBlock))
				{
					if(!pBlock)
					{
						errerbreak = true;
						break;
					}
					const char* data = pBlock->buff().data();
					unsigned long dataLen = pBlock->buff().size();
					theDB->Escape(data, dataLen, escapeData, escapeDataLen);
					escapeMem.add(escapeData);
					if(first)
						first = false;
					else
					{
						if(add_sql_str(sqlLen, "','") != 0)
						{
							errerbreak = true;
							break;
						}
					}

					if(add_sql_val(sqlLen, escapeData, escapeDataLen) != 0)
					{
						errerbreak = true;
						break;
					}
				}
				if(errerbreak)
				{
					theSet.save_only_result(  true);
					break;
				}

				if(add_sql_str(sqlLen, "');") != 0)
				{
					theSet.save_only_result(  true);
					break;
				}
				
				if(gDebug)
					LOG(LOG_DEBUG, "%s", m_sqlBuff);

				int affectedRows = 0;
				START_QUERY_TIME
				int ret = theDB->Query(m_sqlBuff, sqlLen, NULL, &affectedRows);
				if(ret != 0)
				{
					LOG(LOG_ERROR, "theDB->insert: %s", theDB->GetErr());
					if(ret == -2)
					{
						LOG(LOG_INFO, "%s|create|has data", user.str());
					}

					theSet.save_only_result(  true);
					break;
				}
				END_QUERY_TIME
				if(m_interval > SLOW_MS)
				{
					LOG(LOG_ERROR, "%s|INSERT|SLOW|%d", user.str(), m_interval);
				}

				//replace的affectedRows=删除和插入的总和，affectedRows=1是新插入，>1是删除之后有插入
				if(gDebug)
					LOG(LOG_DEBUG, "insert(user,affacted,dataLen)|%s|%d|%lu", user.str(), affectedRows, dataLen);

				theSet.set_result(DataBlockSet::OK);
				theSet.save_only_result();
				break;
			}
			
			//处理完，非长链释放
			freeDB(config, theDB);

			return 0;
		}
		
		int run(CMysqlHelperConfig& config, CMsgQueuePipe& theQueue)
		{
			totalcnt = 0;
			readcnt = 0;
			writecnt = 0;
			readlimited = 0;
			writelimited = 0;
		
			if(config.mysqlKeepAlive)
			{
				//初始化链接池
				for(int i = 0; i < config.sid_num; i++)
				{
					map<int, MysqlDB *>::iterator it = m_theDBPool.find(config.sid_list[i]);
					if(it != m_theDBPool.end())
					{
						LOG(LOG_ERROR, "create MysqlDB %d fail, repeated", config.sid_list[i]);
						return -1;
					}
					MysqlDB *temp = new MysqlDB;
					if(temp == NULL)
					{
						LOG(LOG_ERROR, "new MysqlDB[%d] fail", config.sid_list[i]);
						return -1;
					}
					pair<map<int, MysqlDB *>::iterator, bool> ret = m_theDBPool.insert(pair<int, MysqlDB *>(config.sid_list[i], temp));
					if(!ret.second)
					{
						LOG(LOG_ERROR, "insert MysqlDB[%d] fail", config.sid_list[i]);
						return -1;
					}
				}
			}

			CLogicMsg reqMsg(m_toolkit.readBuff, sizeof(m_toolkit.readBuff));
			CSleepControl theSleep;
			theSleep.setparam(1000,1000, 1000);
			CSpeedControl theReadSpeed;
			theReadSpeed.set(1000,config.readLimitPerSecond);
			CSpeedControl theWriteSpeed;
			theWriteSpeed.set(1000,config.writeLimitPerSecond);

			while(!gstopflag)
			{
				theSleep.sleep();
				//从通道中读请求
				int ret = theQueue.get_msg(reqMsg);
				if(ret == theQueue.EMPTY)
				{
					continue;
				}
				else if(ret != theQueue.OK)
				{
					theSleep.delay();
					continue;
				}

				unsigned int cmd = m_toolkit.get_cmd(reqMsg);
				if(gDebug)
				{
					LOG(LOG_DEBUG, "recv cmd 0x%x", cmd);
				}

				if(cmd == CMD_CDKEY_INNER_REQ)
				{
					USER_NAME user;
					InnerCDKEYReq req;
					if(m_toolkit.parse_protobuf_msg(gDebug, reqMsg, user, req)!=0)
					{
						LOG(LOG_ERROR, "parse innercdkey err");
						continue; 
					}

					int ret = on_use_cdkey(user,g_cdkey_mysql,req.cdkey());
					InnerCDKEYResp resp;
					if(ret > 0)
						resp.set_ret(ret);
					else if(ret == -1)
						resp.set_ret(-4);
					else if(ret == -2)
						resp.set_ret(-2);
					else if(ret == -3)
						resp.set_ret(-5);
					else
						resp.set_ret(-1);
					ret = m_toolkit.send_protobuf_msg(gDebug, resp, 
						CMD_CDKEY_INNER_RESP, user, &theQueue, 
						m_toolkit.get_src_server(reqMsg),m_toolkit.get_src_handle(reqMsg)
					);
					if(ret != 0)
					{
						LOG(LOG_ERROR, "send_msg CMD_CDKEY_INNER_RESP fail");
					}
					continue;
				}
				else if(cmd == CMD_QUERY_BEFORE_REGIST_REQ)
				{
					USER_NAME user;
					InnerQueryBeforeRegReq req;
					if(m_toolkit.parse_protobuf_msg(gDebug, reqMsg, user, req)!=0)
					{
						LOG(LOG_ERROR, "parse innercdkey err");
						continue; 
					}
					ACTIVITY_REWARD_RESULT reward;
					int ret = on_get_activity_reward(user,g_cdkey_mysql,req.account(),req.act_id(),reward);
					LOG(LOG_DEBUG, "on_get_activity_reward ret = %d, %d", ret, reward.Result);
					InnerQueryBeforeReqResp resp;
					resp.set_result(-1);
					if(reward.Result == 0)
					{
						resp.set_result(1);
						resp.set_real_money(reward.SubScore1);
						resp.set_money(reward.TotalScore - reward.SubScore1);
						resp.set_vip(reward.SubScore1);
						resp.set_czfl(reward.SubScore1);
					}
					else if(reward.Result == -1 || reward.Result == -2)
					{
						resp.set_result(0);
					}
					else
					{
						resp.set_result(-1);
					}

					ret = m_toolkit.send_protobuf_msg(gDebug, resp, 
						CMD_QUERY_BEFORE_REGIST_RESP, user, &theQueue, 
						m_toolkit.get_src_server(reqMsg),m_toolkit.get_src_handle(reqMsg)
					);
					if(ret != 0)
					{
						LOG(LOG_ERROR, "send_msg CMD_QUERY_BEFORE_REGIST_RESP fail");
					}
					continue;
				}
				CDataBlockSet theSet;
				USER_NAME inner_name;
				if(m_toolkit.parse_protobuf_msg(gDebug, reqMsg, inner_name, theSet.get_obj())!=0)
				{
					theSleep.delay();
					continue; 
				}
				char t_name[USER_NAME_BUFF_LEN] = {0};		
				inner_name.str(t_name);
				size_t name_len = strlen(t_name);
				if(name_len <= 5)
				{
					LOG(LOG_ERROR, "UserName len less 5,%s", t_name);
					continue;
				}
				char *c_sid = t_name + (name_len - 5);
				int sid = atoi(c_sid);
				*c_sid = 0;
				USER_NAME real_name;
				real_name.from_str(t_name);
				
				if(gDebug)
				{
					LOG(LOG_DEBUG, "UserName %s, sid %d", real_name.str(), sid);
				}

				//收到正确的包了
				theSleep.cancel_delay();

				if(++totalcnt%1000 == 0)
				{
					LOG(LOG_INFO, "totalcnt=%lu readcnt=%lu writecnt=%lu readlimited=%lu writelimited=%lu", 
						totalcnt, readcnt, writecnt, readlimited, writelimited);
				}

				
				unsigned int cmdback;
				int tableType;
				
				if(cmd == CMD_DBCACHE_GET_REQ || cmd == CMD_DBCACHE_GET_USERGROUP_REQ)
				{
					if(cmd == CMD_DBCACHE_GET_REQ)
					{
						cmdback = CMD_DBCACHE_GET_RESP;
						tableType = 0;
					}
					else
					{
						cmdback = CMD_DBCACHE_GET_USERGROUP_RESP;
						tableType = 1;
					}
					
					if(!theReadSpeed.checkLimit())
					{
						LOG(LOG_ERROR, "read limit to %d/s", config.readLimitPerSecond);
						theSet.save_only_result(true);
						readlimited++;
					}
					else
					{
						readcnt++;
						on_get(real_name,config, theSet, sid, tableType);
					}

					ret = m_toolkit.send_protobuf_msg(gDebug, theSet.get_obj(), 
						cmdback, inner_name, &theQueue, 
						m_toolkit.get_src_server(reqMsg),m_toolkit.get_src_handle(reqMsg)
					);
					if(ret != 0)
					{
						LOG(LOG_ERROR, "send_msg(%u) fail", cmdback);
					}

				}
				else if(cmd == CMD_DBCACHE_SET_REQ || cmd == CMD_DBCACHE_SET_USERGROUP_REQ)
				{
					bool noresp = theSet.get_obj().has_noresp();

					if(cmd == CMD_DBCACHE_SET_REQ)
					{
						cmdback = CMD_DBCACHE_SET_RESP;
						tableType = 0;
					}
					else
					{
						cmdback = CMD_DBCACHE_SET_USERGROUP_RESP;
						tableType = 1;
					}

					if(!theWriteSpeed.checkLimit())
					{
						LOG(LOG_ERROR, "write limit to %d/s", config.writeLimitPerSecond);
						theSet.save_only_result(true);
						writelimited++;
					}
					else
					{
						writecnt++;
						on_set(real_name, config, theSet, sid, tableType);
					}

					if(!noresp)
					{
						ret = m_toolkit.send_protobuf_msg(gDebug, theSet.get_obj(), 
							cmdback, inner_name, &theQueue, 
							m_toolkit.get_src_server(reqMsg),m_toolkit.get_src_handle(reqMsg)
						);
						if(ret != 0)
						{
							LOG(LOG_ERROR, "send_msg(%u) fail", cmdback);
						}
					}
				}
				else if(cmd == CMD_DBCACHE_CREATE_REQ || cmd == CMD_DBCACHE_CREATE_USERGROUP_REQ)
				{
					if(cmd == CMD_DBCACHE_CREATE_REQ)
					{
						cmdback = CMD_DBCACHE_CREATE_RESP;
						tableType = 0;
					}
					else
					{
						cmdback = CMD_DBCACHE_CREATE_USERGROUP_RESP;
						tableType = 1;
					}
					if(!theWriteSpeed.checkLimit())
					{
						LOG(LOG_ERROR, "write limit to %d/s", config.writeLimitPerSecond);
						theSet.save_only_result(true);
						writelimited++;
					}
					else
					{
						writecnt++;
						on_insert(real_name, config, theSet, sid, tableType);
					}

					ret = m_toolkit.send_protobuf_msg(gDebug, theSet.get_obj(), 
						cmdback, inner_name, &theQueue, 
						m_toolkit.get_src_server(reqMsg),m_toolkit.get_src_handle(reqMsg)
					);
					if(ret != 0)
					{
						LOG(LOG_ERROR, "send_msg(%u) fail", cmdback);
					}
				}
				else
				{
					LOG(LOG_ERROR, "unexpected cmd=%u", m_toolkit.get_cmd(reqMsg));
					continue;
				}
				
				theSleep.work(1);
			}
			return 0;
		}

		//return 0=内部错误， >0返回奖励ID， <0错误编码（-1=CDKEY无效，-2=CDKEY被别人用了，-3=CDKEY被自己用了）
		int on_use_cdkey(USER_NAME& user, CMysqlHelperConfig& config, const std::string &cdkey)
		{
			MysqlDB* theDB = NULL;
			int retVal = 0;
			while(true) //释放方便
			{
				//处理请求
				theDB = initCDKeyDB(config);
				if(theDB == NULL)
				{
					LOG(LOG_ERROR, "initCDKeyDB failed");
					break;
				}
				CMemGuard escapeMemName;
				char* escapeUser;
				char* escapeCDKey;
				unsigned long escapeDataLen;
				const char* data = user.str();
				unsigned long dataLen = strlen(data);
				theDB->Escape(data, dataLen, escapeUser, escapeDataLen);
				escapeMemName.add(escapeUser);

				data = cdkey.c_str();
				dataLen = strlen(data);
				theDB->Escape(data, dataLen, escapeCDKey, escapeDataLen);
				escapeMemName.add(escapeCDKey);

				//make sql
	#define CDKEY_FUNCTION "func_use_cdkey"

				unsigned long sqlLen = snprintf(m_sqlBuff, sizeof(m_sqlBuff), "select %s('%s', '%s');", 
					CDKEY_FUNCTION, escapeCDKey, escapeUser);

				if(gDebug)
					LOG(LOG_DEBUG, "%s", m_sqlBuff);

				MysqlResult result;
				START_QUERY_TIME;
				if(theDB->Query(m_sqlBuff, sqlLen, &result) != 0)
				{
					LOG(LOG_ERROR, "theDB->query: %s", theDB->GetErr());
					break;
				}
				END_QUERY_TIME;
				if(m_interval > SLOW_MS)
				{
					LOG(LOG_ERROR, "%s|GET|SLOW|%d", user.str(), m_interval);
				}

				int rowNum = result.RowNum();
				if( rowNum != 1)
				{
					LOG(LOG_ERROR, "fetch row failed, row:%d != 1", rowNum);
					break;
				}
				char** rcd = result.FetchNext();
				if( NULL == rcd )
				{
					LOG(LOG_ERROR, "NULL == rcd");
					break;
				}
				int fieldNum = result.FieldNum();
				if( fieldNum != 1 )
				{
					LOG(LOG_ERROR, "fetch row failed, fieldNum:%d != 1", fieldNum);
					break;
				}
				char *pData = rcd[0];
				
				std::istringstream iss(pData);
				iss >> retVal;
				break;
			}
			//处理完，非长链释放
			freeDB(config, theDB);
			return retVal;
		}

		//return 0=内部错误， >0返回奖励ID， <0错误编码（-1=CDKEY无效，-2=CDKEY被别人用了，-3=CDKEY被自己用了）
		//参数。USERID, MYSQL CONFIG, ACC（玩家账号）, 活动ID
		int on_get_activity_reward(USER_NAME& user, CMysqlHelperConfig& config, const std::string &acc, int actID, ACTIVITY_REWARD_RESULT &rewardRet)
		{
			MysqlDB* theDB = NULL;
			while(true) //释放方便
			{
				//处理请求
				theDB = initCDKeyDB(config);
				if(theDB == NULL)
				{
					LOG(LOG_ERROR, "initCDKeyDB failed");
					break;
				}
				CMemGuard escapeMemName;
				char* escapeUser;
				char* escapeAcc;
				unsigned long escapeDataLen;
				const char* data = user.str();
				unsigned long dataLen = strlen(data);
				theDB->Escape(data, dataLen, escapeUser, escapeDataLen);
				escapeMemName.add(escapeUser);

				data = acc.c_str();
				dataLen = strlen(data);
				theDB->Escape(data, dataLen, escapeAcc, escapeDataLen);
				escapeMemName.add(escapeAcc);

				//make sql
	#define CDKEY_PROCEDURE "proc_get_activity_reward"

				unsigned long sqlLen = snprintf(m_sqlBuff, sizeof(m_sqlBuff), "CALL %s('%s', '%s', %d, @Result, @TotalScore, @SubScore1);", 
					CDKEY_PROCEDURE, escapeAcc, escapeUser, actID);

				if(gDebug)
					LOG(LOG_DEBUG, "%s", m_sqlBuff);

				
				START_QUERY_TIME;
				if(theDB->Query(m_sqlBuff, sqlLen, NULL) != 0)
				{
					LOG(LOG_ERROR, "theDB->query: %s", theDB->GetErr());
					break;
				}
				END_QUERY_TIME;
				if(m_interval > SLOW_MS)
				{
					LOG(LOG_ERROR, "%s|GET|SLOW|%d", user.str(), m_interval);
				}

				sqlLen = snprintf(m_sqlBuff, sizeof(m_sqlBuff), "SELECT @Result, @TotalScore, @SubScore1;");

				if(gDebug)
					LOG(LOG_DEBUG, "%s", m_sqlBuff);

				MysqlResult result;
				START_QUERY_TIME;
				if(theDB->Query(m_sqlBuff, sqlLen, &result) != 0)
				{
					LOG(LOG_ERROR, "theDB->query: %s", theDB->GetErr());
					break;
				}
				END_QUERY_TIME;
				if(m_interval > SLOW_MS)
				{
					LOG(LOG_ERROR, "%s|GET|SLOW|%d", user.str(), m_interval);
				}

				int rowNum = result.RowNum();
				if( rowNum != 1)
				{
					LOG(LOG_ERROR, "fetch row failed, row:%d != 1", rowNum);
					break;
				}
				char** rcd = result.FetchNext();
				if( NULL == rcd )
				{
					LOG(LOG_ERROR, "NULL == rcd");
					break;
				}
				int fieldNum = result.FieldNum();
				if( fieldNum < 3 )
				{
					LOG(LOG_ERROR, "fetch row failed, fieldNum:%d < 3", fieldNum);
					break;
				}

				std::istringstream iss;
				
				rewardRet.Result = atoi(rcd[0]);
				rewardRet.TotalScore = atoi(rcd[1]);
				rewardRet.SubScore1 = atoi(rcd[2]);
	
				LOG(LOG_INFO, "%s|acc:%s|actID:%d|Result=%d|TotalScore=%d|SubScore1=%d", 
					user.str(), acc.c_str(), actID, rewardRet.Result, rewardRet.TotalScore, rewardRet.SubScore1);
				break;
			}
			//处理完，非长链释放
			freeDB(config, theDB);
			return 0;
		}

	protected:
		inline int to_pool_idx(int dbIdx)
		{
			return dbIdx - m_DBidxStart;
		}

		MysqlDB* initCDKeyDB(CMysqlHelperConfig& config)
		{
			MysqlDB* theDB;
#define DBNAME_CDKEY "db_gl_cdkey"
			if(config.mysqlKeepAlive && mCDKeyDB != NULL)
			{
				theDB = mCDKeyDB;
				if(!theDB->IsConnected())
				{
					theDB->SetTimeOut(config.mysqltimeout);
	
					if(theDB->Connect(config.mysqlSvrIP, config.mysqlUser, config.mysqlPassword, config.mysqlDBPrefix, config.mysqlSvrPort, true, config.mysqlSock) != 0)
					{
						LOG(LOG_ERROR, "db Connect fail %s", theDB->GetErr());
						return NULL;
					}
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

				if( theDB->Connect(config.mysqlSvrIP, config.mysqlUser, config.mysqlPassword, config.mysqlDBPrefix, config.mysqlSvrPort) != 0)
				{
					LOG(LOG_ERROR, "db Connect fail %s", theDB->GetErr());
					delete theDB;
					return NULL;
				}
				if( config.mysqlKeepAlive )
				{
					mCDKeyDB = theDB;
				}
			}

			return theDB;
		}



		MysqlDB* initDB(CMysqlHelperConfig& config, USER_NAME& name, int sid)
		{
			MysqlDB* theDB;
			char dbnameBuff[256];
			int dbIdx = sid;
			if(config.mysqlKeepAlive)
			{
				//找到对应的链接
				map<int, MysqlDB *>::iterator it = m_theDBPool.find(dbIdx);
				if(it == m_theDBPool.end())
				{
					LOG(LOG_ERROR, "sid %d not find", sid);
					return NULL;
				}
				theDB = it->second;
				if(!theDB->IsConnected())
				{
					theDB->SetTimeOut(config.mysqltimeout);
					snprintf(dbnameBuff, sizeof(dbnameBuff), "%s_%05d", config.mysqlDBPrefix, dbIdx);
					if(theDB->Connect(config.mysqlSvrIP, config.mysqlUser, config.mysqlPassword, dbnameBuff, config.mysqlSvrPort, true, config.mysqlSock) != 0)
					{
						LOG(LOG_ERROR, "db Connect fail %s", theDB->GetErr());
						return NULL;
					}
				}
			}
			else
			{
				snprintf(dbnameBuff, sizeof(dbnameBuff), "%s_%05d", config.mysqlDBPrefix, dbIdx);
				theDB = new MysqlDB;
				if(theDB == NULL)
				{
					LOG(LOG_ERROR, "new MysqlDB fail");
					return NULL;
				}
				
				if( theDB->Connect(config.mysqlSvrIP, config.mysqlUser, config.mysqlPassword, dbnameBuff, config.mysqlSvrPort) != 0)
				{
					LOG(LOG_ERROR, "db Connect fail %s", theDB->GetErr());
					delete theDB;
					return NULL;
				}
			}

			return theDB;
		}

		void freeDB(CMysqlHelperConfig& config,MysqlDB*& theDB)
		{
			if(!config.mysqlKeepAlive && theDB)
			{
				delete theDB;
				theDB = NULL;
			}
		}

		inline int add_sql_str(unsigned long& sqlLen, const char* tmpstr)
		{
			unsigned int tmplen = strlen(tmpstr);
			if(tmplen > sizeof(m_sqlBuff)-sqlLen)
			{
				LOG(LOG_ERROR, "sql too long");
				return -1;
			}
			
			memcpy(m_sqlBuff+sqlLen, tmpstr, tmplen);
			sqlLen += tmplen;

			return 0;
		}

		inline int add_sql_val(unsigned long& sqlLen, const char* start, unsigned long tmplen)
		{
			if(tmplen > sizeof(m_sqlBuff)-sqlLen)
			{
				LOG(LOG_ERROR, "sql too long");
				return -1;
			}
			
			memcpy(m_sqlBuff+sqlLen, start, tmplen);
			sqlLen += tmplen;
		
			return 0;
		}


	protected:
		int m_DBidxStart;
		int m_DBidxEnd;
		CToolkit m_toolkit;
		char m_sqlBuff[MSG_BUFF_LIMIT*2+1024];
		unsigned long readcnt;
		unsigned long writecnt;
		unsigned long totalcnt;
		unsigned long readlimited;
		unsigned long writelimited;
		timeval start_t;
		timeval end_t;
		int m_interval;
		static const int SLOW_MS=10;
		map<int, MysqlDB *> m_theDBPool;
		MysqlDB *mCDKeyDB;
};


static void stophandle(int iSigNo)
{
	gstopflag= 1;
	LOG(LOG_INFO, "recieve siganal %d, stop",  iSigNo);
	LOG(LOG_ERROR, "recieve siganal %d, stop",  iSigNo);
}

static void usr1handle(int iSigNo)
{
	gDebug = (gDebug+1)%2;
	cout << "gDebug=" << gDebug << endl;
}

class CMysqlHelperManager: public CProcessManager
{
public:
	CMysqlHelperManager(CMysqlHelperConfig& config, CMsgQueuePipe& theQueue):m_config(config), m_queue(theQueue)
	{
	}
	
protected:
	virtual int entity( int argc, char *argv[] )
	{
		CMysqlHelperProcess process;
		return process.run(m_config, m_queue);
	}

protected:
	CMysqlHelperConfig& m_config;
	CMsgQueuePipe& m_queue;
};


int main(int argc, char **argv)
{
	if(argc < 3)
	{
		cout << argv[0] << " mysql_helper_ini pipe_ini" <<endl;
		return 0;
	}

	CIniFile oIni(argv[1]);
	if(!oIni.IsValid())
	{
		cout << "read ini " << argv[1] << "fail" << endl;
		return 0;
	}
	//log
	LOG_CONFIG logConf(oIni, "MYSQL_HELPER");
	logConf.debug(cout);
	LOG_CONFIG_SET(logConf);
	cout << "log open=" << LOG_OPEN_DEFAULT(NULL) << " " << LOG_GET_ERRMSGSTRING << endl;

	//config
	CMysqlHelperConfig config;
	if(config.read_from_ini(oIni, "MYSQL_HELPER")!=0)
	{
		cout << "config.read_from_ini fail" << endl;
		return 0;
	}
	
	config.debug(cout);

	if(g_cdkey_mysql.read_from_ini(oIni, "CDKEY")!=0)
	{
		cout << "config.read_from_ini fail" << endl;
		return 0;
	}
	g_cdkey_mysql.debug(cout);

	//queue pipe
	CPIPEConfigInfo pipeconfig;
	if(pipeconfig.set_config(argv[2])!= 0)
	{
		cout << "parse ini fail " << endl;
		return 0;
	}

	CDequePIPE pipe;
	if(pipe.init(pipeconfig, config.queueID, false) != 0)
	{
		cout << "pipe init" << pipe.errmsg() << endl;
		return 0;
	}
	CMsgQueuePipe queue(pipe, &gDebug);
	
	//lock & daemon
	if(CServerTool::run_by_ini(&oIni, "MYSQL_HELPER")!=0)
	{
		cout << "run_by_ini  fail" << endl;
		return 0;
	}

	//signal
	CServerTool::sighandle(SIGTERM, stophandle);
	CServerTool::sighandle(SIGUSR1, usr1handle);

	//开始Process Manager运行
	CMysqlHelperManager manager(config,queue);
	manager.attach_stop_flag(&gstopflag);
	manager.set_child_num(config.procNum);
	if(manager.run(argc, argv)!=manager.SUCCESS)
	{
		return 0;
	}

	return 1;
}


