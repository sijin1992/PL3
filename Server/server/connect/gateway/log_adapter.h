#ifndef __GATEWAY_LOG_ADAPTER_H__
#define __GATEWAY_LOG_ADAPTER_H__

//#include "../../../ext/DC_CPP_SDK_V1.1/inc/dcapi_cpp.h"
#include "proto/gateway.pb.h"
#include "log/log.h"
#include <iconv.h>
#include "common/msg_define.h"
#include <iostream>
#include <sstream>
#include <fstream>
#include <map>
#include "net/tcpwrap.h"
using namespace std;

#define QQ_LOG_APP_NAME "appoperlog"
#define QQ_LOG_APP_ID 100618305
#define QQ_LOG_VERSION 111

#define QQ_LOG_DOMAIN_QZONE 1
#define QQ_LOG_DOMAIN_PENGYOU 2 
#define QQ_LOG_WORLD 1

class CQQLogAdapter
{
	public:
		int init(string serverip, int* pdebug = NULL)
		{
			m_version = QQ_LOG_VERSION;
			m_appid = QQ_LOG_APP_ID;
			string logname = QQ_LOG_APP_NAME;
			int ret = 0;//m_qqLoger.init(logname);
			if(ret!=0)
			{
				LOG(LOG_ERROR, "CLogger init fail %d", ret);
				return -1;
			}

			CTcpSocket::str_to_addr(serverip,m_svrip);

			m_debug = pdebug;
			m_domain = QQ_LOG_DOMAIN_PENGYOU; //默认一个
			m_type = 0;

			LOG(LOG_INFO, "CLogger(%s) inited", logname.c_str());
			return 0;
		}

		inline void set_domain(int domain)
		{
			m_domain = domain;
		}

		inline int get_domain()
		{
			return m_domain;
		}

		inline int get_svrip()
		{
			return m_svrip;
		}

		int log(USER_NAME& user, QQLogReq& req)
		{
			int ret = 0;
			m_type = req.logtype();

			if(req.has_domain() && req.domain()!=0)
			{
				set_domain(req.domain());
			}
			
			if(m_type == req.REGIST)
			{
				if(req.values_size() < 1)
				{
					ret = -1;
					LOG(LOG_ERROR, "req.REGIST need 1 args");
				}
				ret = regist_log(req.userip(), user.str(), req.userkey(), req.values(0));
			}
			else if(m_type == req.LOGIN)
			{
				if(req.values_size() < 1)
				{
					ret = -1;
					LOG(LOG_ERROR, "req.LOGIN need 1 args");
				}
				ret = login_log(req.userip(), user.str(), req.userkey(), atoi(req.values(0).c_str()));
			}
			else if(m_type == req.LOGOUT)
			{
				if(req.values_size() < 1)
				{
					ret = -1;
					LOG(LOG_ERROR, "req.LOGOUT need 1 args");
				}
				else
					ret = logout_log(req.userip(), user.str(), req.userkey(), atoi(req.values(0).c_str()));
			}
			else if(m_type == req.PAYMENT)
			{
				if(req.values_size() < 5)
				{
					ret = -1;
					LOG(LOG_ERROR, "req.LOGOUT need 5 args");
				}
				ret = pay_log(req.userip(), user.str(), req.userkey(), 
					atoi(req.values(0).c_str()), atoi(req.values(1).c_str()), 
					atoi(req.values(2).c_str()), atoi(req.values(3).c_str()),
					atoi(req.values(4).c_str()));
			}
			else if(m_type == req.ONLINE_STAT)
			{
				if(req.values_size() < 1)
				{
					ret = -1;
					LOG(LOG_ERROR, "req.ONLINE_STAT need 1 args");
				}
				else
					ret = stat_log(atoi(req.values(0).c_str()));
			}
			else
			{
				ret = -1;
				LOG(LOG_ERROR, "logtype=%d not implement", m_type);
			}

			return ret;
		}

		//oss.ieodopen.qq.com/logdebug/Home
		int regist_log(unsigned int userip, string useropenid, string openkey, string iopenkey)
		{
			ostringstream os;
			
			os << "version=" << m_version
				<< "&appid=" << m_appid
				<< "&userip=" << userip
				<< "&svrip=" << m_svrip
				<< "&time=" << (unsigned int)time(NULL)
				<< "&domain=" << m_domain
				<< "&worldid=" << QQ_LOG_WORLD
				<< "&optype=" << 3;
			if(iopenkey.length() > 0)
			{
				os << "&actionid=" << 3;
			}
			else
			{
				os << "&actionid=" << 2;
			}
				os << "&opuid=" << get_uid(useropenid)
				<< "&opopenid=" << useropenid
				<< "&touid=" //<< 
				<< "&toopenid=" //<<
				<< "&level=" //<<
				<< "&source=" //<<
				<< "&itemid=" //<<
				<< "&itemtype=" //<<
				<< "&itemcnt=" //<<
				<< "&modifyexp=" //<<
				<< "&totalexp=" //<<
				<< "&modifycoin=" //<<
				<< "&totalcoin=" //<<
				<< "&modifyfee=" //<<
				<< "&totalfee=" //<<
				<< "&onlinetime=" //<<
				<< "&key=" << openkey
				<< "&keycheckret=&safebuf=&remark=&user_num=";

			return write_baselog(os);
		}

		int login_log(unsigned int userip, string useropenid, string openkey, int level)
		{
			ostringstream os;
			
			os << "version=" << m_version
				<< "&appid=" << m_appid
				<< "&userip=" << userip
				<< "&svrip=" << m_svrip
				<< "&time=" << (unsigned int)time(NULL)
				<< "&domain=" << m_domain
				<< "&worldid=" << QQ_LOG_WORLD
				<< "&optype=" << 4
				<< "&actionid=" << 1
				<< "&opuid=" << get_uid(useropenid)
				<< "&opopenid=" << useropenid
				<< "&touid=" //<< 
				<< "&toopenid="; //<<
				if(level <= 0)
					os << "&level="; //<<
				else
					os << "&level=" << level;
				os << "&source=" //<<
				<< "&itemid=" //<<
				<< "&itemtype=" //<<
				<< "&itemcnt=" //<<
				<< "&modifyexp=" //<<
				<< "&totalexp=" //<<
				<< "&modifycoin=" //<<
				<< "&totalcoin=" //<<
				<< "&modifyfee=" //<<
				<< "&totalfee=" //<<
				<< "&onlinetime=" //<<
				<< "&key=" << openkey
				<< "&keycheckret=&safebuf=&remark=&user_num=";


			return write_baselog(os);
		}

		int logout_log(unsigned int userip, string useropenid, string openkey, int onlinetime)
		{
			ostringstream os;
			
			os << "version=" << m_version
				<< "&appid=" << m_appid
				<< "&userip=" << userip
				<< "&svrip=" << m_svrip
				<< "&time=" << (unsigned int)time(NULL)
				<< "&domain=" << m_domain
				<< "&worldid=" << QQ_LOG_WORLD
				<< "&optype=" << 4
				<< "&actionid=" << 9
				<< "&opuid=" << get_uid(useropenid)
				<< "&opopenid=" << useropenid
				<< "&touid=" //<< 
				<< "&toopenid=" //<<
				<< "&level=" //<<
				<< "&source=" //<<
				<< "&itemid=" //<<
				<< "&itemtype=" //<<
				<< "&itemcnt=" //<<
				<< "&modifyexp=" //<<
				<< "&totalexp=" //<<
				<< "&modifycoin=" //<<
				<< "&totalcoin=" //<<
				<< "&modifyfee=" //<<
				<< "&totalfee=" //<<
				<< "&onlinetime=" << onlinetime
				<< "&key=" << openkey
				<< "&keycheckret=&safebuf=&remark=&user_num=";
		
		
			return write_baselog(os);
		}

		int pay_log(unsigned int userip, string useropenid, string openkey, int money, int itemid, int itemtype, int itemcnt, int level)
		{
			ostringstream os;
			
			os << "version=" << m_version
				<< "&appid=" << m_appid
				<< "&userip=" << userip
				<< "&svrip=" << m_svrip
				<< "&time=" << (unsigned int)time(NULL)
				<< "&domain=" << m_domain
				<< "&worldid=" << QQ_LOG_WORLD
				<< "&optype=" << 1
				<< "&actionid=" << 5
				<< "&opuid=" << get_uid(useropenid)
				<< "&opopenid=" << useropenid
				<< "&touid=" //<< 
				<< "&toopenid=" ; //<<
				if(level <= 0)
					os << "&level="; //<<
				else
					os << "&level=" << level;
				os << "&source=" //<<
				<< "&itemid="  << itemid
				<< "&itemtype=" << itemtype
				<< "&itemcnt="  << itemcnt
				<< "&modifyexp=" //<<
				<< "&totalexp=" //<<
				<< "&modifycoin=" //<<
				<< "&totalcoin=" //<<
				<< "&modifyfee=" << money
				<< "&totalfee=" //<<
				<< "&onlinetime=" //<< 
				<< "&key=" << openkey
				<< "&keycheckret=&safebuf=&remark=&user_num=";
		
		
			return write_baselog(os);
		}	
		int stat_log(int onlineusernum, bool realreport=false)
		{
		//不能分机器上报，需要汇总后上报
			if(!realreport)
			{
				ofstream of2("/tmp/online.txt");
				if(!of2.good())
				{
					LOG(LOG_ERROR, "open /tmp/online.txt fail");
					return -1;
				}
				
				of2 << onlineusernum << endl;

				return 0;
			}
			
			ostringstream os;
			
			os << "version=" << m_version
				<< "&appid=" << m_appid
				<< "&userip=" //<< userip
				<< "&svrip=" << m_svrip
				<< "&time=" << (unsigned int)time(NULL)
				<< "&domain=" << m_domain
				<< "&worldid=" << QQ_LOG_WORLD
				<< "&optype=" << 5
				<< "&actionid=" << 14
				<< "&opuid=" << QQ_LOG_WORLD //<< get_uid(useropenid)
				<< "&opopenid=" << QQ_LOG_WORLD //<< useropenid
				<< "&touid=" //<< 
				<< "&toopenid=" //<<
				<< "&level=" //<<
				<< "&source=" //<<
				<< "&itemid=" //<<
				<< "&itemtype=" //<<
				<< "&itemcnt=" //<<
				<< "&modifyexp=" //<<
				<< "&totalexp=" //<<
				<< "&modifycoin=" //<<
				<< "&totalcoin=" //<<
				<< "&modifyfee=" //<<
				<< "&totalfee=" //<<
				<< "&onlinetime=" //<<
				<< "&key=" //<< openkey
				<< "&keycheckret=&safebuf=&remark=&user_num=" << onlineusernum;
		
			return write_baselog(os);
		}

	public:
		inline int write_baselog(ostringstream& os)
		{
			//DataCollector::logtype type = DataCollector::LT_NORMAL;
			string output = os.str();
			int ret = 0;//m_qqLoger.write_baselog(type, output, true);
			LOG(LOG_INFO, "write=%d|%s", ret, output.c_str());

			if(m_debug && *m_debug)
			{
				printf("write=%d|%s\n", ret, output.c_str());
			}


			if(ret != 0)
			{
				LOG(LOG_ERROR, "CLogger init fail %d", ret);
				return -1;
			}
			return 0;
		}

		inline unsigned int get_uid(string& openid)
		{
			char buff[32];
			int len = openid.length();
			if(len > 32)
			{
				len = 32;
			}
			memcpy(buff, openid.c_str(), len);
			int offset = 0;
			if(len > 8)
			{
				offset = len-8;
			}
			return strtoull(openid.c_str()+offset, NULL, 16);
		}
			
/*		static int gbk_to_utf8_short(string& str)
		{
		        const char* inbuf = str.c_str();
		        size_t inleft = str.length();
		        char outbuf[128];
		        size_t outleft = sizeof(outbuf)-1;

		        if( CodeConvert("gbk","utf-8",inbuf,inleft,outbuf,outleft) != 0)
		        {
		                return -1;
		        }

		        outbuf[sizeof(outbuf)-outleft-1] = 0;
		        str = outbuf;

		        return 0;
		}
		static int CodeConvert(const char* from_charset,const char* to_charset, const char* inbuf, size_t inleft, char* outbuf, size_t& outleft)
		{
			char** pin = const_cast<char**>(&inbuf);
			char** pout = &outbuf;
			iconv_t cd = iconv_open(to_charset, from_charset);
			if (cd == 0)
				return -1;
	
			while (true)
			{
					int ret = iconv(cd, pin, &inleft, pout, &outleft);
					if (ret < 0)
					{
						return -1;
					}
	
					break;
			}
	
			iconv_close(cd);
			return 0;
		}*/
	
	protected:
		//DataCollector::CLogger m_qqLoger;
		int m_version;
		int m_appid;
		char m_writebuff[4096];
		unsigned int m_svrip;
		int* m_debug;
		int m_domain;
		int m_type;
};

#endif

