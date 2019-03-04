#ifndef __HTTP_HELPER_H__
#define __HTTP_HELPER_H__

#include "net/tcpwrap.h"
#include "log/log.h"
#include "string/strutil.h"
#include <string.h>
#include <string>
#include <iostream>
#include <stdlib.h>
#include <sstream>
#include <vector>
#include "string/simplejson.h"

extern int gDebug;

using namespace std;

class CHttpHelper
{
	public:
		int init(string addr, unsigned short port, string url)
		{
			m_addr = addr;
			m_port = port;
			strutil::Tokenizer token(url, ":");
			if(token.nextToken())
			{
				m_host = token.getToken();
			}
			else
			{
				LOG(LOG_ERROR, "url=%s no host", url.c_str());
				return -1;
			}
						
			if(token.nextToken())
			{
				m_url = token.getToken();
			}
			else
			{
				LOG(LOG_ERROR, "url=%s no path", url.c_str());
				return -1;
			}

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

		int do_getuserinfo(const char* openkey, const char* openid)
		{
			char req[1024];
			char resp[4096];
			resp[sizeof(resp)-1] = 0;
			int reqlen;
			reqlen = snprintf(req, sizeof(req),
				"GET /%s?uid=%s&token=%s HTTP/1.1\r\n"
				"Host: %s\r\n\r\n"
				,m_url.c_str(), openid, openkey, m_host.c_str());

			LOG(LOG_DEBUG, "%s, port = %d, ip = %s\n", req, m_port, m_addr.c_str());
			
			int resplen = 0;
			string body;

			if(gDebug)
				LOG(LOG_DEBUG, "%s|REQ|%s", openid, req);
			if(send_and_recv(openid, req, reqlen, resp, sizeof(resp), resplen, body)!=0)
			{
				return -1;
			}

			if(gDebug)
				LOG(LOG_DEBUG, "%s|BODY|%s", openid, body.c_str());

			//json代码
			CSimpleJSON objjson;

			if(objjson.parse(body)!=0)
			{
				LOG(LOG_ERROR, "%s|parse json fail|%s", openid, body.c_str());
				return -1;
			}

			if(gDebug)
			{
				ostringstream os;
				objjson.debug(os);
				LOG(LOG_DEBUG, "map content: %s", os.str().c_str());
			}

#define JSON_GET_ATTR(obj, attrname, attrval) \
			if(!obj.get(attrname, attrval)) \
			{ \
				LOG(LOG_ERROR, "%s|no "attrname"|%s", openid, body.c_str()); \
				return -1; \
			}

			

			int ret;
			JSON_GET_ATTR(objjson, "errno", ret)
			
			if(ret != 0)
			{
				string errmsg;
				JSON_GET_ATTR(objjson, "errmsg", errmsg)
				LOG(LOG_ERROR, "%s|ret=%d %s", openid, ret, errmsg.c_str());
				return -1;
			}

			
			return 0;
		}

		int do_reportuserinfo(const char * openid, const vector<string> &keys, const vector<string> &values)
		{
			char req[4096];
			char resp[4096];
			resp[sizeof(resp)-1] = 0;
			int reqlen;
			string dataStr = "{";
			size_t size = min(keys.size(), values.size());
			for(size_t i = 0; i < size; i++ )
			{
				if( i > 0 )
				{
					dataStr += ",";
				}
				dataStr += "\"";
				dataStr += keys[i].c_str();
				dataStr += "\":\"";
				dataStr += values[i].c_str();
				dataStr += "\"";
			}
			dataStr += "}";
			std::cout << "datastr:" << dataStr << std::endl;
			LOG(LOG_DEBUG, "dataStr = %s\n", dataStr.c_str());
			reqlen = snprintf(req, sizeof(req),
				"GET /%s?report=1&data=%s HTTP/1.1\r\n"
				"Host: %s\r\n\r\n"
				,m_url.c_str(), dataStr.c_str(), m_host.c_str());

			LOG(LOG_DEBUG, "%s, port = %d, ip = %s\n", req, m_port, m_addr.c_str());

			int resplen = 0;
			string body;

			if(gDebug)
				LOG(LOG_DEBUG, "%s|REQ|%s", openid, req);
			if(send_and_recv(openid, req, reqlen, resp, sizeof(resp), resplen, body)!=0)
			{
				return -1;
			}

			if(gDebug)
				LOG(LOG_DEBUG, "%s|BODY|%s", openid, body.c_str());

			//json代码
			CSimpleJSON objjson;

			if(objjson.parse(body)!=0)
			{
				LOG(LOG_ERROR, "%s|parse json fail|%s", openid, body.c_str());
				return -1;
			}

			if(gDebug)
			{
				ostringstream os;
				objjson.debug(os);
				LOG(LOG_DEBUG, "map content: %s", os.str().c_str());
			}

#define JSON_GET_ATTR(obj, attrname, attrval) \
	if(!obj.get(attrname, attrval)) \
			{ \
			LOG(LOG_ERROR, "%s|no "attrname"|%s", openid, body.c_str()); \
			return -1; \
			}

			int ret;
			JSON_GET_ATTR(objjson, "errno", ret)

				if(ret != 0)
				{
					string errmsg;
					JSON_GET_ATTR(objjson, "errmsg", errmsg)
						LOG(LOG_ERROR, "%s|ret=%d %s", openid, ret, errmsg.c_str());
					return -1;
				}


				return 0;
		}

		int do_send_logic_info(const string &ip, int port, int idx, int max_client,
				int cur_client, const string &version, const string &host_ip,
				int max_reg, int cur_reg)
		{
			char req[1024];
			int reqlen;
			reqlen = snprintf(req, sizeof(req),
				"GET /inn?idx=%d&ip=%s&port=%d&ver=%s&max_client=%d&cur_client=%d&mr=%d&cr=%d HTTP/1.1\r\n"
				"Host: %s\r\n\r\n"
				,idx, ip.c_str(), port, version.c_str(), max_client, cur_client, max_reg, cur_reg, host_ip.c_str());

			if(gDebug)
				LOG(LOG_DEBUG, "send logic info|%s", req);
			if(just_send(req, reqlen)!=0)
			{
				return -1;
			}
			
			return 0;
		}

		int do_send2globalcb(int port, int idx, const string &global_ip)
		{
			char req[1024];
			int reqlen;
			reqlen = snprintf(req, sizeof(req),
				"GET /inn?sid=%d&pt=%d HTTP/1.1\r\n"
				"Host: %s\r\n\r\n"
				,idx, port, global_ip.c_str());

			if(gDebug)
				LOG(LOG_DEBUG, "send logic info|%s", req);
			if(just_send(req, reqlen)!=0)
			{
				return -1;
			}
			
			return 0;
		}

	protected:

		int parse_http(const char* openid, const char* resp, int resplen, string& body)
		{
#if	0
			char* contentlength = strstr(resp, "Content-Length:");
			if(contentlength == NULL)
			{
				LOG(LOG_ERROR, "%s|Content-Length start not found", openid);
				return -1;
			}

			char* contentlengthstart = contentlength+15;
			const char* contentlengthend = strstr(contentlengthstart, "\r\n");
			if(contentlengthend== NULL)
			{
				LOG(LOG_ERROR, "%s|Content-Length end not found", openid);
				return -1;
			}

			string strcttlen(contentlengthstart, contentlengthend-contentlengthstart);
			int cttlen = atoi(strcttlen.c_str());
if(gDebug)
	LOG(LOG_DEBUG, "cttlen=%d", cttlen);
			const char* headend = strstr(contentlengthend, "\r\n\r\n");
			if(headend == NULL)
			{
				LOG(LOG_ERROR, "%s|head end not found", openid);
				return -1;
			}
#else 
			const char* headend = strstr(resp, "\r\n\r\n");
			if(headend == NULL)
			{
				LOG(LOG_ERROR, "%s|head end not found", openid);
				return -1;
			}
#endif
			headend += 4;

#if	0
if(gDebug)
	LOG(LOG_DEBUG, "content_end_len=%ld and resplen=%d", (headend-resp) + cttlen, resplen);
			if((headend-resp) + cttlen > resplen)
			{
				//LOG(LOG_ERROR, "%s|packet incompelete", openid);
				//need read more
				return 1;
			}

			body.assign(headend, cttlen);
#else
			//看下是否空的
if(gDebug)
	LOG(LOG_DEBUG, "content_end_len=%ld and resplen=%d", headend-resp, resplen);
			if(headend - resp >= resplen)
			{
				//LOG(LOG_ERROR, "%s|packet incompelete", openid);
				return 1;
			}
			body = headend;
#endif
			return 0;
		}
		
		int send_and_recv(const char* openid, const char* req, int reqlen, char* resp, int respmax, int& resplen, string& body)
		{
			CTcpClientSocket sock;
			if(sock.init() !=0)
			{
				LOG(LOG_ERROR, "%s|init fail %s", openid, sock.errmsg());
				return -1;
			}

			if(sock.set_snd_timeout(1)!=0)
			{
				LOG(LOG_ERROR, "%s|set_snd_timeout fail %s", openid, sock.errmsg());
			}

			if(sock.set_rcv_timeout(1)!=0)
			{
				LOG(LOG_ERROR, "%s|set_rcv_timeout fail %s", openid, sock.errmsg());
			}
			
			if(sock.connect(addr(), port()) != 0)
			{
				LOG(LOG_ERROR, "%s|connect fail %s", openid, sock.errmsg());
				return -1;
			}

			if(sock.write(req,reqlen) < 0)
			{
				LOG(LOG_ERROR, "%s|write fail %s", openid, sock.errmsg());
				return -1;
			}

			int readlen = sock.read(resp,respmax-1); 
			if(readlen < 0)
			{
				LOG(LOG_ERROR, "%s|read fail %s", openid,sock.errmsg());
				return -1;
			}
			else if(readlen == 0)
			{
				LOG(LOG_ERROR, "%s|read peer closed", openid);
				return -1;
			}
			/*
	int readlen = snprintf(resp, respmax, "%s",
							"HTTP/1.1 200 OK\r\n"
	"Server: nginx/1.0.10\r\n"
	"Date: Tue, 13 Dec 2011 02:00:54 GMT\r\n"
	"Content-Type: text/html\r\n"
	"Transfer-Encoding: chunked\r\n"
	"Connection: keep-alive\r\n"
	"X-Powered-By: PHP/5.3.8\r\n"
	"Set-Cookie: PHPSESSID=f4l3ls0to4o845s8fl27n9hdu3; path=/\r\n"
	"Expires: Thu, 19 Nov 1981 08:52:00 GMT\r\n"
	"Cache-Control: no-store, no-cache, must-revalidate, post-check=0, pre-check=0\r\n"
	"Pragma: no-cache\r\n"
	"\r\n"
	"12c\r\n"
	"{\"ret\":0,\"userid\":\"00000000000000000000000009A6E73C\",\"nickname\":\"\\u6e29\\u663e\\u658c\",\"gender\":1,\"province\":\""
	"\\u4e0a\\u6d77\",\"city\":\"\\u6d66\\u4e1c\\u65b0\",\"figureurl\":\"http:\\/\\/pyapp.qlogo.cn\\/campus\\/d272637dc1af902a61b3"
	"decca0abc5303f16def3191ac81e3e54db07fe54862afb25e9897043117c\\/60\",\"ext1\":0,\"ext2\":0}\r\n0\r\n\r\n");
			*/

			resp[readlen] = 0;
			resplen = readlen;
			if(gDebug)
				LOG(LOG_DEBUG, "%s|RESP|%d|%s", openid, resplen, resp);

			//获取body
			int parseret = parse_http(openid, resp, resplen, body);
			if(parseret < 0)
			{
				return -1;
			}
			else if(parseret == 1)
			{
				readlen = sock.read(resp+readlen, respmax-1-readlen);
				if(readlen < 0)
				{
					LOG(LOG_ERROR, "read fail %s", sock.errmsg());
					return -1;
				}
				else if(readlen == 0)
				{
					LOG(LOG_ERROR, "read peer closed");
					return -1;
				}

				resplen += readlen;
				resp[resplen] = 0;
				
				if(gDebug)
					LOG(LOG_DEBUG, "%s|RESP|%d(%d)|%s", openid, resplen, readlen, resp);

				//最多两次
				parseret = parse_http(openid, resp, resplen, body);
				if(parseret < 0)
				{
					return -1;
				}
				else if(parseret == 1)
				{
					LOG(LOG_ERROR, "%s|packet incomplete", openid);
				}
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
		string m_url;
		string m_host;
		unsigned short m_port;
};

#endif

