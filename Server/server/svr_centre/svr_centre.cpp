#include <iostream>
#include <string>
#include "struct/common_def.h"
#include "net/tcpwrap.h"
#include "net/epoll_wrap.h"
#include "log/log.h"
#include "common/server_tool.h"
#include "common/packet_interface.h"
#include "common/queue_pipe.h"
#include "logic/msg.h"
#include "logic/toolkit.h"
#include "ini/ini_file.h"
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include "string/strutil.h"
#include <vector>
#include <map>
#include <fstream>
#include <sstream>
#include <time.h>
#include "common/mem_guard.h"
#include "mysql_wrap/mysql_wrap.h"
#include "string/simplejson.h"
#include "time/time_util.h"


/***
* 用来回调充值的httpsvr
*直接把http请求转成msg，丢给logic svr
*使用单独的通道跟logic svr通讯
*/

using namespace std;

int gDebug;

#define INI_SECTION_MAIN "SVR_CENTRE"

CToolkit gtoolkit;
char ghttpbuff[10240];
int g_noplatform = 0;
string g_broadcast;
string g_cdn;
int g_cid;


int httpresp(int code)
{
	char retbuf[128] = {0};
	int retlen = 0;

	if(code == 0)
		retlen = snprintf(retbuf, sizeof(retbuf), "{\"errno\":0,\"errmsg\":\"ok\"}");
	else if(code == -1)
		retlen = snprintf(retbuf, sizeof(retbuf), "{\"errno\":1,\"errmsg\":\"inner err\"}");
	else if(code == -3)
		retlen = snprintf(retbuf, sizeof(retbuf), "{\"errno\":1,\"errmsg\":\"param err\"}");
	else if(code == -6)
		retlen = snprintf(retbuf, sizeof(retbuf), "{\"errno\":1,\"errmsg\":\"httoken err\"}");
	else
		retlen = snprintf(retbuf, sizeof(retbuf), "{\"errno\":1,\"errmsg\":\"unknow err\"}");
	 
	return snprintf(ghttpbuff, sizeof(ghttpbuff), 
		"HTTP/1.1 200\r\nServer: Apache\r\nContent-Length: %d\r\nContent-Type: text/html\r\n"
		"Cache-Control: no-cache\r\nPragma: no-cache\r\n\r\n%s",
		retlen, retbuf);
}

int httpresp1(string s)
{	 
	return snprintf(ghttpbuff, sizeof(ghttpbuff), 
		"HTTP/1.1 200\r\nServer: Apache\r\nContent-Length: %d\r\nContent-Type: text/html\r\n"
		"Cache-Control: no-cache\r\nPragma: no-cache\r\n\r\n%s",
		(int)(s.length()), s.c_str());
}


/*
int httpstatus(int status, CEpollWrap* pepoll, int fd, int sessionID)
{
	int httplen = snprintf(ghttpbuff, sizeof(ghttpbuff), 
		"HTTP/1.1 %d\r\nServer: Apache\r\nContent-Length: %d\r\nContent-Type: text/html\r\n"
		"Cache-Control: no-cache\r\nPragma: no-cache\r\n\r\n",
		status, 0);
	if(pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
	{
		LOG(LOG_ERROR, "write_packet fail");
	}
	pepoll->close_fd(fd, sessionID);
	return 0;
}*/

class CMysqlConfig
{
public:
	int readLimitPerSecond; //每秒读请求限制
	int writeLimitPerSecond; //每秒写请求限制
	char mysqlSvrIP[32];
	unsigned int mysqlSvrPort;
	char mysqlUser[128];
	char mysqlPassword[128];
	char mysqlSock[128];
	char mysqlDB[128];
	int mysqlKeepAlive;
	int mysqltimeout;
	char table[128];
	int tab_num;

	CMysqlConfig()
	{
		readLimitPerSecond = 0;
		writeLimitPerSecond = 0;
		mysqlSvrIP[0] = 0;
		mysqlSvrPort = 0;
		mysqlUser[0] = 0;
		mysqlPassword[0] = 0;
		mysqlSock[0]=0;
		mysqlDB[0]=0;
		mysqlKeepAlive = 0;
		mysqltimeout = -1;
		table[0] = 0;
		tab_num = 0;
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
		os << "mysqlKeepAlive|" << mysqlKeepAlive << endl;
		os << "mysqltimeout|" << mysqltimeout << endl;
		os << "mysqlDB|" << mysqlDB << endl;
		os << "mysqlTAB|" << table << endl;
		os << "mysqlTABNUM|" << tab_num << endl;
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

		if(oIni.GetString(sectorName, "MYSQL_DBNAME", "", mysqlDB, sizeof(mysqlDB))!=0)
		{
			LOG(LOG_ERROR, "%s.MYSQL_DBNAME not found", sectorName);
			return -1;
		}

		oIni.GetString(sectorName, "MYSQL_TABLE", "", table, sizeof(table));
		oIni.GetInt(sectorName, "MYSQL_TABLE_NUM", 1, &tab_num);
		
		return 0;
	}
};


struct svr_info
{
	string ip;			//登录ip
	int port;			//登录端口
	string inner_ip;	//内部ip
	int inner_port;		//内部端口
	int max_client;		//最大在线人数
	int cur_client;		//当前在线人数
	string version;		//可登录的客户端版本
	int max_reg;		// 最大注册数
	int cur_reg;		// 当前注册数
	time_t last_active_time;	// 最近一次更新时间，超过1分钟就提示不在线
};

//可见性策略
struct visible_ploy
{
	string ploy_type;		//可见性策略，="always_visible"表示默认可以，="cond_visible"表示仅对条件可见，="cond_hidden"表示仅对条件不可见
	string vp_device_ploy;	//设备策略，"="表示等于设备，"!="表示不等于设备
	string vp_device;		//针对的设备类型
	string vp_version_ploy;	//版本策略，"="表示等于版本，"!="表示不等于版本，">"表示大于版本，“>=”大于等于版本
	string vp_version;		//针对的版本

	void debug(ostream& os) const
	{
		os << "visible_ploy{ ";
		os << "ploy_type:" << ploy_type;
		os << ", vp_device_ploy:" << vp_device_ploy;
		os << ", vp_device:" << vp_device;
		os << ", vp_version_ploy:" << vp_version_ploy;
		os << ", vp_version:" << vp_version;
		os << " }";
	}
};

struct name_info
{
	//string platform;
	string sid;			// 每个服对应一个实际的logic server
	string svr_name;
	int status;
	svr_info info;
	visible_ploy vp;	//可见性策略
	time_t open_time;	// 开服时间。如果0代表直接开，否则time(NULL)超过这个时间戳开
};

struct channel_info
{
	string channel_id;
	string broad_cast;
	int weichat;
	int recharge;
	int cdkey;
	int hongbao;
};

struct query_result
{
	int has_data;
	map<int,int> list;
	int last_login;
	unsigned int last_login_time;
};

class CSvrCentre;
class CSvrCentreAgent
{
private:
	CSvrCentre *m_host;
public:
	void set_host(CSvrCentre *host)
	{
		m_host = host;
	}
	int update_channel_info(const char *cid);
	int update_svr_info();
	int query_user(string &user_name, query_result &ret);
};

CSvrCentreAgent g_agent;


class CSvrCentreControl: public CControlInterface
{
public:
	CSvrCentreControl()
	{
		m_pepoll = NULL;
	}

	void set_epoll(CEpollWrap* pepoll)
	{
		m_pepoll = pepoll;
	}

	void set_ext_info(
		map<string, channel_info> * channel_list,
		map<string, name_info> * svr_list,
		vector<string>* ip_white_list)
	{
		m_channel_list = channel_list;
		m_svr_list = svr_list;
		m_ip_white_list = ip_white_list;
	}

	int parse_query_str(string& querystr, map<string, string>& nvmap)
	{
		strutil::Tokenizer tokentop(querystr, "&");
		while(tokentop.nextToken())
		{
			string nvpair = tokentop.getToken();
			strutil::Tokenizer nvtoken(nvpair, "=");
			
			string name;
			string value;
			if(nvtoken.nextToken())
			{
				name = strutil::trim(decode(nvtoken.getToken()));
			}
			else
			{
				return -1;
			}

			if(nvtoken.nextToken())
			{
				value = strutil::trim(decode(nvtoken.getToken()));
			}
			else
			{
				return -1;
			}

			nvmap[name] = value;
		}

		return 0;
	}

	string decode(const string& strSrc)
	{
		string strDest;
		int iSrcLength = strSrc.length();
		if (iSrcLength <= 0) return "";

		char ch;
		char ch1;
		char ch2;
		for (int i = 0; i < iSrcLength; i++)
		{
			switch (strSrc[i]) 
			{
				case '%':
					ch1 = CBinaryUtil::char_val(strSrc[i+1]);
					ch2 = CBinaryUtil::char_val(strSrc[i+2]);
					if(ch1 >=0 && ch2 >= 0)
					{	
						ch = (ch1 << 4) + ch2;
						i = i + 2;					
					}
					else 
						ch = strSrc[i];

					strDest += ch;
					break;
				case '+':
					ch = ' ';
					strDest += ch;
					break;
				default: 
					strDest += strSrc[i];
					break;
			}
		}

		return strDest;
	}

	bool check_ploy_condition(const visible_ploy &vp, const string &device, const string &version)
	{
		if( !vp.vp_device_ploy.empty() ) //设备策略
		{
			if( vp.vp_device_ploy == "=" && vp.vp_device != device ) //等于设备
			{
				return false;
			}
			else if( vp.vp_device_ploy == "!=" && vp.vp_device == device ) //不等于设备
			{
				return false;
			}
		}
		if( !vp.vp_version_ploy.empty() ) //版本策略
		{
			if( vp.vp_version_ploy == "!=" )
			{
				if( vp.vp_version == version )
				{
					return false;
				}
			}
			else
			{
				//这里判断正确的情况
				if( vp.vp_version_ploy.find('>') != string::npos && version.compare(vp.vp_version) > 0 )
				{
					return true;
				}
				if( vp.vp_version_ploy.find('<') != string::npos && version.compare(vp.vp_version) < 0 )
				{
					return true;
				}
				
				if( vp.vp_version_ploy.find('=') != string::npos && version.compare(vp.vp_version) == 0 )
				{
					return true;
				}
				return false;
			}
		}
		return true;
	}

	bool check_server_visible(const visible_ploy &vp, const string &device, const string &version)
	{
		if( vp.ploy_type.empty() || vp.ploy_type == "always_visible" ) //总是可见
		{
			return true;
		}
		stringstream sstr1;
		vp.debug(sstr1);
		LOG(LOG_DEBUG, "visible_ploy:%s device:%s version:%s", sstr1.str().c_str(), device.c_str(), version.c_str());
		if( vp.ploy_type == "cond_visible" ) //条件可见
		{
			if( !check_ploy_condition(vp, device, version) ) //是否满足条件
			{
				LOG(LOG_DEBUG, "cond_visible check_ploy_condition FALSE");
				return false;
			}
			LOG(LOG_DEBUG, "cond_visible check_ploy_condition TRUE");
		}
		else if( vp.ploy_type == "cond_hidden" ) //条件不可见可见
		{
			if( check_ploy_condition(vp, device, version) ) //是否满足条件
			{
				LOG(LOG_DEBUG, "cond_visible check_ploy_condition TRUE");
				return false;
			}
			LOG(LOG_DEBUG, "cond_visible check_ploy_condition FALSE");
		}
		return true;
	}

	virtual int pass_packet(int fd, unsigned long long sessionID, const char* packet, unsigned int packetLen) 
	{
		CEpollWrap::UN_SESSION_ID uSession;
		uSession.id = sessionID;
		if(gDebug)
		{
			LOG(LOG_DEBUG, "client(fd=%d,%s:%d,%d) pass_packet(len=%u)|%s", fd, CTcpSocket::addr_to_str(uSession.tcpaddr.ip).c_str(), uSession.tcpaddr.port, uSession.tcpaddr.seq, packetLen, packet);
		}

		//请求在一个包中完结
		//只关心第一行
		unsigned int i = 0;

		if(!(packet[i++] == 'G' && packet[i++] == 'E' && packet[i++] == 'T' && packet[i++] == ' '))
		{
			LOG(LOG_ERROR, "packet(len=%d) not start with GET ", packetLen);
			return -1;
		}

		int req_status = -1;
		int querypos = -1;
		if(packet[i] == '/' && packet[i + 1] == 'r' && packet[i + 2] == 'e' && packet[i + 3] == 'q' && packet[i + 4] == '?')
		{
			req_status = 0;
			i = i + 5;
		}
		else if(packet[i] == '/' && packet[i + 1] == 'i' && packet[i + 2] == 'n' && packet[i + 3] == 'n' && packet[i + 4] == '?')
		{
			req_status = 1;
			i = i + 5;
		}
		else if(packet[i] == '/' && packet[i + 1] == 's' && packet[i + 2] == 'e' && packet[i + 3] == 't' && packet[i + 4] == '?')
		{
			req_status = 2;
			i = i + 5;
		}
		else if (packet[i] == '/' && packet[i + 1] == 'g' && packet[i + 2] == 'l' && packet[i + 3] == '?')
		{
			req_status = 3;
			i = i + 5;
		}
		else if (packet[i] == '/' && packet[i + 1] == 's' && packet[i + 2] == 't' && packet[i + 3] == '?')
		{
			req_status = 4;
			i = i + 5;
		}
		else
		{
			LOG(LOG_ERROR, "packet(len=%d) req func is wrong", packetLen);
			int httplen = httpresp(-3);
			if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
			{
				LOG(LOG_ERROR, "write_packet fail");
			}
			return 1;
		}
		querypos = i;
		for(; i<packetLen; ++i)
		{
			//cout << "i=" << i << ", c[i]=" << packet[i] << "(" << int(packet[i]) << ")" << endl;
			if(packet[i]== '\r' || packet[i]=='\n' || packet[i]==' ')
			{
				break;
			}
		}

		if(i == packetLen)
		{
			LOG(LOG_ERROR, "packet(len=%d) \\r\\n not found", packetLen);
			int httplen = httpresp(-3);
			if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
			{
				LOG(LOG_ERROR, "write_packet fail");
			}
			return 1;
		}

		map<string, string> nvmap;
		map<string, string>::iterator it;
		int querylen = i-querypos + 1;
		if(querypos > 0 && querylen > 0)
		{
			string querystr(packet+querypos, querylen);
			
			if(parse_query_str(querystr, nvmap) != 0)
			{
				LOG(LOG_ERROR, "parse querystr(%s) fail", querystr.c_str());
				int httplen = httpresp(-3);
				if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
				{
					LOG(LOG_ERROR, "write_packet fail");
				}
				//m_pepoll->close_fd(fd, sessionID);
				return 1;
			}
		}
		if(req_status == 0)
		{//客户端查询
			string platform;
			string uid;
			string device = "ios";
			string version;
			//userid必须有
			it = nvmap.find("uid");
			if(it == nvmap.end())
			{//发公告
				it = nvmap.find("platform");
				if(it == nvmap.end())
				{
					LOG(LOG_ERROR, "platform not find");
					int httplen = httpresp(-3);
					if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
					{
						LOG(LOG_ERROR, "write_packet fail");
					}
					return 1;
				}
				platform = it->second;
				string broad;
				map<string, channel_info>::iterator cit = m_channel_list->find(platform);
				int httplen = 0;
				if(cit == m_channel_list->end())
					httplen = httpresp1("");
				else
					httplen = httpresp1(cit->second.broad_cast);
				
                if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
                {
                    LOG(LOG_ERROR, "write_packet fail");
                }
                return 1;
				
			}
			uid = it->second;
			if(uid == "")
			{
				LOG(LOG_ERROR, "uid is null");
				int httplen = httpresp(-3);
				if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
				{
					LOG(LOG_ERROR, "write_packet fail");
				}
				return 1;
			}

			it = nvmap.find("platform");
			if(it == nvmap.end())
			{
				LOG(LOG_ERROR, "platform not find");
				int httplen = httpresp(-3);
				if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
				{
					LOG(LOG_ERROR, "write_packet fail");
				}
				return 1;
			}
			platform = it->second;
			if(g_noplatform != 0)
				platform = "dream";
			LOG(LOG_INFO, "Request,%s", strutil::mapToStr(nvmap).c_str());
			it = nvmap.find("debug");
			int debug;
			if(it == nvmap.end())
			{									
				string sIPClient = CTcpSocket::addr_to_str(uSession.tcpaddr.ip);
				if (find(m_ip_white_list->begin(), m_ip_white_list->end(), sIPClient) == m_ip_white_list->end())
				{
					debug = 0;
				}
				else
				{
					debug = 1;
				}
			}
			else
			{
				debug = 1;
			}

			map<string, channel_info>::iterator cit = m_channel_list->find(platform);
			
			if(cit == m_channel_list->end())
			{
				LOG(LOG_ERROR, "platform not find");
				int httplen = httpresp(-3);
				if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
				{
					LOG(LOG_ERROR, "write_packet fail");
				}
				return 1;
			}

			//获取客户端的类型和版本
			it = nvmap.find("os");
			if(it != nvmap.end())
			{
				device = it->second;
			}
			it = nvmap.find("ver");
			if(it != nvmap.end())
			{
				version = it->second;
			}

			// 查询user在哪些服有角色
			query_result q_ret;
			q_ret.has_data = -1;
			g_agent.query_user(uid, q_ret);
			int rc_svr = 0;
			time_t cur_time = time(NULL);
			// 选择推荐服
			for(map<string, name_info>::iterator it = m_svr_list->begin(); it != m_svr_list->end(); it++)
			{
				name_info *t = &(it->second);
				if(t->status == -100 || t->status == 100 || t->status == -1)
					continue;
				if(t->open_time > 0 && t->open_time > cur_time)
					continue;
				svr_info *sinfo = &(t->info);
				if((sinfo->last_active_time + 60) < cur_time)
				{
					t->status = 2;
				}
				int st = t->status;
				if (st != 2)
				{
					if(sinfo->cur_reg >= sinfo->max_reg)
						continue;
					int max = sinfo->max_client;
					int cur = sinfo->cur_client;
					if(max * 0.9 >= cur)
					{
						rc_svr = atoi(t->sid.c_str());//取最新的非空闲服
						//break;
					}
				}
			}
			
			channel_info *ci = &(cit->second);
			stringstream sstream;
			sstream << "{\"errno\":0,\"server\":[";
			bool first_entry = true;
			for(map<string, name_info>::reverse_iterator it = m_svr_list->rbegin(); it != m_svr_list->rend(); it++)
			{
				name_info *t = &(it->second);
				LOG(LOG_DEBUG, "sid %s, open_time %lu, cur_time %lu, open %d ,debug %d,state=%d", t->sid.c_str(), t->open_time, cur_time, t->open_time > 0 && t->open_time > cur_time ? 0 : 1,debug, t->status);
				if(debug == 0 && (t->status == -100 || t->status == 100	|| (t->open_time > 0 && t->open_time > cur_time)))
					continue;

				//服务器可见性过滤
				if( !check_server_visible(t->vp, device, version) )
				{
					continue;
				}

				int svrid = atoi(it->first.c_str());
				string svr_name;
				//if (version.length() > 2 && t->info.version.length() > 2 && version.substr(2, 1).compare(t->info.version.substr(2, 1)) < 0)
				//{
				//	svr_name = "\u8acb\u81f3\u61c9\u7528\u5546\u5e97\u4e0b\u8f09\u6700\u7248";
				//}
				//else
				//{
					svr_name = t->svr_name;
				//}
				if(!first_entry)
					sstream << ",";
				sstream << "{\"id\":" << svrid << ",\"nm\":\"" << svr_name
					<< "\",\"st\":";
				int status = t->status;
				if (status == 100)
					status = 0;
				else if(status == -100)
					status = -1;
				if(status != 0 && status != 1)
				{
					sstream << 2 << ",\"ip\":\"1.1.1.1\",\"pt\":1,\"vn\":\"1.0.0\",\"hr\":0,\"rc\":0}";
				}
				else
				{
					svr_info *sinfo = &(t->info);
					if((sinfo->last_active_time + 60) < cur_time)
					{
						if(t->status != -100 && t->status != 100)
							t->status = 2;
					}
					int st = t->status;
					if (st != 2)
					{
						if(it == m_svr_list->rbegin())
						{//只对最新服判定繁忙状态
							int max = sinfo->max_client;
							int cur = sinfo->cur_client;
							int max_r = sinfo->max_reg;
							int cur_r = sinfo->cur_reg;
							if(max * 0.8 <= cur || cur_r >= 0.8 * max_r)
								st = 1;
							else
								st = 0;
						}
						else
						{//其他服直接判定为繁忙
							st = 1;
						}
					}
					
					sstream << st << ",";
					sstream << "\"ip\":\"" << sinfo->ip << "\",\"pt\":" << sinfo->port
						<< ",\"vn\":\"" << sinfo->version;
					if(q_ret.has_data != 0)
					{
						if(svrid == rc_svr)
							sstream << "\",\"hr\":0,\"rc\":1";
						else
							sstream << "\",\"hr\":0,\"rc\":0";
					}
					else
					{
						map<int,int>::iterator tit = q_ret.list.find(svrid);
						if(tit == q_ret.list.end())
							sstream << "\",\"hr\":0,";
						else
							sstream << "\",\"hr\":1,";
						if(svrid == q_ret.last_login)
							sstream << "\"rc\":1";
						else
							sstream << "\"rc\":0";
					}
					sstream << "}";
				}
				first_entry = false;
				
			}
			sstream << "],\"cdn\":\"" << g_cdn << "\""
				<< ",\"rc\":" << ci->recharge
				<< ",\"key\":" << (g_cid == 95 ? 0 : ci->cdkey)
				<< ",\"wc\":" << ci->weichat
				<< ",\"hb\":" << ci->hongbao
				<< "}";
			int httplen = httpresp1(sstream.str());
			if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
			{
				LOG(LOG_ERROR, "write_packet fail");
			}
			if(gDebug)
			{
				LOG(LOG_DEBUG, "%s", sstream.str().c_str());
			}
			return 1;
		}
		else if(req_status == 1)
		{//服务器数据更新
			//userid必须有
			it = nvmap.find("idx");
			if(it == nvmap.end())
			{
				LOG(LOG_ERROR, "idx not find");
				int httplen = httpresp(-3);
				if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
				{
					LOG(LOG_ERROR, "write_packet fail");
				}
				return 1;
			}
			string sid = it->second.c_str();
			svr_info *sinfo = NULL;
			name_info *ni = NULL;
			bool new_svr = false;
			map<string, name_info>::iterator sit = m_svr_list->find(sid);

			if(sit != m_svr_list->end())
			{
				ni = (&(sit->second));
				sinfo = &(ni->info);
				if(ni->status == -1 || ni->status == -100)
				{
					it = nvmap.find("ip");
					if(it == nvmap.end())
					{
						LOG(LOG_ERROR, "ip not find");
						int httplen = httpresp(-3);
						if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
						{
							LOG(LOG_ERROR, "write_packet fail");
						}
						return 1;
					}
					sinfo->ip = it->second;
					it = nvmap.find("port");
					if(it == nvmap.end())
					{
						LOG(LOG_ERROR, "port not find");
						int httplen = httpresp(-3);
						if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
						{
							LOG(LOG_ERROR, "write_packet fail");
						}
						return 1;
					}
					sinfo->port = atoi(it->second.c_str());
					it = nvmap.find("ver");
					if(it == nvmap.end())
					{
						LOG(LOG_ERROR, "ver not find");
						int httplen = httpresp(-3);
						if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
						{
							LOG(LOG_ERROR, "write_packet fail");
						}
						return 1;
					}
					sinfo->version = it->second.c_str();
					it = nvmap.find("max_client");
					if(it == nvmap.end())
					{
						LOG(LOG_ERROR, "max_client not find");
						int httplen = httpresp(-3);
						if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
						{
							LOG(LOG_ERROR, "write_packet fail");
						}
						return 1;
					}
					sinfo->max_client = atoi(it->second.c_str());
					new_svr = true;
				}
				it = nvmap.find("cur_client");
				if(it == nvmap.end())
				{
					LOG(LOG_ERROR, "cur_client not find");
					int httplen = httpresp(-3);
					if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
					{
						LOG(LOG_ERROR, "write_packet fail");
					}
					return 1;
				}
				sinfo->cur_client= atoi(it->second.c_str());

				it = nvmap.find("mr");
				if(it != nvmap.end())
				{
					sinfo->max_reg= atoi(it->second.c_str());
				}
				it = nvmap.find("cr");
				if(it != nvmap.end())
				{
					sinfo->cur_reg= atoi(it->second.c_str());
				}

				sinfo->last_active_time = time(NULL);
				if (ni->status == -100 || ni->status == 100)
					ni->status = 100;
				else if (ni->status == 4)
					ni->status = 4;
				else
					ni->status = 0;
			}
			else
			{
				LOG(LOG_ERROR, "add server %s err", sid.c_str());
				int httplen = httpresp(-3);
				if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
				{
					LOG(LOG_ERROR, "write_packet fail");
				}
				return 1;
			}
		}
		else if(req_status == 2)
		{//通知刷新
			string broadcast;
			//userid必须有
			it = nvmap.find("cid");
			if(it != nvmap.end())
			{
				string cid = it->second;
				if(cid == "-1")
					g_agent.update_channel_info(NULL);
				else
					g_agent.update_channel_info(cid.c_str());
			}
			it = nvmap.find("sid");
			
			if(it != nvmap.end())
			{
				LOG(LOG_DEBUG, "sid:%s update_svr_info.", it->second.c_str());
				g_agent.update_svr_info();
			}

			int httplen = httpresp(0);
			if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
			{
				LOG(LOG_ERROR, "write_packet fail");
			}
			return 1;
		}
		else if (req_status == 3)
		{//更改公告

			it = nvmap.find("platform");
			if (it == nvmap.end())
			{
				LOG(LOG_ERROR, "idx not find");
				int httplen = httpresp(-3);
				if (m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
				{
					LOG(LOG_ERROR, "write_packet fail");
				}
				return 1;
			}

			map<string, channel_info>::iterator cit = m_channel_list->find(it->second.c_str());
			it = nvmap.find("broadcast");
			if (it == nvmap.end())
			{
				LOG(LOG_ERROR, "idx not find");
				int httplen = httpresp(-3);
				if (m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
				{
					LOG(LOG_ERROR, "write_packet fail");
				}
				return 1;
			}
			if (cit != m_channel_list->end())
			{
				cit->second.broad_cast = it->second;
			}

		}
		else if (req_status == 4)
		{
			it = nvmap.find("idx");
			if (it == nvmap.end())
			{
				LOG(LOG_ERROR, "idx not find");
				int httplen = httpresp(-3);
				if (m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
				{
					LOG(LOG_ERROR, "write_packet fail");
				}
				return 1;
			}
			string sid = it->second.c_str();


			it = nvmap.find("state");
			if (it == nvmap.end())
			{
				int httplen = httpresp(-3);
				if (m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
				{
					LOG(LOG_ERROR, "write_packet fail");
				}
				return 1;
			}
			name_info *ni = NULL;
			map<string, name_info>::iterator sit = m_svr_list->find(sid);
			if (sit != m_svr_list->end())
			{
				ni = (&(sit->second));
				int state = atoi(it->second.c_str());
				LOG(LOG_DEBUG, "setstate=%d", state);
				if (state == 4)
					ni->status = state;
				else if (state == 0)
					ni->status = 100;
				else
					ni->status = 0;
			}
			
		}
		
		return 0;
	}
	
	virtual void on_connect(int fd, unsigned long long sessionID) 
	{

		if(gDebug)
		{
			CEpollWrap::UN_SESSION_ID uSession;
			uSession.id = sessionID;
			LOG(LOG_DEBUG, "client(fd=%d,%s:%d,%d) connect", fd, CTcpSocket::addr_to_str(uSession.tcpaddr.ip).c_str(), uSession.tcpaddr.port, uSession.tcpaddr.seq);
		}
	}
	
	virtual void on_close(int fd, unsigned long long sessionID) 	
	{
		if(gDebug)
		{
			CEpollWrap::UN_SESSION_ID uSession;
			uSession.id = sessionID;
			LOG(LOG_DEBUG, "client(fd=%d,%s:%d,%d) closed", fd, CTcpSocket::addr_to_str(uSession.tcpaddr.ip).c_str(), uSession.tcpaddr.port, uSession.tcpaddr.seq);
		}
	}

protected:
	CEpollWrap* m_pepoll;

	//map<string, map<string, name_info *> > *m_platform_list;
	//map<string, name_info> *m_name_list;
	//map<int, svr_info> *m_svr_list;
	//map<string, string> *m_platform_broad;

	map<string, channel_info> *m_channel_list;
	map<string, name_info> *m_svr_list;
	vector<string> *m_ip_white_list;
};

class CSvrCentre
{
#define START_QUERY_TIME gettimeofday(&start_t, NULL);
#define END_QUERY_TIME gettimeofday(&end_t, NULL); \
		m_interval = (end_t.tv_sec - start_t.tv_sec)*1000 + (end_t.tv_usec - start_t.tv_usec)/1000;
			

public:
	struct CONFIG
	{
		string ip;
		unsigned short port;
		unsigned int maxclients;
		unsigned int epollTimeoutUs; //微妙级别
		LOG_CONFIG logConf;

		CONFIG()
		{
			maxclients = 1000;
			epollTimeoutUs = 1000;
		}

		void debug(ostream& os)
		{
			os << "CConnect::CONFIG{" << endl;
			os << "ip|" << ip << endl;
			os << "port|" << port << endl;
			os << "maxclients|" << maxclients << endl;
			os << "epollTimeoutUs|" << epollTimeoutUs << endl;
			os << "} end CONFIG" << endl;
		}
	};

	CSvrCentre()
	{
		m_pepoll = NULL;
		m_inited = false;
	}

	~CSvrCentre()
	{
		if(m_pepoll)
		{
			delete m_pepoll;
			m_pepoll = NULL;
		}
		m_inited = false;
	}

	int start(CONFIG& conf)
	{
		if(m_inited)
			return 0;

		//当前时间变量
		timeval timenow;
		gettimeofday(&timenow, NULL);

		m_pepoll = new CEpollWrap(&m_raw, &m_control, &timenow);
		if(m_pepoll == NULL)
		{
			LOG(LOG_ERROR,"%s", "new CEpollWrap() fail");
			return -1;
		}

		int ret = CServerTool::ensure_max_fds(conf.maxclients);
		if(ret != 0)
		{
			LOG(LOG_ERROR,"ensure_max_fds(%u) fail %d %s", conf.maxclients, errno, strerror(errno));
			return -1;
		}

		//request很小，钉死4096字节
		m_pepoll->set_pack_buff_size(4096);
		
		ret = m_pepoll->create(conf.maxclients, false, true);
		if(ret !=0)
		{
			LOG(LOG_ERROR,"m_pepoll->create=%d %s", ret, m_pepoll->errmsg());
			return -1;
		}

		m_pepoll->set_session_limit(0,0,0,3);

		ret = m_pepoll->add_listen(conf.ip, conf.port);
		if(ret !=0)
		{
			LOG(LOG_ERROR,"m_pepoll->add_listen=%d %s", ret, m_pepoll->errmsg());
			return -1;
		}

		unsigned int time_sec = conf.epollTimeoutUs/1000000;
		unsigned int time_microsec = conf.epollTimeoutUs%1000000;

		m_control.set_epoll(m_pepoll);
		m_control.set_ext_info(&m_channel_list, &m_svr_list, &m_ip_white_list);

		CLogicMsg respMsg(gtoolkit.readBuff, sizeof(gtoolkit.readBuff));
		while(!STOP_FLAG)
		{
			//更新下时间
			gettimeofday(&timenow,NULL);
			//epoll
			ret = m_pepoll->do_poll(time_sec, time_microsec);
			if(ret !=0)
			{
				LOG(LOG_ERROR,"m_pepoll->do_poll=%d %s", ret, m_pepoll->errmsg());
			}
		}
		return 0;
	}

	void set_mysql_conf(CMysqlConfig *mysql_conf)
	{
		m_mysql_conf = mysql_conf;
	}

	void set_mysql_user_area(CMysqlConfig *mysql_conf, CMysqlConfig *mysql_conf2 = NULL)
	{
		m_mysql_user_area = mysql_conf;
		m_mysql_user_area2 = mysql_conf2;
	}

	int update_channel_info(const char *cid)
	{
		MysqlDB theDB;
		if(theDB.Connect(m_mysql_conf->mysqlSvrIP, m_mysql_conf->mysqlUser, m_mysql_conf->mysqlPassword,
				m_mysql_conf->mysqlDB, m_mysql_conf->mysqlSvrPort) != 0)
		{
			LOG(LOG_ERROR, "db Connect fail %s", theDB.GetErr());
			return -1;
		}

		string tsql = "set names utf8";
		theDB.Query(tsql.c_str(), tsql.length());
		
		char sql[256];
		MysqlResult result;
		if(cid)
			snprintf(sql, sizeof(sql), "select channel_id,broad_cast,recharge,weichat,cdkey,hongbao from tab_gl_channel where channel_id = '%s'",
				cid);
		else
			snprintf(sql, sizeof(sql), "select channel_id,broad_cast,recharge,weichat,cdkey,hongbao from tab_gl_channel");
		int ret = do_query(&theDB, sql, result);
		if(ret != 0)
			return ret;
		int row_num = result.RowNum();
		if(row_num == 0)
		{
			return -1;
		}
		for (int i = 0; i < row_num; i++)
		{
			fill_channel_info(result);
		}
		return 0;
	}

	int update_svr_info(const char *sid)
	{
		MysqlDB theDB;
		if(theDB.Connect(m_mysql_conf->mysqlSvrIP, m_mysql_conf->mysqlUser, m_mysql_conf->mysqlPassword,
				m_mysql_conf->mysqlDB, m_mysql_conf->mysqlSvrPort) != 0)
		{
			LOG(LOG_ERROR, "db Connect fail %s", theDB.GetErr());
			return -1;
		}
		string tsql = "set names utf8";
		theDB.Query(tsql.c_str(), tsql.length());

		char sql[256];
		MysqlResult result;
		/*if(sid)
			snprintf(sql, sizeof(sql), "select svr_id,svr_name from tab_gl_svr where center_id = %d and svr_id = '%s'",
				g_cid, sid);
		else*/
		snprintf(sql, sizeof(sql), "SELECT server_id,name,status,real_server,server_options FROM T_SERVER WHERE site_id = %d", g_cid);
		
		int ret = do_query(&theDB, sql, result);
		if(ret != 0)
			return ret;
		int row_num = result.RowNum();
		m_svr_list.clear();

		if(row_num == 0)
		{
			return -1;
		}
		
		for (int i = 0; i < row_num; i++)
		{
			fill_svr_info(result);
		}
		return 0;
	}

	int query_user_from(MysqlDB &m_db, CMysqlConfig *m_mysql_user_area, string &user_name, query_result &ret)
	{
		if(!m_db.IsConnected())
		{
			m_db.SetTimeOut(m_mysql_user_area->mysqltimeout);
			if(m_db.Connect(m_mysql_user_area->mysqlSvrIP, m_mysql_user_area->mysqlUser, m_mysql_user_area->mysqlPassword,
				m_mysql_user_area->mysqlDB, m_mysql_user_area->mysqlSvrPort, true, m_mysql_user_area->mysqlSock) != 0)
			{
				LOG(LOG_ERROR, "db Connect fail %s", m_db.GetErr());
				return -1;
			}
			string tsql = "set names utf8";
			m_db.Query(tsql.c_str(), tsql.length());
		}
		
		char sql[256];
		MysqlResult result;
		snprintf(sql, sizeof(sql), "select last_login_areaid,regist_areaids,all_login_areaids from USER_AREA where acc = '%s'", user_name.c_str());
		int qret = do_query(&m_db, sql, result);
		
		if(qret != 0)
		{
			return qret;
		}
		int row_num = result.RowNum();
		if(row_num == 0)
		{
			return -1;
		}

		char **rcd = result.FetchNext();
		if(rcd == NULL)
		{
			return -1;
		}
		//char* vol;
		unsigned long * lengthArray;
		int lengthNum; 
		result.FieldLengthArray(lengthArray, lengthNum);
		if (lengthNum != 3)
			return -1;
		int last_login = 0;	// 记录的最近登录服
		unsigned last_login_time = 0;
		int last_svr = 0;	// 如果最近登录服没找到就用这个最后注册服
		int find_svr = 0;	// 最近登录服是否找到。找到就用
		
		last_login = atoi(rcd[0]);

		//if(rcd[2] == NULL)
			//LOG(LOG_DEBUG, "all_login_areaids, NULL");
		//else
			//LOG(LOG_DEBUG, "all_login_areaids, %s", rcd[2]);
		strutil::Tokenizer t(rcd[1], ",");
		while(t.nextToken())
		{
			int ti = atoi(t.getToken().c_str());
			ret.list[ti] = 1;
			last_svr = ti;
			if (ti == ret.last_login)
				find_svr = 1;
		}
		if(rcd[2] != NULL)
		{
			strutil::Tokenizer t(rcd[2], ",");
			
			while(t.nextToken())
			{
				string ti = t.getToken().c_str();

				size_t posi = ti.find_first_of("-");
				if(posi == string::npos)
					continue;	// 格式错误
				int sid = atoi(ti.substr(0, posi).c_str());
				unsigned int time = atoi(ti.substr(posi+1).c_str());
				if(sid == 0 || time == 0)
					continue;
				if(time >= last_login_time)
				{
					last_login = sid;
					last_login_time = time;
					find_svr = 1;
				}
				//string req_v12 = m_req.version().substr(0, m_req.version().find_last_of("."));
		
				//last_svr = ti;
				//if (ti == ret.last_login)
				//	find_svr = 1;
				//ret.list[ti] = 1;
			}
		}
		if(find_svr == 0)
			last_login = last_svr;
		if(last_login_time > 0 && last_login_time > ret.last_login_time)
		{
			ret.last_login = last_login;
			ret.last_login_time = last_login_time;
		}
		else if(ret.last_login_time == 0)
		{
			ret.last_login = last_login;
			ret.last_login_time = last_login_time;
		}
		ret.has_data = 0;		
		return 0;
	}

	int query_user(string &user_name, query_result & ret)
	{
		ret.has_data = -1;
		ret.last_login_time = 0;
		query_user_from(m_db, m_mysql_user_area, user_name, ret);
		if(m_mysql_user_area2 != NULL)
		{
			query_user_from(m_db2, m_mysql_user_area2, user_name, ret);
		}
		return 0;
	}
	
	void set_ip_white(const string& sIPWhite)
	{
		m_ip_white_list = strutil::split(sIPWhite, ",");
	}
public:
	static int STOP_FLAG;
private:
	int fill_channel_info(MysqlResult &result)
	{
		char **rcd = result.FetchNext();
		if(rcd == NULL)
			return 0;
		char* vol;
		unsigned long * lengthArray;
		int lengthNum; 
		result.FieldLengthArray(lengthArray, lengthNum);
		char field_name[128];
		string cid;
		string broad_cast;
		int recharge = 0;
		int weichat = 0;
		int cdkey = 0;
		int hongbao = 0;
		
		for (int i = 0; i < lengthNum; i++)
		{
			int ret = result.FieldInfo(i, field_name, sizeof(field_name), NULL);
			if (ret != 0)
			{
				LOG(LOG_ERROR,"some err");
			}
			vol = rcd[i];
			if(gDebug)
				LOG(LOG_DEBUG, "field%d:|%s|%s|", i,field_name, vol);
			string sfield = field_name;
			if(sfield == "channel_id")
				cid = vol;
			else if(sfield == "broad_cast")
				broad_cast = vol;
			else if(sfield == "recharge")
				recharge = atoi(vol);
			else if(sfield == "weichat")
				weichat = atoi(vol);
			else if(sfield == "hongbao")
				hongbao = atoi(vol);
			else if(sfield == "cdkey")
				cdkey = atoi(vol);
			
		}
		
		map<string, channel_info>::iterator it = m_channel_list.find(cid);
		if(it == m_channel_list.end())
		{
			channel_info ci;
			ci.broad_cast = broad_cast;
			ci.recharge = recharge;
			ci.weichat = weichat;
			ci.cdkey = cdkey;
			ci.hongbao = hongbao;
			m_channel_list.insert(pair<string, channel_info>(cid, ci));
		}
		else
		{
			channel_info * ci = (channel_info *)(&(it->second));
			ci->broad_cast = broad_cast;
			ci->recharge = recharge;
			ci->weichat = weichat;
			ci->cdkey = cdkey;
			ci->hongbao = hongbao;
		}
		
		return 0;
	}

	int fill_svr_info(MysqlResult &result)
	{
		char **rcd = result.FetchNext();
		if(rcd == NULL)
			return 0;
		char* vol;
		unsigned long * lengthArray;
		int lengthNum; 
		result.FieldLengthArray(lengthArray, lengthNum);
		char field_name[128];
		string sid;
		string s_name;
		int status = -1;
		string real_sid;
		//string options;
		time_t open_time = 0;
		visible_ploy visiblePloy;//可见性策略
		for (int i = 0; i < lengthNum; i++)
		{
			int ret = result.FieldInfo(i, field_name, sizeof(field_name), NULL);
			if (ret != 0)
			{
				LOG(LOG_ERROR,"some err");
			}
			vol = rcd[i];
			if(gDebug)
				LOG(LOG_DEBUG, "field%d:|%s|%s|", i,field_name, vol);
			string sfield = field_name;
			if(sfield == "server_id")
				sid = vol;
			else if(sfield == "name")
				s_name = vol;
			else if(sfield == "status")
				status = atoi(vol);
			else if(sfield == "real_server")
				real_sid = vol;
			else if(sfield == "server_options")
			{
				if(vol != NULL)
				{
					string options = vol;
					CSimpleJSON objjson;
					if(objjson.parse(options)!=0)
					{
						LOG(LOG_ERROR, "parse json fail|%s", options.c_str());
					}
					else
					{
						string tm;
						if(!objjson.get("openTime", tm))
						{
							LOG(LOG_ERROR, "no openTime|%s", options.c_str());
						}
						else
						{
							time_t ttm = CTimeUtil::FromTimeString(tm.c_str());
							LOG(LOG_DEBUG, "%s, %lu", tm.c_str(), ttm);
							open_time = ttm;
						}

						if(objjson.get("visiblePloy", visiblePloy.ploy_type))
						{
							if(objjson.get("vpDevicePloy", visiblePloy.vp_device_ploy))
							{
								if( !objjson.get("vpDevice", visiblePloy.vp_device) )
								{
									LOG(LOG_ERROR, "no vpDevice|%s", options.c_str());
								}
							}
							if(objjson.get("vpVersionPloy", visiblePloy.vp_version_ploy))
							{
								if( !objjson.get("vpVersion", visiblePloy.vp_version) )
								{
									LOG(LOG_ERROR, "no vpVersion|%s", options.c_str());
								}
							}
						}
						stringstream sstr1;
						visiblePloy.debug(sstr1);
						LOG(LOG_DEBUG, "serverID:%s, visiblePloy=%s", sid.c_str(), sstr1.str().c_str());
					}
				}
			}
		}
		if(status == 1)
			status = -1;		// 这个服现在是开启的
		else
			status = -100;		// 这个服现在是关闭的
		if(atoi(real_sid.c_str()) == 0)
			real_sid = sid;


		map<string, name_info>::iterator it = m_svr_list.find(real_sid);
		if(it == m_svr_list.end())
		{
			name_info ni;
			ni.sid = sid;
			ni.svr_name = s_name;
			ni.status = status;
			ni.open_time = open_time;
			ni.vp = visiblePloy;
			m_svr_list.insert(pair<string, name_info>(real_sid, ni));
		}
		else
		{
			it->second.vp = visiblePloy; //更新可见习信息
		}
		
		return 0;
	}

	int do_query(MysqlDB * theDB, string sql, MysqlResult &result)
	{
		CMemGuard escapeMem;
		char* escapeSql;
		unsigned long escapeSqlLen;

		const char* data = sql.c_str();
		unsigned long dataLen = sql.length();

		std::string realSql;
		
		theDB->Escape(data, dataLen, escapeSql, escapeSqlLen);
		escapeMem.add(escapeSql);
		realSql.assign(escapeSql, escapeSqlLen);
		
		strutil::replaceAll(realSql, "\\'", "'");
		
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
			return -1;
		}
		END_QUERY_TIME
		if(m_interval > 10)
		{
			LOG(LOG_ERROR, "QUERY|SLOW|%d", m_interval);
		}
		result.SetAffectRowNum(affectedRows);

		if(gDebug)
			LOG(LOG_DEBUG, "query ok| row=%d", result.RowNum());
		return 0;
	}

protected:
	CEpollWrap* m_pepoll;
	bool m_inited;
	CRawPackInterface m_raw;
	CSvrCentreControl m_control;

	CMysqlConfig *m_mysql_conf;
	CMysqlConfig *m_mysql_user_area;
	CMysqlConfig *m_mysql_user_area2;
	
	MysqlDB m_db;
	MysqlDB m_db2;
	//map<string, map<string, name_info *> > m_platform_list;//各个平台的namelist
	//map<string, name_info> m_name_list;//完整的namelist
	//map<int, svr_info> m_svr_list;
	//map<string, string> m_platform_broadcast;

	map<string, channel_info> m_channel_list;
	map<string, name_info> m_svr_list;
	vector<string> m_ip_white_list;
	int cid;
	timeval start_t;
	timeval end_t;
	int m_interval;
};

int CSvrCentreAgent::update_channel_info(const char *cid)
{
	return m_host->update_channel_info(cid);
}
int CSvrCentreAgent::update_svr_info()
{
	return m_host->update_svr_info(NULL);
}

int CSvrCentreAgent::query_user(string &user_name, query_result &ret)
{
	return m_host->query_user(user_name, ret);
}


int CSvrCentre::STOP_FLAG = 0;

static void stophandle(int iSigNo)
{
	CSvrCentre::STOP_FLAG = 1;
	LOG(LOG_INFO, "recieve siganal %d, stop",  iSigNo);
	LOG(LOG_ERROR, "recieve siganal %d, stop",  iSigNo);
}

static void usr1handle(int iSigNo)
{
	gDebug = (gDebug+1)%2;
	cout << INI_SECTION_MAIN" debug=" << gDebug << endl;
}

int main(int argc, char** argv)
{
	if(argc < 2)
	{
		cout << argv[0] << " svr_centre_config_ini" << endl;
		return 0;
	}

	CSvrCentre svr_centre;
	g_agent.set_host(&svr_centre);
	CSvrCentre::CONFIG config;

	CIniFile oIni(argv[1]);
	if(!oIni.IsValid())
	{
		cout << "read ini " << argv[1] << " fail" << endl;
		return 0;
	}

	char ip[64] = {0}; 
	int epollTimeoutUs = 0;
	int port = 0;
	int cid = 0;
	char cdn[256] = {0};

	//open log
	config.logConf.read_from_ini(oIni, INI_SECTION_MAIN);	
	LOG_CONFIG_SET(config.logConf);
	cout << "log open=" << LOG_OPEN_DEFAULT(NULL) << " " << LOG_GET_ERRMSGSTRING << endl;

	if( oIni.GetString(INI_SECTION_MAIN, "SERVER_IP", "", ip, sizeof(ip)) != 0)
	{
		cout << INI_SECTION_MAIN".SERVER_IP not found" << endl;
		return 0;
	}

	if(oIni.GetInt(INI_SECTION_MAIN, "SERVER_PORT", 0,&port) != 0)
	{
		cout << INI_SECTION_MAIN".SERVER_PORT not found" << endl;
		return 0;
	}

	if(oIni.GetInt(INI_SECTION_MAIN, "CENTER_ID", 0,&cid) != 0)
	{
		cout << INI_SECTION_MAIN".CENTER_ID not found" << endl;
		return 0;
	}

	oIni.GetInt(INI_SECTION_MAIN, "EPOLL_TIMEOUT_US", 1000,&epollTimeoutUs);
	config.ip = ip;
	config.port = port;
	config.epollTimeoutUs = epollTimeoutUs; //1ms
	g_cid = cid;

	oIni.GetInt(INI_SECTION_MAIN, "MAX_CLIENTS",  1000,&(config.maxclients));

	oIni.GetInt(INI_SECTION_MAIN, "NOPLATFORM",  0,&g_noplatform);

	if( oIni.GetString(INI_SECTION_MAIN, "CDN", "", cdn, sizeof(cdn)) != 0)
	{
		cout << INI_SECTION_MAIN".CDN not found" << endl;
		return 0;
	}
	g_cdn = cdn;

	char szIPWhite[256] = {0};
	oIni.GetString(INI_SECTION_MAIN, "IP_WHITE", "", szIPWhite, sizeof(szIPWhite));
	svr_centre.set_ip_white(szIPWhite);
	
	config.debug(cout);
	ifstream ibroadcast("conf/broadcast");
	if(ibroadcast)
	{
		ibroadcast >> g_broadcast;
		ibroadcast.close();
	}

	CMysqlConfig mysqlConf;
	if( mysqlConf.read_from_ini(oIni, "MYSQL") != 0 )
	{
		cout << "mysqlConf.read_from_ini failed" << endl;
		return 0;
	}
	mysqlConf.debug(cout);
	svr_centre.set_mysql_conf(&mysqlConf);

	CMysqlConfig mysql_user_area;
	if( mysql_user_area.read_from_ini(oIni, "USER_AREA") != 0 )
	{
		cout << "mysql_user_area.read_from_ini failed" << endl;
		return 0;
	}

	bool has_user_area2 = false;
	CMysqlConfig mysql_user_area2;
	if( mysql_user_area2.read_from_ini(oIni, "USER_AREA2") == 0 )
	{
		has_user_area2 = true;
	}
	
	mysql_user_area.debug(cout);
	if(has_user_area2)
		svr_centre.set_mysql_user_area(&mysql_user_area, &mysql_user_area2);
	else
		svr_centre.set_mysql_user_area(&mysql_user_area);

	//lock & daemon
	if(CServerTool::run_by_ini(&oIni, INI_SECTION_MAIN)!=0)
	{
		cout << "run_by_ini fail" << endl;
		return 0;
	}

	CServerTool::sighandle(SIGTERM, stophandle);
	CServerTool::sighandle(SIGUSR1, usr1handle);
	CServerTool::ignore(SIGPIPE);

	svr_centre.update_channel_info(NULL);
	svr_centre.update_svr_info(NULL);
	
	//start server
	int ret = svr_centre.start(config);
	if(ret != 0)
	{
		cout << "start =" << ret << endl;
		return 0;
	}

	return 1;
}

