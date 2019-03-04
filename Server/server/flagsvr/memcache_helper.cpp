#include "memcached/my_memcached.hpp"
#include <iostream>
#include <string.h>
#include <sstream>
#include "ini/ini_file.h"
#include "process_manager/process_manager.h"
#include "common/msg_define.h"
#include "common/server_tool.h"
#include "common/sleep_control.h"
#include "common/speed_control.h"
#include "common/user_distribute.h"
#include "logic/msg_queue.h"
#include "logic/toolkit.h"
#include "proto/flagProtocol.pb.h"
#include "memcached/my_memcached.hpp"
#include "flag_svr_def.h"

using namespace std;
using namespace memcache;

int gstopflag = 0;
int gDebug=0;

class CMemcacheHelperConfig
{
public:
	void debug(ostream& os)
	{
		os << "CMemcacheHelperConfig{" << endl;
		os << "serverconf|" << serverconf << endl;
		os << "queueID|" << queueID << endl;
		os << "procNum|" << procNum << endl;
		os << "}END CMemcacheHelperConfig" << endl;
	}

	int read_from_ini(CIniFile& oIni, const char* sectorName)
	{
		char buff[256] = {0};
		if(oIni.GetString(sectorName, "MEMCACHED", "", buff, sizeof(buff))!=0)
		{
			LOG(LOG_ERROR, "%s.MEMCACHED not found", sectorName);
			return -1;
		}
		serverconf = buff;


		if(oIni.GetInt("FLAG_SVR", "MEMCACHED_QUEUE_ID", 0, &queueID)!=0)
		{
			LOG(LOG_ERROR, "FLAG_SVR.MEMCACHED_QUEUE_ID not found");
			return 0;
		}

		if(oIni.GetInt(sectorName, "PROC_NUM", 0, &procNum)!=0)
		{
			LOG(LOG_ERROR, "%s.PROC_NUM not found", sectorName);
			return 0;
		}

		if(procNum <= 0)
		{
			LOG(LOG_ERROR, "%s.PROC_NUM = %d not valid", sectorName, procNum);
			return 0;
		}

		return 0;
	}

public:
	string serverconf;
	int queueID;
	int procNum;
};

class CMemcacheHelper
{
	public:
		CMemcacheHelper()
		{
		}

		~CMemcacheHelper()
		{
		}

	protected:
		int get_from_memcatch(FlagList& reqlist, FlagList& respemptylist)
		{
			string key;
			vector<char> vals;
			uint32_t flags;
			uint64_t cas;
			vector<string> thekeys;
			int total = reqlist.items_size();
			int i;
			USER_NAME name;
			USER_NAME_BYTE bytename;
			for(i=0; i<total; ++i)
			{
				name.from_str(reqlist.items(i).user());
				name.tobyte(bytename);
				string akey;
				akey.assign((char*)bytename.val, sizeof(bytename.val));
				thekeys.push_back(akey);
			}
			if(!memcacheclt.mget(thekeys))
			{
				LOG(LOG_ERROR, "mget error=%d %s", memcacheclt.lastretcode(), memcacheclt.lastretstr().c_str());
				return -1;
			}

			FlagItem* pitem;
			for(i=0; i<total; ++i)
			{
				const FlagItem& reqitem = reqlist.items(i);
				pitem = respemptylist.add_items();
				pitem->set_user(reqitem.user());
				pitem->set_level(1);
			}
			
			for(i=0; i<(int)thekeys.size(); ++i)
			{
				memcached_return_t ret = memcacheclt.fetch(key, vals, flags, cas);
				if(!memcached_success(ret))
				{
					if(ret == 16) //not found
					{
					}
					else
					{
						LOG(LOG_ERROR, "mget error=%d %s", ret, memcacheclt.getError(ret).c_str());
					}
				}
				else
				{
					FLAG_SERVER_UNIT theval;
					if(vals.size() == sizeof(theval))
					{
						memcpy(&theval, &vals[0], sizeof(theval));

						memcpy(bytename.val, key.data(), sizeof(bytename.val));
						name.frombyte(bytename);
						bool found= false;
						for(int i=0; i<total; ++i)
						{
							pitem = respemptylist.mutable_items(i);
							USER_NAME thename;
							thename.from_str(pitem->user());
							//LOG(LOG_INFO, "%s %s", thename.str(), name.str());
							if(thename == name)
							{
								pitem->set_level(theval.level);
								if(theval.boxlevel >= 0)
								{
									FightBox* pbox = pitem->mutable_fightbox();
									pbox->set_exist(theval.boxexist);
									pbox->set_endtime(theval.boxendtime);
									pbox->set_level(theval.boxlevel);
								}
								found = true;
								break;
							}
						}
						
						if(gDebug)
						{
							if(found)
								LOG(LOG_INFO, "fetch(key=%s) %s=(level=%d)", 
									key.c_str(), pitem->user().c_str(), pitem->level());
							else
								LOG(LOG_INFO, "fetch(key=%s) not found", key.c_str());
						}
					}
					else
					{
						LOG(LOG_ERROR, "val.length != sizeof(FLAG_SERVER_UNIT)");
					}
				}
			}

			return 0;
		}

		void mergelist(const FlagList& reqlist, FlagList& resplist)
		{
			int total = reqlist.items_size();
			int i;
			for(i=0; i<total; ++i)
			{
				const FlagItem& req = reqlist.items(i);
				FlagItem* presp = resplist.mutable_items(i);
				if(req.has_level())
				{
					presp->set_level(req.level());
				}

				if(req.has_fightbox())
				{
					presp->mutable_fightbox()->CopyFrom(req.fightbox());
				}
			}

		}

		int set_to_memcache(FlagList& list)
		{
			int total = list.items_size();
			int i;
			USER_NAME name;
			USER_NAME_BYTE bytename;
			FLAG_SERVER_UNIT tmpval;
			std::map<const string, vector<char> > key_value_map;
			for(i=0; i<total; ++i)
			{
				const FlagItem& theitem = list.items(i);
				if(theitem.has_level())
				{
					tmpval.level = theitem.level();
				}
				else
				{
					tmpval.level = 1;
				}

				if(theitem.has_fightbox())
				{
					const FightBox& box = theitem.fightbox();
					tmpval.boxendtime = box.endtime();
					tmpval.boxexist = box.exist();
					tmpval.boxlevel = box.level();
				}
				else
				{
					tmpval.boxlevel = -1;
					tmpval.boxexist = 0;
					tmpval.boxendtime = 0;
				}
				
				name.from_str(theitem.user());
				name.tobyte(bytename);
				string key;
				key.assign((char*)bytename.val, sizeof(bytename.val));
				vector<char> value;
				char* pstart = (char*)&tmpval;
				value.assign(pstart, pstart+sizeof(tmpval));

				key_value_map[key] = value;
				if(gDebug)
				{
					LOG(LOG_INFO, "set %s=(level=%d)", theitem.user().c_str(), theitem.level());
				}
			}

			
			if( !memcacheclt.setAll(key_value_map, 0, 0))
			{
				LOG(LOG_ERROR, "mget error=%d %s", memcacheclt.lastretcode(), memcacheclt.lastretstr().c_str());
				return -1;
			}

			return 0;
		}

	public:
		int run(CMemcacheHelperConfig& config, CMsgQueuePipe& theQueue)
		{
			readcnt = 0;
			writecnt = 0;
			totalcnt = 0;

			if(!memcacheclt.configure(config.serverconf))
			{
				LOG(LOG_ERROR, "memcached=%s error=%d %s", config.serverconf.c_str(), memcacheclt.lastretcode(), memcacheclt.lastretstr().c_str());
				return 0;
			}

			CLogicMsg reqMsg(m_toolkit.readBuff, sizeof(m_toolkit.readBuff));
			CSleepControl theSleep;
			theSleep.setparam(1000,1000, 100000);

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

				if(++totalcnt%1000 == 0)
				{
					LOG(LOG_INFO, "totalcnt=%lu readcnt=%lu writecnt=%lu", 
						totalcnt, readcnt, writecnt);
				}

				unsigned int cmd = m_toolkit.get_cmd(reqMsg);
				if(gDebug)
				{
					LOG(LOG_INFO, "recv cmd 0x%x", cmd);
				}

				CBinProtocol binpro;
				if(m_toolkit.parse_bin_msg(reqMsg, binpro) != 0)
				{
					theSleep.delay();
					continue;
				}
				USER_NAME requser = binpro.head()->parse_name();

				//收到正确的包了
				theSleep.cancel_delay();
				m_list.Clear();
				if( m_toolkit.parse_protobuf_bin(gDebug, binpro, m_list) != 0)
				{
					continue;
				}


				if(cmd == CMD_FLAG_GET_REQ)
				{
					FlagList resp;
					if(get_from_memcatch(m_list,resp)!=0)
					{
						continue;
					}
					
					++readcnt;
					m_toolkit.send_protobuf_msg(gDebug,resp, CMD_FLAG_GET_RESP, requser,
						&theQueue, m_toolkit.get_src_server(reqMsg), m_toolkit.get_src_handle(reqMsg));
				}
				else if(cmd == CMD_FLAG_SET_REQ)
				{
					FlagList getresp;
					if(get_from_memcatch(m_list,getresp)!=0)
					{
						continue;
					}

					mergelist(m_list, getresp);

					if(set_to_memcache(getresp)!=0)
					{
						continue;
					}
					
					++writecnt;
				}
				else
				{
					LOG(LOG_ERROR, "cmd 0x%x invalid", cmd);
				}


				theSleep.work(1);
			}

			return 0;
		}

	protected:
		CMyMemcache memcacheclt;
		unsigned long readcnt;
		unsigned long writecnt;
		unsigned long totalcnt;
		CToolkit m_toolkit;
		FlagList m_list;
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
	cout << "memcache_helper gDebug=" << gDebug << endl;
}

class CMemcacheHelperManager: public CProcessManager
{
	public:
		CMemcacheHelperManager(CMemcacheHelperConfig& config, CMsgQueuePipe& theQueue):m_config(config), m_queue(theQueue)
		{
		}
		
	protected:
		virtual int entity( int argc, char *argv[] )
		{
			CMemcacheHelper process;
			return process.run(m_config, m_queue);
		}
	
	protected:
		CMemcacheHelperConfig& m_config;
		CMsgQueuePipe& m_queue;
};

int main(int argc, char **argv)
{
	if(argc < 3)
	{
		cout << argv[0] << " flagsvr.ini pipe_ini" <<endl;
		return 0;
	}

	CIniFile oIni(argv[1]);
	if(!oIni.IsValid())
	{
		cout << "read ini " << argv[1] << "fail" << endl;
		return 0;
	}

	//log
	LOG_CONFIG logConf(oIni, "MEMCACHE_HELPER");
	logConf.debug(cout);
	LOG_CONFIG_SET(logConf);
	cout << "log open=" << LOG_OPEN_DEFAULT(NULL) << " " << LOG_GET_ERRMSGSTRING << endl;

	//config
	CMemcacheHelperConfig config;
	
	if(config.read_from_ini(oIni, "MEMCACHE_HELPER")!=0)
	{
		cout << "config.read_from_ini fail" << endl;
		return 0;
	}
	
	config.debug(cout);

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
	if(CServerTool::run_by_ini(&oIni, "MEMCACHE_HELPER")!=0)
	{
		cout << "run_by_ini  fail" << endl;
		return 0;
	}

	//signal
	CServerTool::sighandle(SIGTERM, stophandle);
	CServerTool::sighandle(SIGUSR1, usr1handle);

	//开始Process Manager运行
	CMemcacheHelperManager manager(config, queue);
	manager.attach_stop_flag(&gstopflag);
	manager.set_child_num(config.procNum);
	if(manager.run(argc, argv)!=manager.SUCCESS)
	{
		return 0;
	}

	return 1;
}

