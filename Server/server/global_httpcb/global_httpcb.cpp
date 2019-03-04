#include <iostream>
#include <string>
#include "coding/md5/md5.h"
#include "struct/common_def.h"
#include "net/tcpwrap.h"
#include "net/epoll_wrap.h"
#include "log/log.h"
#include "common/server_tool.h"
#include "common/packet_interface.h"
#include "logic/msg.h"
#include "logic/toolkit.h"
#include "ini/ini_file.h"
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <vector>
#include <map>
#include <fstream>
#include <sstream>
#include "global_http_helper.h"

/***
* 用来回调充值的httpsvr
*直接把http请求转成msg，丢给logic svr
*使用单独的通道跟logic svr通讯
*/

using namespace std;

int intest=0;
int gDebug;
unsigned int gGlobePipeID;
int gMaxSaveNum;
int gOrderTimeout;

#define INI_SECTION_MAIN "HTTPCB"

CToolkit gtoolkit;
char ghttpbuff[1024];

map<string, char> gOrderIndx;
vector<string> gOrderArray;
int gOrderArrayPos;
char gHexChar[16] = {'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'};
char g_HTSecret[40] = {0};

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
	else
		retlen = snprintf(retbuf, sizeof(retbuf), "{\"errno\":1,\"errmsg\":\"unknow err\"}");
	 
	return snprintf(ghttpbuff, sizeof(ghttpbuff), 
		"HTTP/1.1 200\r\nServer: Apache\r\nContent-Length: %d\r\nContent-Type: text/html\r\n"
		"Cache-Control: no-cache\r\nPragma: no-cache\r\n\r\n%s",
		retlen, retbuf);
}

int check_order(string& orderno)
{
	if(gOrderIndx.find(orderno) != gOrderIndx.end())
	{
		LOG(LOG_ERROR, "orderid=%s already exsit", orderno.c_str());
		return -1;
	}
	return 0;
}

int record_order(string& orderno)
{
	if(gOrderArray.size() < (unsigned int)gMaxSaveNum)
	{
		//未填满的状态
		gOrderArray.push_back(orderno);
	}
	else
	{
		//循环使用
		gOrderIndx.erase(gOrderArray[gOrderArrayPos]);
		gOrderArray[gOrderArrayPos] = orderno;
	}
	
	gOrderIndx[orderno] = 0;
	
	++gOrderArrayPos;
	if(gOrderArrayPos >= gMaxSaveNum)
	{
		gOrderArrayPos -= gMaxSaveNum;
	}
	
	return 0;
}


int checkmd5(const char* usrid, const char *sid, const char* orderno,  const char *money, const char *htnonce, const char* httoken)
{
	char sbuff[1024];
	int len = snprintf(sbuff, sizeof(sbuff), "%s%s%s%s%s%s",
		g_HTSecret,usrid,sid,orderno, money, htnonce);

	char md5buff[64] = {0};//33就够了
	md5_state_t ms;
	md5_init(&ms); 
	md5_append(&ms, (md5_byte_t *)sbuff, len);
	unsigned char digest[16];
	md5_finish(&ms, (md5_byte_t *)digest);
	
	char *wp = md5buff;
	
	for(int i = 0; i < 16; i++){
		wp[2*i] = gHexChar[(digest[i] >> 4)];
		wp[2*i+1] = gHexChar[digest[i] & 0xf];
	}
	if(strcmp(httoken, wp) != 0)
	{
		LOG(LOG_ERROR, "uid(%s) httoken=%s but md5=%s", usrid, httoken, wp);
		return -1;
	}

	return 0;
}

struct svr_info
{
	int sid;			//server idx
	string ip;			//ip
	int port;			//port
	time_t last_active_time;	// 最近一次更新时间，超过1分钟就提示不在线
};

class CHttpcbControl: public CControlInterface
{
public:
	CHttpcbControl()
	{
		m_pepoll = NULL;
	}

	void set_epoll(CEpollWrap* pepoll)
	{
		m_pepoll = pepoll;
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

	virtual int pass_packet(int fd, unsigned long long sessionID, const char* packet, unsigned int packetLen) 
	{
		CEpollWrap::UN_SESSION_ID uSession;
		uSession.id = sessionID;
		string ip = CTcpSocket::addr_to_str(uSession.tcpaddr.ip);
		if(gDebug)
		{
			LOG(LOG_DEBUG, "client(fd=%d,%s:%d,%d) pass_packet(len=%u)|%s", 
				fd, CTcpSocket::addr_to_str(uSession.tcpaddr.ip).c_str(), uSession.tcpaddr.port, uSession.tcpaddr.seq, packetLen, packet);
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
		if(packet[i] == '/' && packet[i + 1] == 'n' && packet[i + 2] == 'o' && packet[i + 3] == 't' && packet[i + 4] == 'i'
			&& packet[i + 5] == 'f' && packet[i + 6] == 'y' && packet[i + 7] == '?')
		{
			req_status = 0;
			i = i + 8;
		}
		else if(packet[i] == '/' && packet[i + 1] == 'i' && packet[i + 2] == 'n' && packet[i + 3] == 'n' && packet[i + 4] == '?')
		{
			req_status = 1;
			i = i + 5;
		}
		else if(packet[i] == '/' && packet[i + 1] == 'm' && packet[i + 2] == 'a' && packet[i + 3] == 'i'
				&& packet[i + 4] == 'l' && packet[i + 5] == '?')
		{
			req_status = 2;
			i = i + 6;
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
		int querylen = i-querypos+1;
		if(querypos > 0 && querylen > 0)
		{
			string querystr(packet+querypos, querylen);
			//cout << querystr<< endl;
			LOG(LOG_DEBUG, "querystr:%s", querystr.c_str());
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
		{//这个是充值回调
			string sid;		// 游戏区服标志
			int isid;		
			USER_NAME user; // 用户id
			string orderno;	// 订单号
			int money;		// 充值金额
			string amount;
			int status;		// 充值状态
			string extinfo;
			string htnonce;
			string httoken;	//签名

			//userid必须有
			it = nvmap.find("uid");
			if(it == nvmap.end())
			{
				LOG(LOG_ERROR, "uid not find");
				int httplen = httpresp(-3);
				if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
				{
					LOG(LOG_ERROR, "write_packet fail");
				}
				return 2;
			}
			user.str(it->second.c_str(), it->second.length());

			it = nvmap.find("sid");
			if(it == nvmap.end())
			{
				LOG(LOG_ERROR, "%s|sid not find", user.str());
				int httplen = httpresp(-3);
				if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
				{
					LOG(LOG_ERROR, "write_packet fail");
				}
				return 2;
			}
			sid = it->second;
			isid = atoi(it->second.c_str());
			
			//orderid必须有,唯一
			it = nvmap.find("orderno");
			if(it == nvmap.end())
			{
				LOG(LOG_ERROR, "%s|orderno not find", user.str());
				int httplen = httpresp(-3);
				if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
				{
					LOG(LOG_ERROR, "write_packet fail");
				}
				return 2;
			}
			orderno = it->second;

			//money 必须要有
			it = nvmap.find("amount");
			if(it == nvmap.end())
			{
				LOG(LOG_ERROR, "%s|amount not find", user.str());
				int httplen = httpresp(-3);
				if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
				{
					LOG(LOG_ERROR, "write_packet fail");
				}
				return 2;
			}
			money = atoi(it->second.c_str());
			amount = it->second.c_str();

			it = nvmap.find("extinfo");
			if(it == nvmap.end())
			{
				LOG(LOG_ERROR, "%s|extinfo not find", user.str());
				int httplen = httpresp(-3);
				if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
				{
					LOG(LOG_ERROR, "write_packet fail");
				}
				return 2;
			}
			extinfo = it->second;

			it = nvmap.find("htnonce");
			if(it == nvmap.end())
			{
				LOG(LOG_ERROR, "%s|htnonce not find", user.str());
				int httplen = httpresp(-3);
				if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
				{
					LOG(LOG_ERROR, "write_packet fail");
				}
				return 2;
			}
			htnonce = it->second;
			
			//查看是否是自充值
			bool isSelfDefined = false; //是否指自定义充值
			int gameMoney = 0;	//总游戏币
			int baseMoney = 0;	//基础游戏币
			int monthCard = 0;	//月卡ID
			it = nvmap.find("selfdef");
			if( it != nvmap.end() )
			{
				isSelfDefined = atoi(it->second.c_str());
			}
			if( isSelfDefined )
			{
				it = nvmap.find("gamemoney");
				if(it == nvmap.end())
				{
					LOG(LOG_ERROR, "%s|selfdefined|gamemoney not find", user.str());
					int httplen = httpresp(-3);
					if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
					{
						LOG(LOG_ERROR, "write_packet fail");
					}
					return 2;
				}
				gameMoney = atoi(it->second.c_str());

				it = nvmap.find("basemoney");
				if(it == nvmap.end())
				{
					LOG(LOG_ERROR, "%s|selfdefined|basemoney not find", user.str());
					int httplen = httpresp(-3);
					if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
					{
						LOG(LOG_ERROR, "write_packet fail");
					}
					return 2;
				}
				baseMoney = atoi(it->second.c_str());

				it = nvmap.find("monthcard");
				if(it != nvmap.end())
				{
					monthCard = atoi(it->second.c_str());
				}
			}

			if(intest == 0)
			{	
				it = nvmap.find("status");
				if(it != nvmap.end())
					status = atoi(it->second.c_str());
					
				//flag 必须要有
				it = nvmap.find("httoken");
				if(it == nvmap.end())
				{
					LOG(LOG_ERROR, "%s|httoken not find", user.str());
					int httplen = httpresp(-3);
					if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
					{
						LOG(LOG_ERROR, "write_packet fail");
					}
					return 2;
				}
				httoken = it->second;

				if(check_order(orderno) != 0)
				{
					LOG(LOG_ERROR, "%s|orderno invalid", user.str());
					int httplen = httpresp(-3);
					if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
					{
						LOG(LOG_ERROR, "write_packet fail");
					}
					return 2;
				}
				
				//验证flag
				if(checkmd5(user.str(), sid.c_str(), orderno.c_str(), amount.c_str(), htnonce.c_str(), httoken.c_str())!=0)
				{
					int httplen = httpresp(-3);
					if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
					{
						LOG(LOG_ERROR, "write_packet fail");
					}
					return 2;
				}
			}
			bool ok = false;
			svr_info *sinfo = NULL;
			map<int, svr_info>::iterator sit = m_svr_map.find(isid);
			if(sit != m_svr_map.end())
			{
				sinfo = &sit->second;
			}
			if(sinfo == NULL)
			{
				LOG(LOG_ERROR, "sid %d not find", isid);
			}
			else if(time(NULL)- sinfo->last_active_time > 60)
			{
				LOG(LOG_ERROR, "sid %d out of time", isid);
			}
			else
			{
				for(int i=0; i<2; ++i)
				{
					CGlobalHttpHelper thehelper;

					thehelper.init(sinfo->ip, sinfo->port);
					if( isSelfDefined )
					{
						if( thehelper.do_send_selfdef_recharge(user.to_str(), amount, extinfo, orderno, sid, gameMoney, baseMoney, monthCard) != 0 )
						{
							LOG(LOG_ERROR, "send logic info|do_send_logic_info fail i=%d", i);
						}
						ok = true;
						break;
					}
					else if(thehelper.do_send_recharge(user.to_str(), amount, extinfo, orderno, sid) != 0)
					{
						LOG(LOG_ERROR, "send logic info|do_send_logic_info fail i=%d", i);
					}
					else
					{
						ok = true;
						break;
					}
						
				}
			}
			int httplen;
			if(ok)
			{
				httplen = httpresp(0);
				record_order(orderno);
				LOG(LOG_INFO, "%s|%d|%s|%s|%s", user.str(), isid, orderno.c_str(), amount.c_str(), extinfo.c_str());
			}
			else
				httplen = httpresp(-1);
			if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
			{
				LOG(LOG_ERROR, "write_packet fail");
			}
			return 0;
		}
		else if(req_status == 1)
		{
			it = nvmap.find("sid");
			if(it == nvmap.end())
			{
				LOG(LOG_ERROR, "idx not find");
				return 2;
			}
			int sid = atoi(it->second.c_str());

			it = nvmap.find("pt");
			if(it == nvmap.end())
			{
				LOG(LOG_ERROR, "port not find");
				return 2;
			}
			int port = atoi(it->second.c_str());
			
			svr_info *sinfo = NULL;
			bool new_svr = false;
			map<int, svr_info>::iterator sit = m_svr_map.find(sid);
			if(sit != m_svr_map.end())
			{
				sinfo = &sit->second;
				if(sinfo->ip != ip)
					sinfo->ip = ip;
				if(sinfo->port != port)
					sinfo->port = port;
			}
			else
			{
				svr_info t;
				pair<map<int, svr_info>::iterator, bool> ret = m_svr_map.insert(pair<int, svr_info>(sid, t));
				if(ret.second == false)
				{
					LOG(LOG_ERROR, "add server %d err", sid);
					return 2;
				}
				sinfo = &(ret.first->second);
				sinfo->ip = ip;
				sinfo->port = port;
				new_svr = true;
			}
			sinfo->last_active_time = time(NULL);
			return 0;
		}
		else if(req_status == 2)
		{//发邮件
			string sid;		// 游戏区服标志
			int isid;		
			USER_NAME user; // 用户id
			string from;
			string msg;
			string subject;

			//userid必须有
			it = nvmap.find("uid");
			if(it == nvmap.end())
			{
				LOG(LOG_ERROR, "uid not find");
				int httplen = httpresp(-3);
				if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
				{
					LOG(LOG_ERROR, "write_packet fail");
				}
				return 2;
			}
			user.str(it->second.c_str(), it->second.length());

			it = nvmap.find("sid");
			if(it == nvmap.end())
			{
				LOG(LOG_ERROR, "%s|sid not find", user.str());
				int httplen = httpresp(-3);
				if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
				{
					LOG(LOG_ERROR, "write_packet fail");
				}
				return 2;
			}
			sid = it->second;
			isid = atoi(it->second.c_str());

			it = nvmap.find("subject");
			if(it == nvmap.end())
			{
				LOG(LOG_ERROR, "subject not find");
				int httplen = httpresp(-3);
				if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
				{
					LOG(LOG_ERROR, "write_packet fail");
				}
				return 2;
			}
			subject.assign(it->second.c_str(), it->second.length());

			it = nvmap.find("from");
			if(it == nvmap.end())
			{
				LOG(LOG_ERROR, "from not find");
				int httplen = httpresp(-3);
				if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
				{
					LOG(LOG_ERROR, "write_packet fail");
				}
				return 2;
			}
			from.assign(it->second.c_str(), it->second.length());

			it = nvmap.find("message");
			if(it == nvmap.end())
			{
				LOG(LOG_ERROR, "message not find");
				int httplen = httpresp(-3);
				if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
				{
					LOG(LOG_ERROR, "write_packet fail");
				}
				return 2;
			}
			msg.assign(it->second.c_str(), it->second.length());

			
			bool ok = false;
			svr_info *sinfo = NULL;
			map<int, svr_info>::iterator sit = m_svr_map.find(isid);
			if(sit != m_svr_map.end())
			{
				sinfo = &sit->second;
			}
			if(sinfo == NULL)
			{
				LOG(LOG_ERROR, "sid %d not find", isid);
			}
			else if(time(NULL)- sinfo->last_active_time > 60)
			{
				LOG(LOG_ERROR, "sid %d out of time", isid);
			}
			else
			{
				for(int i=0; i<2; ++i)
				{
					CGlobalHttpHelper thehelper;

					thehelper.init(sinfo->ip, sinfo->port);
					if(thehelper.do_send_mail(user.to_str(), msg, from, subject, isid) != 0)
					{
						LOG(LOG_ERROR, "send logic info|do_send_logic_info fail i=%d", i);
					}
					else
					{
						ok = true;
						break;
					}
				}
			}
			int httplen;
			if(ok)
			{
				httplen = httpresp(0);
				LOG(LOG_INFO, "send mail:%s|%d", user.str(), isid);
			}
			else
				httplen = httpresp(-1);
			if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
			{
				LOG(LOG_ERROR, "write_packet fail");
			}
			return 0;
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

	map<int, svr_info> m_svr_map;
};

class CHttpcb
{
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

	CHttpcb()
	{
		m_pepoll = NULL;
		m_inited = false;
	}

	~CHttpcb()
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

public:
	static int STOP_FLAG;

protected:
	CEpollWrap* m_pepoll;
	bool m_inited;
	CRawPackInterface m_raw;
	CHttpcbControl m_control;
};

int CHttpcb::STOP_FLAG = 0;

static void stophandle(int iSigNo)
{
	CHttpcb::STOP_FLAG = 1;
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
		cout << argv[0] << " connect_config_ini" << endl;
		return 0;
	}

	CHttpcb httpcb;
	CHttpcb::CONFIG config;

	CIniFile oIni(argv[1]);
	if(!oIni.IsValid())
	{
		cout << "read ini " << argv[1] << " fail" << endl;
		return 0;
	}

	char ip[64] = {0}; 
	int epollTimeoutUs = 0;
	int port = 0;

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

	oIni.GetInt(INI_SECTION_MAIN, "EPOLL_TIMEOUT_US", 1000,&epollTimeoutUs);
	config.ip = ip;
	config.port = port;
	config.epollTimeoutUs = epollTimeoutUs; //1ms

	oIni.GetInt(INI_SECTION_MAIN, "MAX_CLIENTS",  1000,&(config.maxclients));
	
	config.debug(cout);
	
	if(oIni.GetInt(INI_SECTION_MAIN, "MAX_SAVE_ORDERID_NUM", 0, &gMaxSaveNum)!=0)
	{
	 	cout << INI_SECTION_MAIN".MAX_SAVE_ORDERID_NUM not found" << endl;
		return 0;
	}
	cout << "gMaxSaveNum " << gMaxSaveNum << endl;

	if(oIni.GetInt(INI_SECTION_MAIN, "ORDERID_TIMEOUT_S", 0, &gOrderTimeout)!=0)
	{
	 	cout << INI_SECTION_MAIN".ORDERID_TIMEOUT_S not found" << endl;
		return 0;
	}
	cout << "gOrderTimeout " << gOrderTimeout << endl;

	if(oIni.GetString(INI_SECTION_MAIN, "HTSECRET", "", g_HTSecret, sizeof(g_HTSecret)))
	{
	 	cout << INI_SECTION_MAIN".HTSECRET not found" << endl;
		return 0;
	}
	cout << "g_HTSecret " << g_HTSecret << endl;

	oIni.GetInt(INI_SECTION_MAIN, "INTEST", 0, &intest);

	//lock & daemon
	if(CServerTool::run_by_ini(&oIni, INI_SECTION_MAIN)!=0)
	{
		cout << "run_by_ini fail" << endl;
		return 0;
	}

	CServerTool::sighandle(SIGTERM, stophandle);
	CServerTool::sighandle(SIGUSR1, usr1handle);
	CServerTool::ignore(SIGPIPE);

	//初始化订单
	gOrderArray.reserve(gMaxSaveNum);
	gOrderArrayPos = 0;

	//start server
	int ret = httpcb.start(config);
	if(ret != 0)
	{
		cout << "start =" << ret << endl;
		return 0;
	}

	return 1;
}

