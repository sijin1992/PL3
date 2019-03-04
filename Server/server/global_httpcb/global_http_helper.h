#ifndef __GLOBAL_HTTP_HELPER_H__
#define __GLOBAL_HTTP_HELPER_H__

#include "net/tcpwrap.h"
#include "log/log.h"
#include "string/strutil.h"
#include <string.h>
#include <string>
#include <iostream>
#include <stdlib.h>
#include <sstream>
#include "string/simplejson.h"

extern int gDebug;

using namespace std;

class CGlobalHttpHelper
{
	public:
		int init(string addr, unsigned short port)
		{
			m_addr = addr;
			m_port = port;
			return 0;
		}
		
		inline string addr()
		{
			return m_addr;
		}

		inline unsigned short port()
		{
			return m_port;
		}
		
		int do_send_recharge(const string &uid, const string &amount, const string &ext_info, const string &orderid,
				const string &sid)
		{
			char req[1024];
			int reqlen;
			reqlen = snprintf(req, sizeof(req),
				"GET /req?uid=%s&am=%s&et=%s&od=%s&sid=%s HTTP/1.1\r\n"
				,uid.c_str(), amount.c_str(), ext_info.c_str(), orderid.c_str(), sid.c_str());

			if(gDebug)
				LOG(LOG_DEBUG, "send recharge logic info|%s", req);
			if(just_send(req, reqlen)!=0)
			{
				return -1;
			}
			
			return 0;
		}

		int do_send_selfdef_recharge(const string &uid, const string &amount, const string &ext_info, const string &orderid,
			const string &sid, int gameMoney, int baseMoney, int monthCard)
		{
			char req[1024];
			int reqlen;
			reqlen = snprintf(req, sizeof(req),
				"GET /req?selfdef=1&uid=%s&am=%s&et=%s&od=%s&sid=%s&gm=%d&bm=%d&mc=%d HTTP/1.1\r\n"
				,uid.c_str(), amount.c_str(), ext_info.c_str(), orderid.c_str(), sid.c_str(), gameMoney, baseMoney, monthCard);

			if(gDebug)
				LOG(LOG_DEBUG, "send selfdef recharge logic info|%s", req);
			if(just_send(req, reqlen)!=0)
			{
				return -1;
			}

			return 0;
		}

		int do_send_mail(const string &uid, const string &msg, const string &from, const string &subject,
				const int sid)
		{
			char req[1024];
			int reqlen;
			reqlen = snprintf(req, sizeof(req),
				"GET /xxx?gm_cmd=131&gm_user=test&gm_key=test&user=%s%05d&sb=%s&from=%s&message=%s HTTP/1.1\r\n"
				,uid.c_str(), sid, subject.c_str(), from.c_str(), msg.c_str());

			if(gDebug)
				LOG(LOG_DEBUG, "send logic info|%s", req);
			if(just_send(req, reqlen)!=0)
			{
				return -1;
			}
			
			return 0;
		}
		
		int just_send(const char* req, int reqlen)
		{
			CTcpClientSocket sock;
			if(sock.init() !=0)
			{
				LOG(LOG_ERROR, "send logic info|init fail %s", sock.errmsg());
				return -1;
			}

			if(sock.set_snd_timeout(1)!=0)
			{
				LOG(LOG_ERROR, "send logic info|set_snd_timeout fail %s", sock.errmsg());
			}

			if(sock.set_rcv_timeout(1)!=0)
			{
				LOG(LOG_ERROR, "send logic info|set_rcv_timeout fail %s", sock.errmsg());
			}
			
			if(sock.connect(addr(), port()) != 0)
			{
				LOG(LOG_ERROR, "send logic info|connect fail %s", sock.errmsg());
				return -1;
			}

			if(sock.write(req,reqlen) < 0)
			{
				LOG(LOG_ERROR, "send logic info|write fail %s", sock.errmsg());
				return -1;
			}
			return 0;
		}
	protected:
		string m_addr;
		string m_host;
		unsigned short m_port;
};

#endif

