/*
* 用户身份认证的server
*/
#include <sstream>

#include "lua_manager.h"

#include "common/msg_define.h"
#include "logic/driver.h"
#include "login.h"
#include "logout.h"
#include "regist.h"
#include "heart_beat.h"

#include "logic_gm.h"
#include "logic_gm_usersnap.h"
#include "online_cache.h"
#include "common/user_distribute.h"
#include "data_cache/data_cache.h"
#include "struct/timer.h"
#include "logic_httpcb.h"
#include "logic_cdkey.h"
#include "logic_chat.h"

#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <fstream>
#include "neiceuser.h"
#include "dirtyword/dirtyword.h"

#include "logic_lua.h"

#include "xml2lua/all_config.h"
#include "logic_info.h"

#include "proto/inner_cmd.pb.h"
#include "lua_global_wrap.h"
//#include "world_boss_manager.h"


using namespace std;

unsigned int MSG_QUEUE_ID_LOGIC = 0;
unsigned int MSG_QUEUE_ID_DB = 0; //准确的说是到tcplinker
unsigned int MSG_QUEUE_ID_GATEWAY = 0;
unsigned int MSG_QUEUE_ID_HTTPCB = 0;
unsigned int MSG_QUEUE_ID_LOG = 0;

int LOCK_PERIOD = 0;
unsigned int TIMEOUT_FOR_DB = 0;
unsigned int CHECK_ONLINE_INTERVAL = 0;
unsigned int KICK_USER_TIME = 0;
unsigned int FLAG_SVRSET=0;

COnlineCache gOnlineCache;
CDataCache gDataCache;
int gDebugFlag=0;
int gInfoDetail=0;
CUserDistribute gDistribute; 

CShmTimer<unsigned int> gTheTimer;

CHashedUserList gneiceuser;
string gGMXML; //gm配置文件路径

CDirtyWord gDirtyWord;
//世界BOSS管理器
//CWorldBossManager gWBossMgr;

int gVipBindQzone=1;

logic_info g_logic_info;

time_t g_ext_time = 0;


#define MAIN_LOGIC_REGIST_CMD(cmdName, className) \
if(driver.regist_handle(cmdName, CLogicCreator(new className))!=0) \
{ \
	return 0; \
}

#define MAIN_LOGIC_REGIST_CMD_UNIQ(cmdName, className) \
if(driver.regist_handle(cmdName, CLogicCreator(new className, true))!=0) \
{ \
	return 0; \
}


class CLogicMainDriver: public CLogicDriver
{
public:
	CLogicMainDriver()
	{
		loopnum = 0;
		lastlogtime = time(NULL);
		last_notify_time = 0;
		last_reflesh_time = lastlogtime;
	}
			
	//return 0=设置superCreator, 其他不使用
	int set_super_creator(CLogicMsg& msg, CLogicCreator& superCreator)
	{
		unsigned int msgCmd = msg.head()->cmdID;
		if(m_lua_map.find(msgCmd) != m_lua_map.end())
		{
			superCreator = CLogicCreator(&m_lua_handle); //千万不要new CLogicLUA 没的释放的
			return 0;
		}
		return -1;
	}

	bool luaSendMessage(USER_NAME & user, int cmd, std::string & msg) {
		if (m_toolkit.send_protobuf_s_msg(gDebugFlag, msg, cmd, user, MSG_QUEUE_ID_LOGIC) != 0) {
			LOG(LOG_ERROR, "send %d resp fail", cmd);
			return false;
		}
		return true;
	}
	
	virtual int hook_loop_end()
	{
		//检查淘汰和回写
		//非活跃的用户直接淘汰，没有写缓存的
		gDataCache.check_release(NULL);
		
		vector < unsigned int > vtimerID;
		vector < unsigned int > vtimerData;
		int ret = 0;
		
		if(gTheTimer.get_timer()->check_timer(vtimerID,  vtimerData) == 0)
		{
			for(unsigned int i=0; i< vtimerID.size(); ++i)
			{
				CLogicMsg msg(m_toolkit.readBuff, m_toolkit.BUFFLEN);
				msg.head()->queueID = CLogicMsg::QUEUE_ID_FOR_TIMER;
				msg.head()->desHandleID = 0;
				msg.head()->srcHandleID = vtimerID[i];
				msg.head()->srcServerID = m_serverID;
				msg.head()->desServerID = m_serverID;
				msg.head()->cmdID = CMD_LOGIC_CHECKONLINE_REQ;
				msg.head()->bodySize = sizeof(vtimerData[i]);
				memcpy(msg.body(), &(vtimerData[i]), sizeof(vtimerData[i]));
				
				if(m_useSuper && set_super_creator(msg, m_theSuper)==0)
					ret = m_pmanager->process_msg(msg, &m_theSuper);
				else
					ret = m_pmanager->process_msg(msg);
				if(ret != 0)
				{
					//木有啥事
				}
			}
		}
		else
		{
			LOG(LOG_ERROR, "online timer error %s", gTheTimer.get_timer()->m_err.errstrmsg);
		}
		{
			time_t t = time(NULL);
			if(last_notify_time + 10 < t)
			{
				last_notify_time = t;

				RsyncLogicStatus msg;
				msg.set_ip(g_logic_info.ip);
				msg.set_port(g_logic_info.port);
				for(unsigned int i = 0; i < g_logic_info.idx_list.size(); i++)
				{
					msg.add_idx(g_logic_info.idx_list[i]);
				}
				for(unsigned int i = 0; i < g_logic_info.centre_port_list.size(); i++)
                {
                    RsyncLogicStatus::CentreInfo t;
                    t.set_centre_ip(g_logic_info.centre_ip_list[i]);
                    t.set_centre_port(g_logic_info.centre_port_list[i]);
                    msg.add_centre_list()->CopyFrom(t);
                }
				msg.set_max_client(g_logic_info.max_client);
				msg.set_cur_client(gOnlineCache.get_map()->get_head()->curNodeNum);
				msg.set_version(g_logic_info.version);
				msg.set_max_reg(g_logic_info.max_reg);
				msg.set_cur_reg(g_logic_info.cur_reg);
				USER_NAME t_name;
				
				//LOG(LOG_INFO, "%s|send_log_to_gateway before send", user.str());
				if(m_toolkit.send_protobuf_msg(gDebugFlag, msg, CMD_NOTIFY_LOGIC_INFO_REQ,
					t_name, MSG_QUEUE_ID_GATEWAY) !=0)
				{
					LOG(LOG_ERROR, "CMD_NOTIFY_LOGIC_INFO_REQ send fail");
				}

				if(g_logic_info.global_httpcb_port != 0)
				{
					Rsync2GlobalCB msg1;
					msg1.set_port(g_logic_info.cb_port);
					for(unsigned int i = 0; i < g_logic_info.idx_list.size(); i++)
					{
						msg1.add_idx(g_logic_info.idx_list[i]);
					}
					//msg1.set_idx(g_logic_info.idx);
					msg1.set_globalcb_ip(g_logic_info.global_httpcb_ip);
					msg1.set_globalcb_port(g_logic_info.global_httpcb_port);
					if( !g_logic_info.global_httpcb_ip_2.empty() )
					{
						msg1.set_globalcb_ip_2(g_logic_info.global_httpcb_ip_2);
						msg1.set_globalcb_port_2(g_logic_info.global_httpcb_port_2);
					}
					if(m_toolkit.send_protobuf_msg(gDebugFlag, msg1, CMD_NOTIFY_GLOBALCB_REQ,
						t_name, MSG_QUEUE_ID_GATEWAY) !=0)
					{
						LOG(LOG_ERROR, "CMD_NOTIFY_GLOBAL_CB_REQ send fail");
					}
				}
			}
		}
		{
			time_t t = time(NULL);
			if(last_reflesh_time + 10 < t)
			{
				last_reflesh_time = t;
				lua_State *gl = g_lua_env.global_state;
				lua_getglobal(gl, "time_reflesh");
				if(lua_pcall(gl, 0, 0, 0) != 0)
				{
					LOG(LOG_ERROR, "func time_reflesh call error %s", lua_tostring(gl, -1));
					lua_pop(gl, 1);
				}
			}
		}
		{
			time_t t = time(NULL);
			if(g_ext_time + 60 < t)
			{
				LOG_STAT_ONLINE(gOnlineCache.get_map()->get_head()->curNodeNum, strutil::format("%05d", g_logic_info.idx_list[0]).c_str());
				g_ext_time = t;
			}
		}

		/*time_t nowTime = time(NULL);
		//世界BOSS
		{
			//gWBossMgr.update(nowTime);
		}
		if(loopnum++ > 1000)
		{
			loopnum -= 1000;
			int nowtime = time(NULL);
			if(nowtime - lastlogtime > 300)
			{
				lastlogtime = nowtime;
				string name="system";
				USER_NAME user;
				user.from_str(name);
				QQLogReq thereq;
				thereq.set_logtype(thereq.ONLINE_STAT);
				CDataControlSlot::send_log_to_gateway(user, thereq, &m_toolkit);
			}
		}*/

		return 0;
	}

	std::map<unsigned int, LUA_handle> &get_lua_map()
	{
		return m_lua_map;
	}

protected:
	int loopnum;
	time_t lastlogtime;
	time_t last_notify_time;
	time_t last_reflesh_time;	// 最近一次调用lua.time_reflesh的时间

	CLogicLUA m_lua_handle;
	map<unsigned int, LUA_handle> m_lua_map; // lua命令均在此注册
};

CLogicMainDriver driver; 

static void stophandle(int iSigNo)
{
	driver.stopFlag = 1;
	LOG(LOG_INFO, "recieve siganal %d, stop", iSigNo);
	LOG(LOG_ERROR, "recieve siganal %d, stop", iSigNo);
}

static void usr1handle(int iSigNo)
{
	gDebugFlag = (gDebugFlag+1)%2;
	cout << "debug=" << gDebugFlag << endl;
}

static void usr2handle(int iSigNo)
{
	gInfoDetail = (gInfoDetail+1)%2;
	cout << "info detail =" << gInfoDetail << endl;
}

class CLUAConfig
{
public:
	string lua_root_path;
	string lua_logic_path;
	string lua_config_path;
	string lua_svr_conf_path;
public:

	int readFromIni(CIniFile& ini, const char* sector="LUA")
	{
		char buf[128];
		ini.GetString(sector, "lua_root_path", "./lua/", buf, 128);
		if(buf[strlen(buf) - 1] != '/'
			&& buf[strlen(buf) - 1] != '\\')
		{
			buf[strlen(buf)] = '/';
			buf[strlen(buf) + 1] = 0;
		}
		lua_root_path = buf;
		ini.GetString(sector, "lua_logic_path", "logic/", buf, 128);
		if(buf[strlen(buf) - 1] != '/'
			&& buf[strlen(buf) - 1] != '\\')
		{
			buf[strlen(buf)] = '/';
			buf[strlen(buf) + 1] = 0;
		}
		lua_logic_path = lua_root_path + buf;
		ini.GetString(sector, "lua_config_path", "config/", buf, 128);
		if(buf[strlen(buf) - 1] != '/'
			&& buf[strlen(buf) - 1] != '\\')
		{
			buf[strlen(buf)] = '/';
			buf[strlen(buf) + 1] = 0;
		}
		lua_config_path = lua_root_path + buf;
		ini.GetString(sector, "lua_svr_conf_path", "../conf/", buf, 128);
		if(buf[strlen(buf) - 1] != '/'
			&& buf[strlen(buf) - 1] != '\\')
		{
			buf[strlen(buf)] = '/';
			buf[strlen(buf) + 1] = 0;
		}
		lua_svr_conf_path = buf;
		return 0;
	}
};

int init_lua_env(const CLUAConfig &conf)
{
	string lua_path = conf.lua_root_path + "?.lua;" 
		+ conf.lua_logic_path + "?.lua;"
		+ conf.lua_config_path + "?.lua;"
		+ conf.lua_svr_conf_path + "?.lua";
	string c_path = conf.lua_root_path + "?.so;"
		+ conf.lua_logic_path + "?.so";
	setenv("LUA_PATH", lua_path.c_str(), 1);
	setenv("LUA_CPATH", c_path.c_str(), 1);
	return 0;
}

int isOnline(lua_State *l)
{
	if (lua_gettop(l) != 1 || lua_type(l, 1) != LUA_TSTRING)
	{
		lua_pushnil(l);
		return 1;
	}
	size_t s_len;
	const char *str = lua_tolstring(l, -1, &s_len);

	USER_NAME user;
	user.from_str(str);
	
	bool isOnline = false;
	unsigned int theIdx;
	ONLINE_CACHE_UNIT* punit;
	if(gOnlineCache.getOnlineRef(user, theIdx, punit)==0)
	{
		isOnline = true;
	}

	lua_pushboolean(l, isOnline);

	return 1;
}
int activeSendMessage(lua_State *l)
{

	if (lua_gettop(l) != 3 || lua_type(l, 1) != LUA_TSTRING)
	{
		lua_pushnil(l);
		return 1;
	}

	size_t s_len;
	const char *str = lua_tolstring(l, 1, &s_len);

	USER_NAME user;
	user.from_str(str);

	int ext_cmd = lua_tointeger(l, 2);

	const char * s = lua_tolstring(l, 3, &s_len);
	std::string ext_resp;
	ext_resp.assign(s, s_len);

	driver.luaSendMessage(user, ext_cmd, ext_resp);

	return 0;
}


int main(int argc, char** argv)
{
	
	if(argc < 4)
	{
		cout << argv[0] << " mainlogic_config_ini pipe_conf_ini formatCache[0 or 1] xxooxx_data_path(default ../conf/xxooxx.bin)" << endl;
		return 0;
	}

	bool forceFormat = false;
	if(atoi(argv[3]) == 1)
	{
		forceFormat = true;
	}

	const char *conf_file = argv[1];
	CIniFile oIni(conf_file);
	if(!oIni.IsValid())
	{
		cout << "read ini " << conf_file << "fail" << endl;
		return 0;
	}
	//log必须首先开启，否则无法打日志
	LOG_CONFIG logConf(oIni, "MAIN_LOGIC");
	logConf.debug(cout);
	LOG_CONFIG_SET(logConf);
	cout << "log open=" << LOG_OPEN("main_logic",LOG_EXT_INFO) << " " << LOG_GET_ERRMSGSTRING << endl;

	// 先初始化lua环境，主要是设置LUA_PATH和LUA_CPATH
	CLUAConfig lua_config;
	lua_config.readFromIni(oIni);
	init_lua_env(lua_config);

	//neice 玩家list
	if(gneiceuser.init("../conf/neice.user", 20000)!=0)
	{
		cout << "gneiceuser.init(../conf/neice.user) fail" << endl;
		return 0;
	}

	//gm配置
	int gmenable = 0;
	int gmdenyhttp = 1;
	oIni.GetInt("GM", "ENABLE", 0, &gmenable);
	oIni.GetInt("GM", "DENY_HTTP", 1, &gmdenyhttp);
	if(gmenable)
	{
		char gmpath[256] = {0};
		if(oIni.GetString("GM", "XML", "", gmpath, sizeof(gmpath))!=0)
		{
			LOG(LOG_ERROR, "GM.XML not exist");
			return -1;
		}

		gGMXML = gmpath;
		cout << "GM enabled xml=" << gGMXML  << " , deny http = " << gmdenyhttp<< endl;
	}

	//cache配置
	DATA_CACHE_CONFIG cacheConfig;
	if(cacheConfig.read_from_ini(oIni, "CACHE")!=0)
	{
		cout << "cacheConfig.read_from_ini fail" << endl;
		return 0;
	}
	cacheConfig.debug(cout);

	
	int ret = gDataCache.init(cacheConfig, forceFormat, &gDebugFlag);
	if(ret != 0)
	{
		cout << "gDataCache init fail" << endl;
		return 0;
	}

	//online cache配置
	ONLINE_CACHE_CONFIG onlineCacheConfig;
	if(onlineCacheConfig.read_from_ini(oIni, "ONLINE_CACHE")!=0)
	{
		cout << "onlineCacheConfig.read_from_ini fail" << endl;
		return 0;
	}
	onlineCacheConfig.debug(cout);

	ret = gTheTimer.init(onlineCacheConfig.timershmkey, onlineCacheConfig.timerNum);
	if(ret != 0)
	{
		cout << "gTheTimer init fail" << endl;
		return 0;
	}

	ret = gOnlineCache.init(onlineCacheConfig);
	if(ret != 0)
	{
		cout << "gOnlineCache init fail" << endl;
		return 0;
	}

	//检查下
	if(oIni.GetInt("MAIN_LOGIC", "KICK_USER_TIME", 1800, &KICK_USER_TIME)!=0)
	{
	 	cout << "MAIN_LOGIC.KICK_USER_TIME not found" << endl;
		return 0;
	}
	CServerTool::server_param_safe(KICK_USER_TIME, 1, 99999, 1800);
	cout << "KICK_USER_TIME:" << KICK_USER_TIME << "s" <<  endl;
	
	gOnlineCache.cleanTimeoutNode(KICK_USER_TIME);

	//gDistribute配置
	ret = gDistribute.init(oIni, "DISTRIBUTE");
	if(ret != 0)
	{
		cout << "gDistribute init fail" << endl;
		return 0;
	}
	
	//配置server
	//pipe config
	CPIPEConfigInfo pipeconfig;
	const char *conf_pipe = argv[2];
	if(pipeconfig.set_config(conf_pipe)!= 0)
	{
		cout << "parse ini fail " << endl;
		return 0;
	}

	
	if(oIni.GetInt("MAIN_LOGIC", "GLOBE_PIPE_ID_LOGIC", 0, &MSG_QUEUE_ID_LOGIC)!=0)
	{
	 	cout << "MAIN_LOGIC.GLOBE_PIPE_ID_LOGIC not found" << endl;
		return 0;
	}
	cout << "GLOBE_PIPE_ID_LOGIC=" << MSG_QUEUE_ID_LOGIC << endl;

	if(oIni.GetInt("MAIN_LOGIC", "GLOBE_PIPE_ID_DB", 0, &MSG_QUEUE_ID_DB)!=0)
	{
	 	cout << "MAIN_LOGIC.GLOBE_PIPE_ID_DB not found" << endl;
		return 0;
	}
	cout << "GLOBE_PIPE_ID_DB=" << MSG_QUEUE_ID_DB << endl;

	if(oIni.GetInt("MAIN_LOGIC", "GLOBE_PIPE_ID_GATEWAY", 0, &MSG_QUEUE_ID_GATEWAY)!=0)
	{
	 	cout << "MAIN_LOGIC.GLOBE_PIPE_ID_GATEWAY not found" << endl;
		return 0;
	}
	cout << "GLOBE_PIPE_ID_GATEWAY=" << MSG_QUEUE_ID_GATEWAY << endl;

	if(oIni.GetInt("MAIN_LOGIC", "GLOBE_PIPE_ID_HTTPCB", 0, &MSG_QUEUE_ID_HTTPCB)!=0)
	{
	 	cout << "MAIN_LOGIC.GLOBE_PIPE_ID_HTTPCB not found" << endl;
		return 0;
	}
	cout << "GLOBE_PIPE_ID_HTTPCB=" << MSG_QUEUE_ID_HTTPCB << endl;

	if(oIni.GetInt("MAIN_LOGIC", "GLOBE_PIPE_ID_LOG", 0, &MSG_QUEUE_ID_LOG)!=0)
	{
		cout << "MAIN_LOGIC.GLOBE_PIPE_ID_LOG not found" << endl;
		return 0;
	}
	cout << "GLOBE_PIPE_ID_LOG=" << MSG_QUEUE_ID_LOG << endl;

	char tbuff[128];
	memset(tbuff, 0x0, sizeof(tbuff));
	if(oIni.GetString("LOGIC_INFO", "IP", "", tbuff, sizeof(tbuff))!=0)
	{
	 	cout << "LOGIC_INFO.IP not found" << endl;
		return 0;
	}
	cout << "LOGIC_IP=" << tbuff << endl;
	g_logic_info.ip = tbuff;

	
	if(oIni.GetInt("LOGIC_INFO", "PORT", 0, &g_logic_info.port)!=0)
	{
		cout << "LOGIC_INFO.PORT not found" << endl;
		return 0;
	}
	cout << "LOGIC_PORT=" << g_logic_info.port << endl;

	memset(tbuff, 0x0, sizeof(tbuff));
	if(oIni.GetString("LOGIC_INFO", "VERSION", "", tbuff, sizeof(tbuff))!=0)
	{
		cout << "LOGIC_INFO.VERSION not found" << endl;
		return 0;
	}
	cout << "LOGIC_VERSION=" << tbuff << endl;
	g_logic_info.version = tbuff;

	int sid_num = 0;
	if(oIni.GetInt("LOGIC_INFO", "SID_NUM", 0, &sid_num)!=0)
    {
    	int sid = 0;
		if(oIni.GetInt("LOGIC_INFO", "IDX", 0, &sid)!=0)
		{
			cout << "LOGIC_INFO.IDX not found" << endl;
			return 0;
		}
		cout << "LOGIC_IDX=" << sid << endl;
		g_logic_info.idx_list.push_back(sid);
	}
	else
	{
		int sid = 0;
		char idxbuff[32] = {0};
        for(int i = 0; i < sid_num; i++)
        {
            memset(idxbuff, 0, sizeof(idxbuff));
            snprintf(idxbuff, sizeof(idxbuff), "SID_%d", i+1);
            if(oIni.GetInt("LOGIC_INFO", idxbuff, 0, &sid)!=0)
            {
                cout << "LOGIC_INFO.IDXs not found" << endl;
                return 0;
            }
            cout << "LOGIC_IDX=" << sid << endl;
            g_logic_info.idx_list.push_back(sid);
        }
	}

	int centre_num = 0;
    if(oIni.GetInt("LOGIC_INFO", "CENTRE_NUM", 0, &centre_num)!=0)
    {
        memset(tbuff, 0x0, sizeof(tbuff));
        if(oIni.GetString("LOGIC_INFO", "CENTRE_IP", "", tbuff, sizeof(tbuff))!=0)
        {
            cout << "LOGIC_INFO.CENTRE_IP not found" << endl;
            return 0;
        }
        cout << "LOGIC_CENTRE_IP=" << tbuff << endl;
        g_logic_info.centre_ip_list.push_back(tbuff);
    
        int port = 0;
        if(oIni.GetInt("LOGIC_INFO", "CENTRE_PORT", 0, &port)!=0)
        {
            cout << "LOGIC_INFO.CENTRE_PORT not found" << endl;
            return 0;
        }
        cout << "LOGIC_CENTRE_PORT=" << port << endl;
        g_logic_info.centre_port_list.push_back(port);
    }
    else
    {
        char idxbuff[32] = {0};
        for(int i = 0; i < centre_num; i++)
        {
            memset(idxbuff, 0, sizeof(idxbuff));
            snprintf(idxbuff, sizeof(idxbuff), "CENTRE_IP_%d", i+1);
            memset(tbuff, 0x0, sizeof(tbuff));
            if(oIni.GetString("LOGIC_INFO", idxbuff, "", tbuff, sizeof(tbuff))!=0)
            {
                cout << "LOGIC_INFO.CENTRE_IP not found" << endl;
                return 0;
            }
            cout << "LOGIC_CENTRE_IP=" << tbuff << endl;
            g_logic_info.centre_ip_list.push_back(tbuff);
        
            int port = 0;
            memset(idxbuff, 0, sizeof(idxbuff));
            snprintf(idxbuff, sizeof(idxbuff), "CENTRE_PORT_%d", i+1);
            if(oIni.GetInt("LOGIC_INFO", idxbuff, 0, &port)!=0)
            {
                cout << "LOGIC_INFO.CENTRE_PORT not found" << endl;
                return 0;
            }
            cout << "LOGIC_CENTRE_PORT=" << port << endl;
            g_logic_info.centre_port_list.push_back(port);
        }
    }
	
	g_logic_info.max_client = onlineCacheConfig.nodeNum;

	oIni.GetInt("LOGIC_INFO", "UNRECHARGE", 0, &g_logic_info.unrecharge);
	cout << "LOGIC_UNRECHARGE=" << g_logic_info.unrecharge << endl;

	oIni.GetInt("LOGIC_INFO", "ANTI_CDKEY", 0, &g_logic_info.anti_cdkey);
	cout << "LOGIC_ANTI_CDKEY=" << g_logic_info.anti_cdkey << endl;

	oIni.GetInt("LOGIC_INFO", "ANTI_WEICHAT", 0, &g_logic_info.anti_weichat);
	cout << "LOGIC_ANTI_WEICHAT=" << g_logic_info.anti_weichat << endl;

	//global_httpcb_ip
	memset(tbuff, 0x0, sizeof(tbuff));
	if(oIni.GetString("LOGIC_INFO", "GLOBAL_CB_IP", "", tbuff, sizeof(tbuff))!=0)
	{
	 	cout << "LOGIC_INFO.GLOBAL_CB_IP not found" << endl;
		return 0;
	}
	cout << "GLOBAL_CB_IP=" << tbuff << endl;
	g_logic_info.global_httpcb_ip = tbuff;

	
	if(oIni.GetInt("LOGIC_INFO", "GLOBAL_CB_PORT", 0, &g_logic_info.global_httpcb_port)!=0)
	{
		cout << "LOGIC_INFO.GLOBAL_CB_PORT not found" << endl;
		return 0;
	}
	cout << "GLOBAL_CB_PORT=" << g_logic_info.global_httpcb_port << endl;

	//global_httpcb_ip_2
	if(oIni.GetString("LOGIC_INFO", "GLOBAL_CB_IP_2", "", tbuff, sizeof(tbuff))==0)
	{
		g_logic_info.global_httpcb_ip_2 = tbuff;
		oIni.GetInt("LOGIC_INFO", "GLOBAL_CB_PORT_2", g_logic_info.global_httpcb_port
			, &g_logic_info.global_httpcb_port_2);
		cout << "GLOBAL_CB_IP_2=" << tbuff << endl;
		cout << "GLOBAL_CB_PORT_2=" << g_logic_info.global_httpcb_port_2 << endl;
	}

	if(oIni.GetInt("LOGIC_INFO", "CB_PORT", 0, &g_logic_info.cb_port)!=0)
	{
		cout << "LOGIC_INFO.CB_PORT not found" << endl;
		return 0;
	}
	cout << "CB_PORT=" << g_logic_info.cb_port << endl;


	int old_ver_num = 0;
    if(oIni.GetInt("LOGIC_INFO", "OLD_VERSION_NUM", 0, &old_ver_num)==0)
    {
    	char idxbuff[32] = {0};
        for(int i = 0; i < old_ver_num; i++)
        {
            memset(idxbuff, 0, sizeof(idxbuff));
            snprintf(idxbuff, sizeof(idxbuff), "OLD_VERSION_%d", i+1);
            memset(tbuff, 0x0, sizeof(tbuff));
            if(oIni.GetString("LOGIC_INFO", idxbuff, "", tbuff, sizeof(tbuff))!=0)
            {
                cout << "LOGIC_INFO.OLD_VERSION_NUM not found" << endl;
                return 0;
            }
            cout << "OLD_VERSION_NUM=" << tbuff << endl;
            g_logic_info.old_versions.push_back(tbuff);
        }
    }
	g_logic_info.old_versions.push_back(g_logic_info.version);
	
	/*
	char sbuff[32] = {0};
	if(oIni.GetString("MAIN_LOGIC", "FLAG_SVRSET", "", sbuff, sizeof(sbuff)) != 0)
	{
	 	cout << "MAIN_LOGIC.FLAG_SVRSET not found" << endl;
		return 0;
	}
	if(CTcpSocket::str_to_addr(sbuff, FLAG_SVRSET) != 0)
	{
		LOG(LOG_ERROR, "MAIN_LOGIC.SVR_ID(%s) not valid", sbuff);
		return -1;
	}
	cout << "FLAG_SVRSET:" << sbuff << endl;
	*/

	if(oIni.GetInt("MAIN_LOGIC", "LOCK_PERIOD", 3, &LOCK_PERIOD)!=0)
	{
	 	cout << "MAIN_LOGIC.LOCK_PERIOD not found" << endl;
		return 0;
	}
	CServerTool::server_param_safe(LOCK_PERIOD, 1, 10000, 3);
	cout << "LOCK_PERIOD:" << LOCK_PERIOD << "s" <<  endl;

	if(oIni.GetInt("MAIN_LOGIC", "TIMEOUT_FOR_DB", 1, &TIMEOUT_FOR_DB)!=0)
	{
	 	cout << "MAIN_LOGIC.TIMEOUT_FOR_DB not found" << endl;
		return 0;
	}
	CServerTool::server_param_safe(TIMEOUT_FOR_DB, 1, 5, 1);
	cout << "TIMEOUT_FOR_DB:" << LOCK_PERIOD << "s" <<  endl;

	if(oIni.GetInt("MAIN_LOGIC", "CHECK_ONLINE_INTERVAL", 600, &CHECK_ONLINE_INTERVAL)!=0)
	{
	 	cout << "MAIN_LOGIC.CHECK_ONLINE_INTERVAL not found" << endl;
		return 0;
	}
	CServerTool::server_param_safe(CHECK_ONLINE_INTERVAL, 1, 99999, 600);
	cout << "CHECK_ONLINE_INTERVAL:" << CHECK_ONLINE_INTERVAL << "s" <<  endl;

	CDequePIPE pipeLogic;
	ret = pipeLogic.init(pipeconfig, MSG_QUEUE_ID_LOGIC, false);
	if(ret != 0)
	{
		cout << "pipeLogic.init " << pipeLogic.errmsg() << endl;
		return 0;
	}
	CMsgQueuePipe queuePipeLogic(pipeLogic, &gDebugFlag);

	CDequePIPE pipeDB;
	ret = pipeDB.init(pipeconfig, MSG_QUEUE_ID_DB, true);
	if(ret != 0)
	{
		cout << "pipeDB.init " << pipeDB.errmsg() << endl;
		return 0;
	}
	CMsgQueuePipe queuePipeDB(pipeDB, &gDebugFlag);

	CDequePIPE pipeHttpcb;
	ret = pipeHttpcb.init(pipeconfig, MSG_QUEUE_ID_HTTPCB, false);
	if(ret != 0)
	{
		cout << "pipeHttpcb.init " << pipeHttpcb.errmsg() << endl;
		return 0;
	}
	CMsgQueuePipe queuePipeHttpcb(pipeHttpcb, &gDebugFlag);

	CDequePIPE pipeGateWay;
	ret = pipeGateWay.init(pipeconfig, MSG_QUEUE_ID_GATEWAY, true);
	if(ret != 0)
	{
		cout << "pipeHttpcb.init " << pipeGateWay.errmsg() << endl;
		return 0;
	}
	CMsgQueuePipe queuePipeGateWay(pipeGateWay, &gDebugFlag);

	
	CDequePIPE pipeLog;
	ret = pipeLog.init(pipeconfig, MSG_QUEUE_ID_LOG, true);
	if(ret != 0)
	{
		cout << "pipeLog.init " << pipeLog.errmsg() << endl;
		return 0;
	}
	CMsgQueuePipe queuePipeLog(pipeLog, &gDebugFlag);


	if(driver.add_msg_queue(MSG_QUEUE_ID_LOGIC, &queuePipeLogic)!=0)
	{
		return 0;
	}
	
	if(driver.add_msg_queue(MSG_QUEUE_ID_DB, &queuePipeDB)!=0)
	{
		return 0;
	}

	if(driver.add_msg_queue(MSG_QUEUE_ID_HTTPCB, &queuePipeHttpcb)!=0)
	{
		return 0;
	}

	if(driver.add_msg_queue(MSG_QUEUE_ID_GATEWAY, &queuePipeGateWay)!=0)
	{
		return 0;
	}

	if(driver.add_msg_queue(MSG_QUEUE_ID_LOG, &queuePipeLog)!=0)
	{
		return 0;
	}

	MAIN_LOGIC_REGIST_CMD(CMD_LOGIN_REQ, CLogicLogin)
	MAIN_LOGIC_REGIST_CMD_UNIQ(CMD_LOGOUT_REQ, CLogicLogout)
	MAIN_LOGIC_REGIST_CMD(CMD_REGIST_REQ, CLogicRegist)
	MAIN_LOGIC_REGIST_CMD_UNIQ(CMD_HEART_BEAT_REQ, CLogicHeartBeat)
	MAIN_LOGIC_REGIST_CMD_UNIQ(CMD_USERLOG_REQ, CLogicHeartBeat)
	MAIN_LOGIC_REGIST_CMD_UNIQ(CMD_LOGIC_CHECKONLINE_REQ, CLogicLogout)
	MAIN_LOGIC_REGIST_CMD(CMD_CDKEY_REQ, CLogicCDKEY)
	
	//logichttpcb的请求只允许从MSG_QUEUE_ID_HTTPCB上来
	MAIN_LOGIC_REGIST_CMD(CMD_HTTPCB_ADDMONEY_REQ, CLogicHttpcb)
	MAIN_LOGIC_REGIST_CMD(CMD_GM_SEND_MAIL_REQ, CLogicGM)
	MAIN_LOGIC_REGIST_CMD(CMD_HTTPCB_GM_BLOCK_REQ, CLogicGM)
	MAIN_LOGIC_REGIST_CMD(CMD_GM_GET_USER_SNAP_REQ, CLogicGMUserSnap)
	//MAIN_LOGIC_REGIST_CMD(CMD_CHAT_REQ, CLogicChat)
	//MAIN_LOGIC_REGIST_CMD(CMD_GET_GROUP_REQ, CLogicTest)
	MAIN_LOGIC_REGIST_CMD(CMD_HTTPCB_BROADCAST_REQ, CLogicChat)
	driver.allow_cmd(CMD_HTTPCB_ADDMONEY_REQ, MSG_QUEUE_ID_HTTPCB);
	driver.allow_cmd(CMD_GM_SEND_MAIL_REQ, MSG_QUEUE_ID_HTTPCB);

	if(gmenable)
	{
		MAIN_LOGIC_REGIST_CMD(CMD_HTTPCB_GM_REQ, CLogicGM)
		if(gmdenyhttp)
		{
			driver.deny_cmd(CMD_HTTPCB_GM_REQ, MSG_QUEUE_ID_HTTPCB);
		}
	}

	
	//init diver
	CLogicDriverConfig configDriver;
	ret = configDriver.readFromIni(oIni);
	if(ret < 0)
	{
		cout << "CLogicDriverConfig readFromIni fail" << endl;
		return 0;
	}
	ret = driver.init(configDriver);
	if(ret != 0)
	{
		cout << "init fail" << endl;
		return 0;
	}
	// 同屏可见玩家管理器
	/*
	INMAP_CACHE_CONFIG inmap_cache_conf;
	if(inmap_cache_conf.read_from_ini(oIni, "CHANNEL_CACHE") != 0)
	{
		cout << "channel_cache_conf.read_from_ini fail" << endl;
		return 0;
	}
	inmap_cache_conf.debug(cout);
	ret = g_inmap_manager.init(inmap_cache_conf);
	if(ret != 0)
	{
		cout << "inmap_player_manager init fail" << endl;
		return 0;
	}
	driver.set_inmap_manager(&g_inmap_manager);
	g_inmap_manager.debug();
	*/

	//lock & daemon 这个要先执行，防止异常重启时lua被执行两次
	if(CServerTool::run_by_ini(&oIni, "MAIN_LOGIC")!=0)
	{
		cout << "run_by_ini  fail" << endl;
		return 0;
	}
	
	// init lua modules
	if(lua_load_all(
		(lua_config.lua_logic_path+"reg_cmd.lua").c_str(),
		(lua_config.lua_logic_path+"global.lua").c_str(),
		(lua_config.lua_logic_path+"special_logic.lua").c_str(),
		lua_config.lua_logic_path.c_str(),
		driver.get_lua_map()) != 0)
	{
		cout << "load lua fail" << endl;
		return 0;
	}

	lua_State *l = g_lua_env.global_state;
	if(lua_gettop(l) != 0)
	{
		LOG(LOG_ERROR, "%s|%d| call %s err: stack top is %u",__FILE__,__LINE__, "get_reg", lua_gettop(l));
		return 0;
	}
	lua_getglobal(l, "get_reg_num");
	if(lua_pcall(l, 0, 2, 0) != 0)
	{
		LOG(LOG_ERROR, "%s|%d| func %s, call error %s",__FILE__,__LINE__, "get_reg", lua_tostring(l, -1));
		lua_pop(l, 1);
		return 0;	// nick name err
	}
	g_logic_info.cur_reg = lua_tointeger(l, -2);
	g_logic_info.max_reg = lua_tointeger(l, -1);
	lua_pop(l, 2);
	//cout << "CUR_REG=" << g_logic_info.cur_reg << " , MAX_REG=" << g_logic_info.max_reg << endl;
	if( luaGlobal().init(l) )
	{
		cout << "luaGlobal.inited" << endl;
	}
	else
	{
		cout << "luaGlobal.init failed" << endl;
		return 0;
	}
	lua_register(l, "isOnline", isOnline);
	lua_register(l, "activeSendMessage", activeSendMessage);

	//lua_debug_cmd_map(driver.get_lua_map());
	
	/*CWorldBossMgrConfig wbossCfg;
	int resetTime = forceFormat?1:0;
	int resetBoss = forceFormat?1:0;
	wbossCfg.read_from_ini(oIni, "WORLD_BOSS", resetTime, resetBoss);
	if( !gWBossMgr.init(wbossCfg) )
	{
		cout << "gWBossMgr.init fail" << endl;
		return 0;
	}*/

	
	CServerTool::sighandle(SIGTERM, stophandle);
	CServerTool::sighandle(SIGUSR1, usr1handle);
	CServerTool::sighandle(SIGUSR2, usr2handle);

	//开始run吧
	cout << "main_loop=" << driver.main_loop(-1) << endl;
	lua_release_all();
	return 1;
}