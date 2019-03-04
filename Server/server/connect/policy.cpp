#include <iostream>
#include <string>
#include "struct/common_def.h"
#include "net/tcpwrap.h"
#include "net/epoll_wrap.h"
#include "log/log.h"
#include "../common/server_tool.h"
#include "../common/packet_interface.h"
#include "../common/queue_pipe.h"
#include "../logic/msg.h"
#include "../logic/msg_queue.h"
#include "../logic/toolkit.h"
#include "connect_protocol.h"
#include "ini/ini_file.h"
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

using namespace std;

int gDebug;
const char* gReqString = "<policy-file-request/>";
int gReqStrLen = 0;
char gPolicyFileBuff[10240];
int gPolicyFileLen=0;


class CPolicyControl: public CControlInterface
{
public:
	CPolicyControl()
	{
		m_pepoll = NULL;
	}

	void set_epoll(CEpollWrap* pepoll)
	{
		m_pepoll = pepoll;
	}
	
	virtual int pass_packet(int fd, unsigned long long sessionID, const char* packet, unsigned int packetLen) 
	{
		if(gDebug)
		{
			CEpollWrap::UN_SESSION_ID uSession;
			uSession.id = sessionID;
			LOG(LOG_DEBUG, "client(fd=%d,%s:%d,%d) pass_packet(len=%u)|%s", 
				fd, CTcpSocket::addr_to_str(uSession.tcpaddr.ip).c_str(), uSession.tcpaddr.port, uSession.tcpaddr.seq,packetLen, packet);
		}

		do{
			//是否是http请求
			if(packetLen >= TWG_HTTP_HEAD_LEN && strncmp(packet, TWG_HTTP_HEAD, TWG_HTTP_HEAD_LEN) == 0)
			{
				if(gDebug)
				{
					LOG(LOG_DEBUG, "reciecv http request ignored");
				}
				
				const char* httpend = strstr(packet, "\r\n\r\n");
				if(httpend != NULL)
				{
					int htmllen = httpend+4 - packet;
					if(htmllen>=(int)packetLen)
					{
						break;
					}
					
					if(gDebug)
					{
						LOG(LOG_DEBUG, "there is a package after http at(%d,%d)", htmllen, packetLen);
					}

					packet = packet+htmllen;
					packetLen -= htmllen;
				}
				else
				{
					break;
				}
			}

			//请求对不对?
			if((int)packetLen < gReqStrLen)
			{
				LOG(LOG_ERROR, "req too small");
				break;
			}

			if(strncmp(packet, gReqString, gReqStrLen) != 0)
			{
				LOG(LOG_ERROR, "packet not reqString");
				break;
			}

			//把\0也发送过去
			if(m_pepoll->write_packet(fd, sessionID, gPolicyFileBuff, gPolicyFileLen+1) != 0)
			{
				break;
			}
		}while(0);

		if(gDebug)
		{
			LOG(LOG_DEBUG, "send|%s", gPolicyFileBuff);
		}

		//总是关闭
		return 1;
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
};

class CPolicy
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

	CPolicy()
	{
		m_pepoll = NULL;
		m_inited = false;
	}

	~CPolicy()
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

		//request很小，钉死1024字节
		m_pepoll->set_pack_buff_size(1024);
		
		ret = m_pepoll->create(conf.maxclients);
		if(ret !=0)
		{
			LOG(LOG_ERROR,"m_pepoll->create=%d %s", ret, m_pepoll->errmsg());
			return -1;
		}

		ret = m_pepoll->add_listen(conf.ip, conf.port);
		if(ret !=0)
		{
			LOG(LOG_ERROR,"m_pepoll->add_listen=%d %s", ret, m_pepoll->errmsg());
			return -1;
		}

		unsigned int time_sec = conf.epollTimeoutUs/1000000;
		unsigned int time_microsec = conf.epollTimeoutUs%1000000;

		m_control.set_epoll(m_pepoll);
		
		while(!STOP_FLAG)
		{
			//epoll
			ret = m_pepoll->do_poll(time_sec, time_microsec);
			if(ret !=0)
			{
				LOG(LOG_ERROR,"m_pepoll->do_poll=%d %s", ret, m_pepoll->errmsg());
			}

			//更新下时间,用不到
			//gettimeofday(&timenow,NULL);
		}

		return 0;
	}

public:
	static int STOP_FLAG;
	
protected:
	CEpollWrap* m_pepoll;
	bool m_inited;
	CRawPackInterface m_raw;
	CPolicyControl m_control;
};

int CPolicy::STOP_FLAG = 0;

static void stophandle(int iSigNo)
{
	CPolicy::STOP_FLAG = 1;
	LOG(LOG_INFO, "recieve siganal %d, stop",  iSigNo);
	LOG(LOG_ERROR, "recieve siganal %d, stop",  iSigNo);
}

static void usr1handle(int iSigNo)
{
	gDebug = (gDebug+1)%2;
	cout << "policy debug=" << gDebug;
}

int main(int argc, char** argv)
{
	if(argc < 2)
	{
		cout << argv[0] << " connect_config_ini" << endl;
		return 0;
	}

	CPolicy policy;
	CPolicy::CONFIG config;

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
	config.logConf.read_from_ini(oIni, "POLICY");	
	LOG_CONFIG_SET(config.logConf);
	cout << "log open=" << LOG_OPEN_DEFAULT(NULL) << " " << LOG_GET_ERRMSGSTRING << endl;

	if( oIni.GetString("POLICY", "SERVER_IP", "", ip, sizeof(ip)) != 0)
	{
		cout << "POLICY.SERVER_IP not found" << endl;
		return 0;
	}

	if(oIni.GetInt("POLICY", "SERVER_PORT", 0,&port) != 0)
	{
		cout << "POLICY.SERVER_PORT not found" << endl;
		return 0;
	}

	oIni.GetInt("POLICY", "EPOLL_TIMEOUT_US", 1000,&epollTimeoutUs);
	config.ip = ip;
	config.port = port;
	config.epollTimeoutUs = epollTimeoutUs; //1ms


	oIni.GetInt("POLICY", "MAX_CLIENTS",  1000,&(config.maxclients));
	
	config.debug(cout);

	char policyFilePath[1024] = {0};
	if(oIni.GetString("POLICY", "FILE_PATH", "", policyFilePath, sizeof(policyFilePath))!=0 || strlen(policyFilePath)==0)
	{
		cout << "POLICY.FILE_PATH not found or not valid" << endl;
		return 0;
	}

	FILE * pfile = fopen(policyFilePath, "r");
	if(pfile == NULL)
	{
		cout << "fopen(" << policyFilePath << ")=" << errno << " " << strerror(errno) << endl;
		return 0;
	}

	gReqStrLen = strlen(gReqString);
	gPolicyFileLen = fread(gPolicyFileBuff, 1, sizeof(gPolicyFileBuff)-1, pfile);
	if(gPolicyFileLen == 0)
	{
		cout << "fread = 0" << endl;
		return 0;
	}
	gPolicyFileBuff[gPolicyFileLen] = '\0';

	cout << "use file[" << policyFilePath << "]:"<< endl;
	cout << gPolicyFileBuff << endl;

	//lock & daemon
	if(CServerTool::run_by_ini(&oIni, "POLICY")!=0)
	{
		cout << "run_by_ini fail" << endl;
		return 0;
	}

	CServerTool::sighandle(SIGTERM, stophandle);
	CServerTool::sighandle(SIGUSR1, usr1handle);
	CServerTool::ignore(SIGPIPE);

	//start server
	int ret = policy.start(config);
	if(ret != 0)
	{
		cout << "start =" << ret << endl;
		return 0;
	}

	return 1;
}

