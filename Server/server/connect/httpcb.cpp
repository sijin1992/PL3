#include <iostream>
#include <string>
#include "coding/md5/md5.h"
#include "struct/common_def.h"
#include "net/tcpwrap.h"
#include "net/epoll_wrap.h"
#include "log/log.h"
#include "common/server_tool.h"
#include "common/packet_interface.h"
#include "common/queue_pipe.h"
#include "logic/msg.h"
#include "logic/msg_queue.h"
#include "logic/toolkit.h"
#include "connect_protocol.h"
#include "ini/ini_file.h"
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include "proto/httpcb.pb.h"
#include "proto/gm_cmd.pb.h"
#include "proto/inner_cmd.pb.h"
#include "string/strutil.h"
#include <vector>
#include <map>
#include <fstream>
#include <sstream>

/***
* 用来回调充值的httpsvr
*直接把http请求转成msg，丢给logic svr
*使用单独的通道跟logic svr通讯
*/

using namespace std;

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
	else if(code == -6)
		retlen = snprintf(retbuf, sizeof(retbuf), "{\"errno\":1,\"errmsg\":\"httoken err\"}");
	else if(code == -2)
		retlen = snprintf(retbuf, sizeof(retbuf), "{\"errno\":2,\"errmsg\":\"nodata err\"}");
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

	void set_queue(CMsgQueuePipe* ppipe)
	{
		m_ppipe = ppipe;
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
			LOG(LOG_DEBUG, "nvmap[%s]=%s", name.c_str(), value.c_str());
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
		if(gDebug)
		{
			CEpollWrap::UN_SESSION_ID uSession;
			uSession.id = sessionID;
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

		int lastslash = -1;
		int querypos = -1;
		for(; i<packetLen; ++i)
		{
			//cout << "i=" << i << ", c[i]=" << packet[i] << "(" << int(packet[i]) << ")" << endl;
			if(packet[i]== '\r' || packet[i]=='\n' || packet[i]==' ')
			{
				break;
			}

			if(packet[i] == '/' && querypos == -1)
			{
				lastslash = i;
			}
			else if(packet[i] == '?' && querypos == -1)
			{
				querypos = i;
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
			//m_pepoll->close_fd(fd, sessionID);
			return 1;
		}

		if(lastslash == -1 || lastslash >= querypos-1)
		{
			LOG(LOG_ERROR, "packet(len=%d, lastslash=%d, querypos=%d) format is not /anything?params", 
				lastslash, querypos, packetLen);
			int httplen = httpresp(-3);
			if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
			{
				LOG(LOG_ERROR, "write_packet fail");
			}
			//m_pepoll->close_fd(fd, sessionID);
			return 1;
		}

		map<string, string> nvmap;
		map<string, string>::iterator it;
		int querylen = i-querypos-1;
		if(querypos > 0 && querylen > 0)
		{
			string querystr(packet+querypos+1, querylen);
			//cout << "i="<< i << "," << querystr<< endl;
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

		//加入gm命令的分支
		it = nvmap.find("gm_cmd");
		
		if(it != nvmap.end())
		{
			int cmd = atoi(it->second.c_str());
			//战斗模拟
			if(cmd == CMD_HTTPCB_GM_FIGHT_SIM_REQ)
			{
				GMFightReq req;
				USER_NAME user;//gm账号
				int battle=0;
				int num=0;
				int diff = 0;

				it = nvmap.find("user");
				if(it == nvmap.end())
				{
					LOG(LOG_ERROR, "user not find");
					int httplen = httpresp(-3);
					if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
					{
						LOG(LOG_ERROR, "write_packet fail");
					}
					//m_pepoll->close_fd(fd, sessionID);
					return 1;
				}
				user.str(it->second.c_str(), it->second.length());

				it = nvmap.find("battle_id");
				if(it == nvmap.end())
				{
					LOG(LOG_ERROR, "battle_id not find");
					int httplen = httpresp(-3);
					if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
					{
						LOG(LOG_ERROR, "write_packet fail");
					}
					//m_pepoll->close_fd(fd, sessionID);
					return 1;
				}
				battle = atoi(it->second.c_str());

				it = nvmap.find("num");
				if(it == nvmap.end())
				{
					LOG(LOG_ERROR, "num not find");
					int httplen = httpresp(-3);
					if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
					{
						LOG(LOG_ERROR, "write_packet fail");
					}
					//m_pepoll->close_fd(fd, sessionID);
					return 1;
				}
				num = atoi(it->second.c_str());

				it = nvmap.find("diff");
				if(it == nvmap.end())
				{
					LOG(LOG_ERROR, "diff not find");
					int httplen = httpresp(-3);
					if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
					{
						LOG(LOG_ERROR, "write_packet fail");
					}
					//m_pepoll->close_fd(fd, sessionID);
					return 1;
				}
				diff = atoi(it->second.c_str());

				req.set_user(user.str());
				req.set_battle(battle);
				req.set_difficult(diff);
				req.set_num(num);
				req.set_fd(fd);
				req.set_session(sessionID);

				if(gtoolkit.send_protobuf_msg(gDebug, req, CMD_HTTPCB_GM_FIGHT_SIM_REQ,
					user, m_ppipe)!=0)
				{
					LOG(LOG_ERROR, "send CMD_HTTPCB_GM_FIGHT_SIM_REQ fail");
					int httplen = httpresp(-3);
					if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
					{
						LOG(LOG_ERROR, "write_packet fail");
					}
					//m_pepoll->close_fd(fd, sessionID);
					return 1;
				}
			}
			//GM加道具
			else if(cmd == CMD_HTTPCB_GM_ADD_ITEM_REQ)
			{
				GMAddItemReq req;
				string gmuser;
				string gmkey;
				int gold = 0;
				int item_id = 0;
				int item_num = 0;
				USER_NAME user;//gm账号
				
				it = nvmap.find("user");
				if(it == nvmap.end())
				{
					LOG(LOG_ERROR, "user not find");
					int httplen = httpresp(-3);
					if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
					{
						LOG(LOG_ERROR, "write_packet fail");
					}
					//m_pepoll->close_fd(fd, sessionID);
					return 2;
				}
				user.str(it->second.c_str(), it->second.length());

				it = nvmap.find("gm_user");
				if(it == nvmap.end())
				{
					LOG(LOG_ERROR, "gm_user not find");
					int httplen = httpresp(-3);
					if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
					{
						LOG(LOG_ERROR, "write_packet fail");
					}
					//m_pepoll->close_fd(fd, sessionID);
					return 2;
				}
				gmuser.assign(it->second.c_str(), it->second.length());

				it = nvmap.find("gm_key");
				if(it == nvmap.end())
				{
					LOG(LOG_ERROR, "gm_key not find");
					int httplen = httpresp(-3);
					if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
					{
						LOG(LOG_ERROR, "write_packet fail");
					}
					//m_pepoll->close_fd(fd, sessionID);
					return 2;
				}
				gmkey.assign(it->second.c_str(), it->second.length());

				it = nvmap.find("gold");
				if(it != nvmap.end())
				{
					gold = atoi(it->second.c_str());
				}

				it = nvmap.find("item_id");
				if(it != nvmap.end())
				{
					item_id = atoi(it->second.c_str());
				}

				it = nvmap.find("item_num");
				if(it != nvmap.end())
				{
					item_num = atoi(it->second.c_str());
				}
				req.set_user(user.str());
				req.set_gold(gold);
				req.set_gm_user(gmuser);
				req.set_gm_pswd(gmkey);
				req.set_item_id(item_id);
				req.set_item_num(item_num);
				req.set_fd(fd);
				req.set_session(sessionID);
				
				if(gtoolkit.send_protobuf_msg(gDebug, req, CMD_HTTPCB_GM_ADD_ITEM_REQ,
					user, m_ppipe)!=0)
				{
					LOG(LOG_ERROR, "send CMD_HTTPCB_GM_FIGHT_SIM_REQ fail");
					int httplen = httpresp(-3);
					if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
					{
						LOG(LOG_ERROR, "write_packet fail");
					}
					//m_pepoll->close_fd(fd, sessionID);
					return 0;
				}
			}
			else if(cmd == CMD_HTTPCB_BROADCAST_REQ)
			{
				ServerBroadcastReq req;
				string gmuser;
				string gmkey;
				string content;

				it = nvmap.find("gm_user");
				if(it == nvmap.end())
				{
					LOG(LOG_ERROR, "gm_user not find");
					int httplen = httpresp(-3);
					if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
					{
						LOG(LOG_ERROR, "write_packet fail");
					}
					//m_pepoll->close_fd(fd, sessionID);
					return 2;
				}
				gmuser.assign(it->second.c_str(), it->second.length());

				it = nvmap.find("gm_key");
				if(it == nvmap.end())
				{
					LOG(LOG_ERROR, "gm_key not find");
					int httplen = httpresp(-3);
					if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
					{
						LOG(LOG_ERROR, "write_packet fail");
					}
					//m_pepoll->close_fd(fd, sessionID);
					return 2;
				}
				gmkey.assign(it->second.c_str(), it->second.length());

				it = nvmap.find("content");
				if(it == nvmap.end())
				{
					LOG(LOG_ERROR, "content not find");
					int httplen = httpresp(-3);
					if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
					{
						LOG(LOG_ERROR, "write_packet fail");
					}
					//m_pepoll->close_fd(fd, sessionID);
					return 2;
				}
				content.assign(it->second.c_str(), it->second.length());

				req.set_message(content);
				req.set_gmuser(gmuser);
				req.set_gmkey(gmkey);
				req.set_fd(fd);
				req.set_session(sessionID);
				USER_NAME user;
				user.from_str(gmuser);
				if(gtoolkit.send_protobuf_msg(gDebug, req, CMD_HTTPCB_BROADCAST_REQ,
					user, m_ppipe)!=0)
				{
					LOG(LOG_ERROR, "send CMD_HTTPCB_BROADCAST_REQ fail");
					int httplen = httpresp(-3);
					if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
					{
						LOG(LOG_ERROR, "write_packet fail");
					}
					//m_pepoll->close_fd(fd, sessionID);
					return 2;
				}
			}
			else if(cmd == CMD_GM_SEND_MAIL_REQ)
			{
				GMSendMailReq req;
				string gmuser;
				string gmkey;
				USER_NAME user;
				string subject;
				string from;
				string message;
				string items;
				int buchang;
				DBSendMailReq db_req;
				// item先不处理
				
				it = nvmap.find("user");
				if(it != nvmap.end())
				{
					user.str(it->second.c_str(), it->second.length());
					db_req.set_user(user.str());
				}
				
				it = nvmap.find("gm_user");
				if(it == nvmap.end())
				{
					LOG(LOG_ERROR, "gm_user not find");
					int httplen = httpresp(-3);
					if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
					{
						LOG(LOG_ERROR, "write_packet fail");
					}
					//m_pepoll->close_fd(fd, sessionID);
					return 2;
				}
				gmuser.assign(it->second.c_str(), it->second.length());

				it = nvmap.find("gm_key");
				if(it == nvmap.end())
				{
					LOG(LOG_ERROR, "gm_key not find");
					int httplen = httpresp(-3);
					if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
					{
						LOG(LOG_ERROR, "write_packet fail");
					}
					//m_pepoll->close_fd(fd, sessionID);
					return 2;
				}
				gmkey.assign(it->second.c_str(), it->second.length());

				it = nvmap.find("sb");
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
				db_req.set_subject(subject);

				it = nvmap.find("from");
				if(it == nvmap.end())
				{
					LOG(LOG_ERROR, "from not find");
					int httplen = httpresp(-3);
					if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
					{
						LOG(LOG_ERROR, "write_packet fail");
					}
					//m_pepoll->close_fd(fd, sessionID);
					return 2;
				}
				from.assign(it->second.c_str(), it->second.length());
				db_req.set_from(from);
				
				it = nvmap.find("message");
				if(it == nvmap.end())
				{
					LOG(LOG_ERROR, "message not find");
					int httplen = httpresp(-3);
					if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
					{
						LOG(LOG_ERROR, "write_packet fail");
					}
					//m_pepoll->close_fd(fd, sessionID);
					return 2;
				}
				message.assign(it->second.c_str(), it->second.length());
				db_req.set_message(message);
				
				it = nvmap.find("buchang");
				if(it != nvmap.end())
				{
					buchang = atoi(it->second.c_str());
					db_req.set_buchang(buchang);
				}
				it = nvmap.find("reg_time");
				if(it != nvmap.end())
				{
					int reg_tm = atoi(it->second.c_str());
					db_req.set_reg_time(reg_tm);
				}
				it = nvmap.find("vip_limit");
				if(it != nvmap.end())
				{
					int vip = atoi(it->second.c_str());
					db_req.set_vip_limit(vip);
				}
				it = nvmap.find("lev_limit");
				if(it != nvmap.end())
				{
					int lev = atoi(it->second.c_str());
					db_req.set_lev_limit(lev);
				}

				it = nvmap.find("items");
				if(it != nvmap.end())
				{
					items.assign(it->second.c_str(), it->second.length());
					int t = 0;
					strutil::Tokenizer item(items, ",");
					Item *ti = NULL;
					while(item.nextToken())
					{
						if(t == 0)
							ti = db_req.add_item_list();
						string st = item.getToken();
						if(t == 0){
							ti->set_id(atoi(st.c_str()));
							ti->set_guid(0);
						}
						else{
							ti->set_num(atoi(st.c_str()));
						}
						if(t == 0)
						{
							t = 1;
						}
						else
						{
							t = 0;
						}
					}
					if(t != 0)
					{
						LOG(LOG_ERROR, "itemlist err");
						int httplen = httpresp(-3);
						if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
						{
							LOG(LOG_ERROR, "write_packet fail");
						}
						return 2;
					}
					db_req.set_type(10);
				}
				else
				{
					db_req.set_type(0);
				}
				it = nvmap.find("time");
				if(it != nvmap.end())
				{
					db_req.set_time(atoi(it->second.c_str()));
				}
				
				req.mutable_req()->CopyFrom(db_req);
				//req.set_gm_user(gmuser);
				//req.set_gm_pswd(gmkey);
				req.set_fd(fd);
				req.set_session(sessionID);
				
				if(gtoolkit.send_protobuf_msg(gDebug, req, CMD_GM_SEND_MAIL_REQ,
					user, m_ppipe)!=0)
				{
					LOG(LOG_ERROR, "send CMD_GM_SEND_MAIL_REQ fail");
					int httplen = httpresp(-3);
					if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
					{
						LOG(LOG_ERROR, "write_packet fail");
					}
					//m_pepoll->close_fd(fd, sessionID);
					return 2;
				}
			}
			else if(cmd == CMD_HTTPCB_GM_BLOCK_REQ)
			{
				GMBlockReq req;
				string gmuser;
				string gmkey;
				USER_NAME user;
				int type = 0;
				int blocktime = 0;
				
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
				
				it = nvmap.find("type");
				if(it != nvmap.end())
				{
					type = atoi(it->second.c_str());
				}
				it = nvmap.find("time");
				if(it != nvmap.end())
				{
					blocktime = atoi(it->second.c_str());
				}
				
				req.set_uid(user.str());
				req.set_type(type);
				req.set_blocktime(blocktime);
				req.set_fd(fd);
				req.set_session(sessionID);
				
				if(gtoolkit.send_protobuf_msg(gDebug, req, CMD_HTTPCB_GM_BLOCK_REQ,
					user, m_ppipe)!=0)
				{
					LOG(LOG_ERROR, "send CMD_HTTPCB_GM_BLOCK_REQ fail");
					int httplen = httpresp(-3);
					if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
					{
						LOG(LOG_ERROR, "write_packet fail");
					}
					//m_pepoll->close_fd(fd, sessionID);
					return 2;
				}
			}
//			LOG(LOG_INFO, "GMREQ|gm=%s|custom=%s|money=%d|expr=%d|itemid=%d|itemnum=%d",
//				gmuser.str(), req.custom().c_str(), req.money(), req.expr(), req.itemid(), req.itemnum());
			int httplen = httpresp(0);
			if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
			{
				LOG(LOG_ERROR, "write_packet fail");
			}
			return 0;
		}
		//充值回调
		USER_NAME user; // 用户id
		string orderno;	// 订单号
		int money;		// 充值金额
		string amount;
		string extinfo;
		int sid;
		string ssid;
		
		HttpAddMondyReq req;

		//userid必须有
		it = nvmap.find("uid");
		if(it == nvmap.end())
		{
			LOG(LOG_ERROR, "id not find");
			int httplen = httpresp(-3);
			if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
			{
				LOG(LOG_ERROR, "write_packet fail");
			}
			return 2;
		}
		user.str(it->second.c_str(), it->second.length());

		//orderid必须有,唯一
		it = nvmap.find("od");
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
		it = nvmap.find("am");
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
		ssid = it->second;
		sid = atoi(it->second.c_str());
		
		it = nvmap.find("et");
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

		it = nvmap.find("fake");
		if(it != nvmap.end())
		{
			req.set_fake(atoi(it->second.c_str()));
		}

		it = nvmap.find("selfdef");
		if(it != nvmap.end() && atoi(it->second.c_str()) != 0 )
		{
			req.set_selfdef(1);
			it = nvmap.find("gm"); //游戏币
			if(it == nvmap.end()) 
			{
				LOG(LOG_ERROR, "%s|selfdef|gamemoney not find", user.str());
				int httplen = httpresp(-3);
				if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
				{
					LOG(LOG_ERROR, "write_packet fail");
				}
				return 2;
			}
			else
			{
				req.set_gamemoney(atoi(it->second.c_str()));
			}
			it = nvmap.find("bm"); //游戏币
			if(it == nvmap.end()) 
			{
				LOG(LOG_ERROR, "%s|selfdef|basemoney not find", user.str());
				int httplen = httpresp(-3);
				if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
				{
					LOG(LOG_ERROR, "write_packet fail");
				}
				return 2;
			}
			else
			{
				req.set_basemoney(atoi(it->second.c_str()));
			}

			it = nvmap.find("mc"); //月卡
			if(it != nvmap.end()) 
			{
				req.set_monthcard(atoi(it->second.c_str()));
			}
		}

		req.set_fd(fd);
		req.set_sid(ssid);
		req.set_session(sessionID);
		req.set_orderno(orderno);
		req.set_money(money);
		req.set_extinfo(extinfo);

		char t_name[USER_NAME_LEN] = {0};
		snprintf(t_name, USER_NAME_LEN, "%s%05d", user.str(), sid);
		USER_NAME inner_name;
		inner_name.str(t_name, USER_NAME_LEN);
		
		if(gtoolkit.send_protobuf_msg(gDebug, req, CMD_HTTPCB_ADDMONEY_REQ,
			inner_name, m_ppipe)!=0)
		{
			LOG(LOG_ERROR, "send CMD_HTTPCB_ADDMONEY_REQ fail");
			int httplen = httpresp(-3);
			if(m_pepoll->write_packet(fd, sessionID, ghttpbuff, httplen) != 0)
			{
				LOG(LOG_ERROR, "write_packet fail");
			}
			return 2;
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
	CMsgQueuePipe* m_ppipe;
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

	int start(CONFIG& conf, CMsgQueuePipe& pipe)
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
		m_control.set_queue(&pipe);

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

			ret = pipe.get_msg(respMsg);
			if(ret == CMsgQueue::OK)
			{
				int cmd = gtoolkit.get_cmd(respMsg);

				if(cmd == CMD_HTTPCB_ADDMONEY_RESP)
				{
					HttpAddMondyResp resp;
					USER_NAME user;
					int code = -3;
					if(gtoolkit.parse_protobuf_msg(gDebug, respMsg,	user, resp) != 0)
					{
						LOG(LOG_ERROR, "parse_protobuf_msg fail");
					}
					else
					{
						code = resp.result();
					}
					int httplen = httpresp(code);
					if(m_pepoll->write_packet(resp.req().fd(), resp.req().session(), ghttpbuff, httplen) != 0)
					{
						LOG(LOG_ERROR, "write_packet fail");
					}
					m_pepoll->close_fd(resp.req().fd(), resp.req().session());
				}
				
				else if(cmd == CMD_HTTPCB_GM_RESP)
				{
					GMFightResp resp;
					USER_NAME user;
					if(gtoolkit.parse_protobuf_msg(gDebug, respMsg,	user, resp) != 0)
					{
						LOG(LOG_ERROR, "parse_protobuf_msg fail");
					}
					else
					{
						LOG(LOG_DEBUG, "------%s", resp.DebugString().c_str());
						//int code = resp.code();
						//LOG(LOG_INFO, "GMRESP|gm=%s|custom=%s|money=%d|expr=%d|itemid=%d|itemnum=%d|code=%d",
						//	user.str(), resp.custom().c_str(), resp.money(), resp.expr(), resp.itemid(), resp.itemnum(), code);
						int httplen = httpresp1(resp.DebugString());
						if(m_pepoll->write_packet(resp.fd(), resp.session(), ghttpbuff, httplen) != 0)
						{
							LOG(LOG_ERROR, "write_packet fail");
						}
						m_pepoll->close_fd(resp.fd(), resp.session());
					}
				}
				else if(cmd == CMD_HTTPCB_GM_FIGHT_SIM_RESP)
				{
					GMFightResp resp;
					USER_NAME user;
					if(gtoolkit.parse_protobuf_msg(gDebug, respMsg,	user, resp) != 0)
					{
						LOG(LOG_ERROR, "parse_protobuf_msg fail");
					}
					else
					{
						//int code = resp.code();
						//LOG(LOG_INFO, "GMRESP|gm=%s|custom=%s|money=%d|expr=%d|itemid=%d|itemnum=%d|code=%d",
						//	user.str(), resp.custom().c_str(), resp.money(), resp.expr(), resp.itemid(), resp.itemnum(), code);
						int httplen;
						if(resp.result() == resp.FAIL)
							httplen = httpresp1("参数错误");
						else
						{
							ostringstream s;
							s << "胜" << resp.win() << "场，胜率" << resp.win() * 100 /resp.num() << "\%";
							httplen = httpresp1(s.str());
						}
						if(m_pepoll->write_packet(resp.fd(), resp.session(), ghttpbuff, httplen) != 0)
						{
							LOG(LOG_ERROR, "write_packet fail");
						}
						m_pepoll->close_fd(resp.fd(), resp.session());
					}
				}
				else if(cmd == CMD_HTTPCB_GM_ADD_ITEM_RESP)
				{
					GMAddItemResp resp;
					USER_NAME user;
					if(gtoolkit.parse_protobuf_msg(gDebug, respMsg,	user, resp) != 0)
					{
						LOG(LOG_ERROR, "parse_protobuf_msg fail");
					}
					else
					{
						//int code = resp.code();
						//LOG(LOG_INFO, "GMRESP|gm=%s|custom=%s|money=%d|expr=%d|itemid=%d|itemnum=%d|code=%d",
						//	user.str(), resp.custom().c_str(), resp.money(), resp.expr(), resp.itemid(), resp.itemnum(), code);
						int httplen;
						if(resp.result() == resp.FAIL)
							httplen = httpresp1("some err");
						else
						{
							httplen = httpresp1("OK");
						}
						if(m_pepoll->write_packet(resp.fd(), resp.session(), ghttpbuff, httplen) != 0)
						{
							LOG(LOG_ERROR, "write_packet fail");
						}
						m_pepoll->close_fd(resp.fd(), resp.session());
					}
				}
				else if(cmd == CMD_HTTPCB_BROADCAST_RESP)
				{
					ServerBroadcastResp resp;
					USER_NAME user;
					if(gtoolkit.parse_protobuf_msg(gDebug, respMsg,	user, resp) != 0)
					{
						LOG(LOG_ERROR, "parse_protobuf_msg fail");
					}
					else
					{
						//int code = resp.code();
						//LOG(LOG_INFO, "GMRESP|gm=%s|custom=%s|money=%d|expr=%d|itemid=%d|itemnum=%d|code=%d",
						//	user.str(), resp.custom().c_str(), resp.money(), resp.expr(), resp.itemid(), resp.itemnum(), code);
						int httplen;
						if(resp.result() == resp.FAIL)
							httplen = httpresp1("some err");
						else
						{
							httplen = httpresp1("OK");
						}
						if(m_pepoll->write_packet(resp.fd(), resp.session(), ghttpbuff, httplen) != 0)
						{
							LOG(LOG_ERROR, "write_packet fail");
						}
						m_pepoll->close_fd(resp.fd(), resp.session());
					}
				}
				else if(cmd == CMD_GM_RESP)
				{
					GMGeneralResp resp;
					USER_NAME user;
					if(gtoolkit.parse_protobuf_msg(gDebug, respMsg,	user, resp) != 0)
					{
						LOG(LOG_ERROR, "parse_protobuf_msg fail");
					}
					else
					{
						//int code = resp.code();
						//LOG(LOG_INFO, "GMRESP|gm=%s|custom=%s|money=%d|expr=%d|itemid=%d|itemnum=%d|code=%d",
						//	user.str(), resp.custom().c_str(), resp.money(), resp.expr(), resp.itemid(), resp.itemnum(), code);
						int httplen;
						if(resp.result() != 0)
						{
							stringstream sstr;
							sstr << "some err:";
							sstr << resp.result();
							httplen = httpresp1(sstr.str());
						}
						else
						{
							httplen = httpresp1("OK");
						}
						if(m_pepoll->write_packet(resp.fd(), resp.session(), ghttpbuff, httplen) != 0)
						{
							LOG(LOG_ERROR, "write_packet fail");
						}
						m_pepoll->close_fd(resp.fd(), resp.session());
					}
				}
				
				else
				{
					LOG(LOG_ERROR, "recv bad cmd=0x%x", cmd);
				}
			}
			else if(ret == CMsgQueue::ERROR)
			{
				LOG(LOG_ERROR,"pipe.get_msg fail");
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
	if(argc < 3)
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

	//pipe config
	CPIPEConfigInfo pipeconfig;
	if(pipeconfig.set_config(argv[2])!= 0)
	{
		cout << "parse ini fail " << endl;
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

	if(oIni.GetInt(INI_SECTION_MAIN, "GLOBE_PIPE_ID", 0, &gGlobePipeID)!=0)
	{
	 	cout << INI_SECTION_MAIN".GLOBE_PIPE_ID not found" << endl;
		return 0;
	}
	cout << "pipe id " << gGlobePipeID << endl;

	CDequePIPE pipeForward;
	int ret = pipeForward.init(pipeconfig, gGlobePipeID, true);
	if(ret != 0)
	{
		cout << "pipeForward.init " << pipeForward.errmsg() << endl;
		return 0;
	}
	CMsgQueuePipe queuePipeForward(pipeForward, &gDebug);

	//lock & daemon
	if(CServerTool::run_by_ini(&oIni, INI_SECTION_MAIN)!=0)
	{
		cout << "run_by_ini fail" << endl;
		return 0;
	}

	CServerTool::sighandle(SIGTERM, stophandle);
	CServerTool::sighandle(SIGUSR1, usr1handle);
	CServerTool::ignore(SIGPIPE);

	//start server
	ret = httpcb.start(config, queuePipeForward);
	if(ret != 0)
	{
		cout << "start =" << ret << endl;
		return 0;
	}

	return 1;
}

