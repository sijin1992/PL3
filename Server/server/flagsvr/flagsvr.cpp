#include <iostream>
#include "ini/ini_file.h"
#include "log/log.h"
#include "logic/driver.h"
#include <time.h>
#include <map>
using namespace std;

//!!todo: modify 
#include "flag_svr_def.h"
//#include "logic_rank.h"
//#include "logic_cdkey.h"
#include "rank_pool.h"
#include "time/interval_ms.h"
//#include "proto/rankprotocol.pb.h"

#define INI_FALGMAP_SECTOR "FLAG_SVR"
#define INI_LOG_SECTOR "FLAG_SVR"
#define INI_LISTEN_QUEUE_SECTOR "FLAG_SVR"
#define INI_LISTEN_QUEUE_ITEM "LISTEN_QUEUE_ID"
#define INI_DRIVER_SECTOR "LOGIC_DRIVER"
#define INI_SERVER_TOOL_SECTOR "FLAG_SVR"
#define BOOL_ACTIVE false
#define INI_LOGIC_SERVER_SET "LOGIC_SVRSET"

//#ifndef USE_MEMCACHED
//#include "logic_flag.h"
//#else
//#include "logic_flag_memcache.h"
//#define INI_MEMCACHED_QUEUENAME "MEMCACHED_QUEUE_ID"
//#endif

CShmHashMap<FLAG_SERVER_UNIT, USER_NAME_BYTE, UserByteHashType> gFlagMapOld;
CShmHashMap<FLAG_SERVER_UNIT, USER_NAME_BYTE, UserByteHashType> gFlagMap;
CRankPool gRankPool; //名将之路排名
map<int, CRankPool*> gRankPoolMap; // boss 挑战排名，每周清空
map<int, CRankPool*> gRankPoolMap2; // 抽奖排名，每日清空
map<int, CRankPool*> gRankPoolMap3; //通用排名，排名100，不清空
map<int, CRankPool*> gRankPoolMap4; //通用排名，排名500，不清空

//!!end
int gMemcachedQueueID=0;
int gListenQueueID=0;
int gDebug=0;
int gAliveIntvl=0;
unsigned int gLogicSvrSetID=0;

class CFlagLogicDriver: public CLogicDriver
{
public:
	CFlagLogicDriver()
	{
		loopTimes = 0;
		lastUpdateRank2 = time(NULL);
		string ssvridlimit="3.0.0.1";
		string ssvridtarget = "1.0.0.1";
		CTcpSocket::str_to_addr(ssvridlimit, svridlimit);
		CTcpSocket::str_to_addr(ssvridtarget, svridtarget);
	}

	inline void send_alive_to_linker()
	{
		USER_NAME emptyUser;
		if(m_toolkit.send_bin_msg_to_queue(CMD_FLAG_ALIVE_REQ, emptyUser, gListenQueueID, 0, gLogicSvrSetID) 
			!=0)
		{
			LOG(LOG_ERROR, "send_alive_to_linker fail");
		}
	}

	inline void send_rankcallback(int rankid, int rank, RANK_UNIT* val)
	{
//		RankCallBack cb;
//		cb.set_ranktype(2);
//		cb.set_rankid(rankid);
//		cb.set_rank(rank);
//		if(m_toolkit.send_protobuf_msg(gDebug,cb, CMD_FLAG_RANK_CALLBACK_REQ, val->user, gListenQueueID, svridtarget)
//			!=0)
//		{
//			LOG(LOG_ERROR, "%s|send_rankcallback fail rank=%d",val->user.str(), rank);
//		}
//		else
//		{
//			LOG(LOG_INFO, "%s|send_rankcallback ok rank=%d",val->user.str(), rank);
//		}
	}

	inline CRankPool* get_luckpool(int id)
	{
		map<int, CRankPool*>::iterator it = gRankPoolMap2.find(id); //昨天
		CRankPool*  ppool = NULL;
		if(it == gRankPoolMap2.end())
		{
			ppool = new CRankPool;
			if(ppool == NULL)
			{
				LOG(LOG_ERROR, "new CRankPool fail");
				return NULL;
			}
			
			char file[256];
			snprintf(file, sizeof(file), "luckrank_%d.mmap", id);
			if(ppool->ext_init(file, 5)!=0)
			{
				LOG(LOG_ERROR, "CRankPool init(%s, 5) fail",  file);
				delete ppool;
				return NULL;
			}
			
			gRankPoolMap2.insert(make_pair(id, ppool));
		}
		else
		{
			ppool = it->second;
		}

		return ppool;
	}
	
	virtual int hook_loop_end()
	{
		if(++loopTimes >= 100)
		{
			loopTimes = 0;
			if(intvlMs.check_timeout(gAliveIntvl, true))
			{
				send_alive_to_linker();
			}

			//每日清空gRankPoolMap2
			tm * ptm = localtime(&lastUpdateRank2);
			time_t timelimit = lastUpdateRank2 + 24*3600 - (ptm->tm_hour*3600+ptm->tm_min*60+ptm->tm_sec);
			time_t nowtime = time(NULL);
			if(nowtime > timelimit)
			{
				LOG(LOG_INFO, "gRankPoolMap2 clear nowtime=%ld, lastUpdateRank2=%ld, timelimit=%ld", nowtime, lastUpdateRank2, timelimit);
				lastUpdateRank2 = nowtime;
				CRankPool* ppool =get_luckpool(1);//今天
				if(ppool)
				{
					if(m_serverID == svridlimit) //svr 1为主，只有主svr通知logic
					{
						LOG(LOG_INFO, "send callback for main svr");
						for(int i=0; i<ppool->size(); ++i)
						{
							send_rankcallback(1, i+1, ppool->val(i));
						}
					}

					CRankPool* ppool2 = get_luckpool(2);//昨天
					if(ppool2)
					{
						if(ppool2->size() > 0)
						{
							CRankPool* ppool3 = get_luckpool(3); //前天
							if(ppool3)
							{
								if(ppool3->size() > 0)
								{
									CRankPool* ppool4 = get_luckpool(4); //大前天
									if(ppool4)
										ppool4->copy(ppool3);
								}
								ppool3->copy(ppool2);
							}
						}

						ppool2->copy(ppool);
					}
					
					ppool->exthead()->format(nowtime);
					ppool->head()->used=0;
				}
			}
		}

		return 0;
	}
	
protected:
	int loopTimes;
	CIntervalMs intvlMs;
	time_t lastUpdateRank2;
	unsigned int svridlimit;
	unsigned int svridtarget;
};

CFlagLogicDriver gDriver;

static void stophandle(int iSigNo)
{
	gDriver.stopFlag = 1;
	LOG(LOG_INFO, "recieve siganal %d, stop",  iSigNo);
	LOG(LOG_ERROR, "recieve siganal %d, stop",  iSigNo);
}

static void usr1handle(int iSigNo)
{
	gDebug = (gDebug+1)%2;
	cout << "gDebug=" << gDebug << endl;
}


static int regist_all_handles()
{
	//!!to-do regist handles
	/*
	//cmd should return RET_YIELD
	if(driver.regist_handle(CMD_XXX, CLogicCreator(new CLogicXXX))!=0)
	{
		return 0;
	}
	*/

	//cmd should not return RET_YIELD
//	#ifndef USE_MEMCACHED
//	if(gDriver.regist_handle(CMD_FLAG_GET_REQ, CLogicCreator(new CLogicFlag, true))!=0)
//	{
//		return 0;
//	}
//	
//	if(gDriver.regist_handle(CMD_FLAG_SET_REQ, CLogicCreator(new CLogicFlag, true))!=0)
//	{
//		return 0;
//	}
//	#else
//
//	if(gDriver.regist_handle(CMD_FLAG_GET_REQ, CLogicCreator(new CLogicFlagMemcache, true))!=0)
//	{
//		return 0;
//	}
//	
//	if(gDriver.regist_handle(CMD_FLAG_SET_REQ, CLogicCreator(new CLogicFlagMemcache, true))!=0)
//	{
//		return 0;
//	}
//
//	if(gDriver.regist_handle(CMD_FLAG_GET_RESP, CLogicCreator(new CLogicFlagMemcache, true))!=0)
//	{
//		return 0;
//	}
//	
//	#endif
//
//	if(gDriver.regist_handle(CMD_FLAG_RANK_GET_REQ, CLogicCreator(new CLogicFlagRank, true))!=0)
//	{
//		return 0;
//	}
//	
//	if(gDriver.regist_handle(CMD_FLAG_RANK_SET_REQ, CLogicCreator(new CLogicFlagRank, true))!=0)
//	{
//		return 0;
//	}
//
//	if(gDriver.regist_handle(CMD_FLAG_CDKEY_GET_REQ, CLogicCreator(new CLogicFlagCDKey, true))!=0)
//	{
//		return 0;
//	}
//	
//	if(gDriver.regist_handle(CMD_FLAG_CDKEY_SET_REQ, CLogicCreator(new CLogicFlagCDKey, true))!=0)
//	{
//		return 0;
//	}

	return 1;
}

static int loadOldData()
{
	if(gFlagMap.m_config.shmKey == FLAG_SVR_SHM_KEY_OLD)
	{
		cout << "keep old data" << endl;
		return 0;
	}

	int ret = gFlagMapOld.tryGet(FLAG_SVR_SHM_KEY_OLD);
	if(ret < 0)
	{
		cout << "get old data(key=0x" << hex << FLAG_SVR_SHM_KEY_OLD << dec << ") fail" << endl;
		return -1;
	}
	else if(ret == 0)
	{
		cout << "no old data" << endl;
		return 0;
	}

	if(gFlagMapOld.m_config.nodeNum > gFlagMap.m_config.nodeNum 
		|| gFlagMapOld.m_config.hashNum > gFlagMap.m_config.hashNum)
	{
		cout << "old data bigger than now" << endl;
		return -1;
	}

	//copy data
	if(gFlagMap.get_map()->copyFrom(gFlagMapOld.get_map())!=0)
	{
		cout << gFlagMap.get_map()->m_err.errstrmsg << endl;
		return -1;
	}
	
	return 0;
}

int main(int argc, char **argv)
{	
	int ret = 0;
	//!!todo: modify if you have other arg
	if(argc < 4)
	{
		cout << argv[0] << " server_ini pipe_ini format(0,1)" << endl;
		return 0;
	}

	int format = 0;
	if(atoi(argv[3])!=0)
	{
		format = 1;
	}

	cout <<  "argv[3]="<< argv[3] << " format=" << format << endl;

	//server conf
	CIniFile oIni(argv[1]);
	if(!oIni.IsValid())
	{
		cout <<  "read ini "<< argv[1] << " fail" << endl;
		return 0;
	}

	//open log
	LOG_CONFIG logConf(oIni, INI_LOG_SECTOR);
	logConf.debug(cout);
	LOG_CONFIG_SET(logConf);
	cout << "log open=" << LOG_OPEN_DEFAULT(NULL) << " " << LOG_GET_ERRMSGSTRING << endl;

	//gRankPool
	if(gRankPool.init(oIni, "RANK", format) !=0)
	{
		cout << "rankpool init fail" << endl;
		return 0;
	}

	//listen queue id
	if(oIni.GetInt(INI_LISTEN_QUEUE_SECTOR, INI_LISTEN_QUEUE_ITEM, 0, &gListenQueueID)!=0)
	{
	 	cout << INI_LISTEN_QUEUE_SECTOR"."INI_LISTEN_QUEUE_ITEM" not found" << endl;
		return 0;
	}

	//logic svrset
	char buff[16] = {0};
	if(oIni.GetString(INI_LISTEN_QUEUE_SECTOR, INI_LOGIC_SERVER_SET, "", buff, sizeof(buff))!=0)
	{
	 	cout << INI_LISTEN_QUEUE_SECTOR"."INI_LOGIC_SERVER_SET" not found" << endl;
		return 0;
	}

	if(CTcpSocket::str_to_addr(buff, gLogicSvrSetID)!=0)
	{
		cout << INI_LISTEN_QUEUE_SECTOR"."INI_LOGIC_SERVER_SET"(" << buff << ") not valid" << endl;
		return 0;
	}

	cout << "gLogicSvrSetID(" << gLogicSvrSetID << ")=" << CTcpSocket::addr_to_str(gLogicSvrSetID) << endl;

	
	//pipe config
	CPIPEConfigInfo pipeconfig;
	if(pipeconfig.set_config(argv[2])!= 0)
	{
		cout << "CPIPEConfigInfo config fail " << endl;
		return 0;
	}

	//special conifg
#ifndef USE_MEMCACHED
	ret = gFlagMap.init(oIni, INI_FALGMAP_SECTOR, format);
	if(ret != 0)
	{
		cout << "gFlagMap.init fail" << endl;
		return 0;
	}

	//if(loadOldData()!=0)
	//	return 0;
#else
	if(oIni.GetInt(INI_LISTEN_QUEUE_SECTOR, INI_MEMCACHED_QUEUENAME, 0, &gMemcachedQueueID)!=0)
	{
	 	cout << INI_LISTEN_QUEUE_SECTOR"."INI_MEMCACHED_QUEUENAME" not found" << endl;
		return 0;
	}
#endif

	oIni.GetInt(INI_SERVER_TOOL_SECTOR, "ALIVE_INTERVAL_MS", 500, &gAliveIntvl);
	CServerTool::server_param_safe(gAliveIntvl, 10, 10000, 500);

	//init driver
	CDequePIPE listenPipe;
	if(listenPipe.init(pipeconfig, gListenQueueID, BOOL_ACTIVE) != 0)
	{
		cout << "listenPipe init " << listenPipe.errmsg() << endl;
		return 0;
	}
	CMsgQueuePipe listenQueue(listenPipe, &gDebug);

	if(gDriver.add_msg_queue(gListenQueueID, &listenQueue)!=0)
	{
		return 0;
	}

#ifdef USE_MEMCACHED
	CDequePIPE memcachePipe;
	if(memcachePipe.init(pipeconfig, gMemcachedQueueID, true) != 0)
	{
		cout << "listenPipe init " << memcachePipe.errmsg() << endl;
		return 0;
	}
	CMsgQueuePipe memcacheQueue(memcachePipe, &gDebug);

	if(gDriver.add_msg_queue(gMemcachedQueueID, &memcacheQueue)!=0)
	{
		return 0;
	}
#endif

	if(regist_all_handles()!=1)
	{
		return 0;
	}

	CLogicDriverConfig configDriver;
	ret = configDriver.readFromIni(oIni, INI_DRIVER_SECTOR);
	if(ret < 0)
	{
		cout << "CLogicDriverConfig readFromIni fail" << endl;
		return 0;
	}
	
	ret = gDriver.init(configDriver);
	if(ret != 0)
	{
		cout << "init fail" << endl;
		return 0;
	}

	//lock & daemon
	if(CServerTool::run_by_ini(&oIni, INI_SERVER_TOOL_SECTOR)!=0)
	{
		cout << "run_by_ini  fail" << endl;
		return 0;
	}

	//signal
	CServerTool::sighandle(SIGTERM, stophandle);
	CServerTool::sighandle(SIGUSR1, usr1handle);

	cout << argv[0] << " main_loop=" << gDriver.main_loop(-1) << endl;
		
	return 1;
}

