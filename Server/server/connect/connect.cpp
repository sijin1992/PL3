#include <iostream>
#include <string>
#include "struct/common_def.h"
#include "net/tcpwrap.h"
#include "net/epoll_wrap.h"
#include "log/log.h"
#include "string/strutil.h"
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
#include <set>
#include <map>

#include "broadcast_manager.h"
using namespace std;

struct fd_id_pack
{
	int fd;
	unsigned long long id;
};

typedef map<int, fd_id_pack> my_fd_set;
typedef map<int, my_fd_set*> fd_map;
class room_manager
{
public:
	~room_manager()
	{
		for(fd_map::iterator it = m_map.begin(); it != m_map.end(); ++it)
		{
			if(it->second != NULL)
				delete it->second;
		}
	}
	
	void add(int _fd, unsigned long long id, int room_id)
	{
		remove(_fd);
		fd_id_pack pack;
		pack.fd = _fd;
		pack.id = id;
		fd_map::iterator it = m_map.find(room_id);
		if(it == m_map.end())
		{
			LOG(LOG_DEBUG, "new room");
			my_fd_set* t_fd_set = NULL;
			t_fd_set = new(std::nothrow) my_fd_set;
			if(t_fd_set == NULL)
			{
				LOG(LOG_ERROR, "new fd_set err");
				return;
			}
			m_map.insert(pair<int, my_fd_set*>(room_id, new my_fd_set));
			it = m_map.find(room_id);
		}
		it->second->insert(pair<int, fd_id_pack>(_fd, pack));
	}
	
	void remove(int _fd)
	{
		fd_map::iterator it;
		my_fd_set::iterator it_set;
		for(it = m_map.begin(); it != m_map.end(); ++it)
		{
			it_set = it->second->find(_fd);
			if(it_set != it->second->end())
			{
				it->second->erase(it_set);
				LOG(LOG_DEBUG, "%d remove from room_id %d", _fd, it->first);
				break;
			}
		}
	}

	void get_fd_set(int room_id, my_fd_set** sets)
	{
		*sets = NULL;
		fd_map::iterator it = m_map.find(room_id);
		if(it != m_map.end())
		{
			*sets = it->second;
		}
	}

private:
	fd_map m_map;
};

room_manager g_room_manager;

fd_map g_fd_map;

int gDebugFlag = 0;
int gInfoDetail = 0;


int gReqStrLen = 0;
char gPolicyFileBuff[10240];
int gPolicyFileLen=0;


class CConnectControl: public CControlInterface
{
public:
	CConnectControl(CMsgQueuePipe * p)
	{
		m_pqueue = p;
		m_pepoll=NULL;
	}

	
	virtual int hook_create(CEpollWrap* host) 
	{
		m_pepoll = host;
		return 0;
	}
	
	virtual int pass_packet(int fd, unsigned long long sessionID, const char* packet, unsigned int packetLen) 
	{
		if(gDebugFlag)
		{
			CEpollWrap::UN_SESSION_ID uSession;
			uSession.id = sessionID;
			LOG(LOG_DEBUG, "client(fd=%d,%s:%d,%d) pass_packet(len=%u)", 
			fd, CTcpSocket::addr_to_str(uSession.tcpaddr.ip).c_str(), uSession.tcpaddr.port, uSession.tcpaddr.seq,packetLen);
		}

		//是否是http请求
		if(packetLen >= TWG_HTTP_HEAD_LEN && strncmp(packet, TWG_HTTP_HEAD, TWG_HTTP_HEAD_LEN) == 0)
		{
			if(gDebugFlag)
			{
				LOG(LOG_DEBUG, "reciecv http request ignored");
			}

			//防止http和后面的包连接在一起
			const char* httpend = strstr(packet, "\r\n\r\n");
			if(httpend != NULL)
			{
				int htmllen = httpend+4 - packet;
				if(htmllen>=(int)packetLen)
				{
					return 0;
				}
				
				if(gDebugFlag)
				{
					LOG(LOG_DEBUG, "there is a package after http at(%d,%d)", htmllen, packetLen);
				}

				packet = packet+htmllen;
				packetLen -= htmllen;
			}
			else
			{
				return 0;
			}
		}

		return send_msg(fd, sessionID, SESSION_FLAG_ZERO, packet, packetLen);
	}
	
	virtual void on_connect(int fd, unsigned long long sessionID) 
	{
		if(gDebugFlag)
		{
			CEpollWrap::UN_SESSION_ID uSession;
			uSession.id = sessionID;
			LOG(LOG_DEBUG, "client(session=%llu,fd=%d,%s:%d,%d) connect", uSession.id, fd, CTcpSocket::addr_to_str(uSession.tcpaddr.ip).c_str(), uSession.tcpaddr.port, uSession.tcpaddr.seq);
		}

		if(gInfoDetail)
		{
			CEpollWrap::UN_SESSION_ID uSession;
			uSession.id = sessionID;
			LOG(LOG_INFO, "client(session=%llu,fd=%d,%s:%d,%d) connect", uSession.id, fd, CTcpSocket::addr_to_str(uSession.tcpaddr.ip).c_str(), uSession.tcpaddr.port, uSession.tcpaddr.seq);
		}
	}
	
	virtual void on_close(int fd, unsigned long long sessionID) 	
	{
		if(gDebugFlag)
		{
			CEpollWrap::UN_SESSION_ID uSession;
			uSession.id = sessionID;
			LOG(LOG_DEBUG, "client(session=%llu,fd=%d,%s:%d,%d) closed", uSession.id, fd, CTcpSocket::addr_to_str(uSession.tcpaddr.ip).c_str(), uSession.tcpaddr.port, uSession.tcpaddr.seq);
		}

		if(gInfoDetail)
		{
			CEpollWrap::UN_SESSION_ID uSession;
			uSession.id = sessionID;
			LOG(LOG_INFO, "client(session=%llu,fd=%d,%s:%d,%d) closed", uSession.id,fd, CTcpSocket::addr_to_str(uSession.tcpaddr.ip).c_str(), uSession.tcpaddr.port, uSession.tcpaddr.seq);
		}
		
		send_msg(fd, sessionID, SESSION_FLAG_CLOSE, NULL, 0);
	}

protected:
	int send_msg(int fd, unsigned long long sessionID,int flag, const char* packet, unsigned int packetLen )
	{
		CConnectProtocol protocol(m_toolkit.send_buff(), m_toolkit.send_buff_len());
		MSG_SESSION* p = protocol.session();
		p->fd = fd;
		p->id = sessionID;
		p->flag = flag;

		//不可能大的
		if(protocol.packet_len() < (int)(packetLen+sizeof(MSG_SESSION)))
		{
			LOG(LOG_ERROR, "pass_packet buff too small need "PRINTF_FORMAT_FOR_SIZE_T,  packetLen+sizeof(MSG_SESSION));
			return -1;
		}
		
		if(packetLen > 0)
		{
			if(packet == NULL)
			{
				LOG(LOG_ERROR,  "%s", "packet=NULL");
				return -1;
			}
			
			memcpy(protocol.packet(), packet, packetLen);
		}

		return m_toolkit.send_to_queue(CMD_SESSION_REQ, m_pqueue, protocol.total_len(packetLen));
	}

protected:
	CToolkit m_toolkit;
	CMsgQueuePipe * m_pqueue;
	CEpollWrap* m_pepoll;
};

class CConnect
{
public:
	struct CONFIG
	{
		string ip;
		string ports;
		unsigned int maxclients;
		unsigned int epollTimeoutUs; //微妙级别
		unsigned int protocolType; //见protocol interface的定义
		string protocolEndStr; //PROTOCOL_TYPE_END时有效
		key_t shmkey_r;
		unsigned int dequesize_r;
		key_t shmkey_w;
		unsigned int dequesize_w;
		LOG_CONFIG logConf;
		key_t semKey;
		unsigned int fdIdleTimeoutS;

		CONFIG()
		{
			maxclients = 10000;
			epollTimeoutUs = 1000;
			protocolType = PROTOCOL_TYPE_BIN;
			fdIdleTimeoutS = 0;
		}

		void debug(ostream& os)
		{
			os << "CConnect::CONFIG{" << endl;
			os << "ip|" << ip << endl;
			os << "ports|" << ports << endl;
			os << "maxclients|" << maxclients << endl;
			os << "fdIdleTimeoutS|" << fdIdleTimeoutS << endl;
			os << "epollTimeoutUs|" << epollTimeoutUs << endl;
			os << "protocolType|" << protocolType << endl;
			os << "protocolEndStr|" << protocolEndStr << endl;
			os << "shmkey_r|" << hex << shmkey_r << dec << endl;
			os << "dequesize_r|" << dequesize_r << endl;
			os << "shmkey_w|" << hex << shmkey_w << dec << endl;
			os << "dequesize_w|" << dequesize_w << endl;
			os << "semKey|" << hex << semKey << dec << endl;
			os << "} end CONFIG" << endl;
		}
	};

	CConnect()
	{
		m_pepoll = NULL;
		m_ppacket = NULL;
		m_pcontrol = NULL;
		m_inited = false;
	}

	~CConnect()
	{
		if(m_ppacket)
		{
			delete m_ppacket;
			m_ppacket = NULL;
		}

		if(m_pepoll)
		{
			delete m_pepoll;
			m_pepoll = NULL;
		}

		if(m_pcontrol)
		{
			delete m_pcontrol;
			m_pcontrol = NULL;
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

		//初始化pipe
		int ret = m_pipe.init(conf.shmkey_r, conf.dequesize_r, conf.shmkey_w, conf.dequesize_w, &conf.semKey);
		if(ret != 0)
		{
			LOG(LOG_ERROR, "m_pipe.init=%d %s", ret, m_pipe.errmsg());
			return -1;
		}

		//session_pipe功能封装		
		CMsgQueuePipe queuePipe(m_pipe);
		CToolkit toolkit;

		m_pcontrol = new CConnectControl(&queuePipe);
		if(m_pcontrol == NULL)
		{
			LOG(LOG_ERROR, "%s", "new CConnectControl() fail");
			return -1;
		}

		if(conf.protocolType == PROTOCOL_TYPE_BIN)
		{	
			CBinPackInterface* ptmp = new CBinPackInterfaceNormal();
			if(ptmp == NULL)
			{
				LOG(LOG_ERROR,"%s", "new CBinPackInterface() fail");
				return -1;
			}

			ptmp->bind_flag(&gDebugFlag);
			m_ppacket = ptmp;
		}
		else if(conf.protocolType == PROTOCOL_TYPE_END)
		{
			m_ppacket = new CEndPackInterface(conf.protocolEndStr.c_str(), conf.protocolEndStr.size());
			if(m_ppacket == NULL)
			{
				LOG(LOG_ERROR,"%s", "new CEndPackInterface() fail");
				return -1;
			}
		}
		else
		{
			//字节流
			m_ppacket = new CRawPackInterface;
			if(m_ppacket == NULL)
			{
				LOG(LOG_ERROR,"%s", "new CRawPackInterface() fail");
				return -1;
			}
		}
		
		m_pepoll = new CEpollWrap(m_ppacket, m_pcontrol, &timenow);
		if(m_pepoll == NULL)
		{
			LOG(LOG_ERROR,"%s", "new CEpollWrap() fail");
			return -1;
		}

		if(conf.fdIdleTimeoutS > 0)
		{
			m_pepoll->set_session_limit(0, 0, 0, conf.fdIdleTimeoutS);
		}
		
		ret = CServerTool::ensure_max_fds(conf.maxclients);
		if(ret != 0)
		{
			LOG(LOG_ERROR,"ensure_max_fds(%u) fail %d %s", conf.maxclients, errno, strerror(errno));
			return -1;
		}

		//不去计算msg头等等长度，反正不超过1k，保证没有问题
		m_pepoll->set_pack_buff_size(RECV_PACK_SZIE_LIMIT);

		if(conf.fdIdleTimeoutS > 0)
		{
			ret = m_pepoll->create(conf.maxclients, false, true);
		}
		else
		{
			ret = m_pepoll->create(conf.maxclients);
		}
		if(ret !=0)
		{
			LOG(LOG_ERROR,"m_pepoll->create=%d %s", ret, m_pepoll->errmsg());
			return -1;
		}

		strutil::Tokenizer thetoken(conf.ports);
		while(thetoken.nextToken(","))
		{
			unsigned int port = strtoul(thetoken.getToken().c_str(), NULL, 10);
			ret = m_pepoll->add_listen(conf.ip, port);
			if(ret !=0)
			{
				LOG(LOG_ERROR,"m_pepoll->add_listen(%s,%u)=%d %s", 
					conf.ip.c_str(), port, ret, m_pepoll->errmsg());
				return -1;
			}
		}

		unsigned int time_sec = conf.epollTimeoutUs/1000000;
		unsigned int time_microsec = conf.epollTimeoutUs%1000000;
		while(!STOP_FLAG)
		{
			//epoll
			ret = m_pepoll->do_poll(time_sec, time_microsec);
			if(ret !=0)
			{
				LOG(LOG_ERROR,"m_pepoll->do_poll=%d %s", ret, m_pepoll->errmsg());
			}

			//读回包
			while(!STOP_FLAG)
			{
				char* packet = NULL;
				int packLen = 0;
				MSG_SESSION* p =NULL;
				
				//buff 可能被replace成堆内存，一个循环的生命期
				CLogicMsg msg(toolkit.readBuff, toolkit.BUFFLEN); 
				ret = queuePipe.get_msg(msg);
				if(ret == CMsgQueue::ERROR)
				{
					//底层读错会舍弃包
					break;
				}
				else if(ret == CMsgQueue::EMPTY)
				{
					//empty
					break;
				}
				
				
				CConnectProtocol protocol(toolkit.get_body(msg), toolkit.get_body_len(msg));
				packLen = protocol.packet_len();
				if(packLen > 0)
				{
					packet = protocol.packet();
				}
				else if(packLen < 0)
				{
					LOG(LOG_ERROR, "readBuffLen=%d too small", toolkit.get_body_len(msg));
					break;
				}

				p = protocol.session();

				if(p->flag == SESSION_FLAG_CLOSE)
				{
					if(gDebugFlag)
					{
						CEpollWrap::UN_SESSION_ID uSession;
						uSession.id = p->id;
						LOG(LOG_DEBUG, "close client(fd=%d,%s:%d,%d)", 
						p->fd, CTcpSocket::addr_to_str(uSession.tcpaddr.ip).c_str(), uSession.tcpaddr.port, uSession.tcpaddr.seq);
					}

					LOG(LOG_INFO, "ticked session=%llu", p->id);

					ret = m_pepoll->close_fd(p->fd,p->id);
					if(ret != 0)
					{
						LOG(LOG_ERROR,"m_pepoll->close_fd %d %s", ret, m_pepoll->errmsg());
						continue;
					}
				}
				else if(p->flag == SESSION_FLAG_BROADCAST)
				{
					if(gDebugFlag)
					{
						CEpollWrap::UN_SESSION_ID uSession;
						uSession.id = p->id;
						LOG(LOG_DEBUG, "write_broad(len=%d) client(fd=%d,%s:%d,%d)", 
						packLen, p->fd, CTcpSocket::addr_to_str(uSession.tcpaddr.ip).c_str(), uSession.tcpaddr.port, uSession.tcpaddr.seq);
					}
					m_broadcast.addBroadcast(packet, packLen, 0);
				}
				else if(p->flag == SESSION_FLAG_ZERO)
				{
					if(gDebugFlag)
					{
						CEpollWrap::UN_SESSION_ID uSession;
						uSession.id = p->id;
						LOG(LOG_DEBUG, "write_packet(len=%d) client(fd=%d,%s:%d,%d)", 
						packLen, p->fd, CTcpSocket::addr_to_str(uSession.tcpaddr.ip).c_str(), uSession.tcpaddr.port, uSession.tcpaddr.seq);
					}
					ret = m_pepoll->write_packet(p->fd,p->id, packet, packLen);
				
					if(ret != 0)
					{
						LOG(LOG_ERROR,"m_pepoll->write_packet %d %s", ret, m_pepoll->errmsg());
						continue;
					}
				}
				else if(p->flag == SESSION_FLAG_ADD)
				{
					int channel_id = p->channel_id;
					LOG(LOG_DEBUG, "channel_id = %d", channel_id);
					g_room_manager.add(p->fd, p->id, channel_id);
				}
				else if(p->flag == SESSION_FLAG_REMOVE)
				{
					int channel_id = p->channel_id;
					LOG(LOG_DEBUG, "channel_id = %d", channel_id);
					g_room_manager.remove(p->fd);
				}
				else if(p->flag == SESSION_FLAG_SYNC)
				{
					int channel_id = p->channel_id;
					my_fd_set* sets = NULL;
					g_room_manager.get_fd_set(channel_id, &sets);
					if(sets == NULL)
					{
						LOG(LOG_ERROR, "sync channel %d err, no fd set", channel_id);
					}
					else
					{
						if(gDebugFlag)
						{
							LOG(LOG_DEBUG, "sync room %d, len %d", 
								channel_id, packLen);
						}
						for(my_fd_set::iterator it = sets->begin(); it != sets->end(); ++it)
						{
							ret = m_pepoll->write_packet(it->second.fd, it->second.id, packet, packLen);
				
							if(ret != 0)
							{
								LOG(LOG_ERROR,"m_pepoll->write_packet %d %s", ret, m_pepoll->errmsg());
								continue;
							}
						}
					}
				}
			}
			if( !STOP_FLAG && m_broadcast.needBroadcast() )
			{
				int ret = m_broadcast.doBroadcast(m_pepoll);
				if( ret != 0 )
				{
					LOG(LOG_ERROR,"doBroadcast ret = %d", ret);
				}
			}
			//更新下时间
			gettimeofday(&timenow,NULL);
		}
		return 0;
	}

public:
	static int STOP_FLAG;
	
protected:
	CEpollWrap* m_pepoll;
	CDequePIPE m_pipe;
	bool m_inited;
	CPacketInterface* m_ppacket;
	CControlInterface* m_pcontrol;
	char m_localbuff[CEpollWrap::SIZE_BUFF_LIMIT];
	CBroadcastManager m_broadcast;
};

int CConnect::STOP_FLAG = 0;

static void stophandle(int iSigNo)
{
	CConnect::STOP_FLAG = 1;
	LOG(LOG_INFO, "recieve siganal %d, stop",  iSigNo);
	LOG(LOG_ERROR, "recieve siganal %d, stop",  iSigNo);
}

static void usr1handle(int iSigNo)
{
	gDebugFlag = (gDebugFlag+1)%2;
	cout << "debug=" << gDebugFlag << endl;
}

static void usr2handle(int iSigNo)
{
	gInfoDetail = (gInfoDetail+1)%2;
	cout << "info=" << gInfoDetail << endl;
}


int main(int argc, char** argv)
{
	if(argc < 3)
	{
		cout << argv[0] << " connect_config_ini pipe_conf_ini" << endl;
		return 0;
	}

	CConnect connect;
	CConnect::CONFIG config;

	CIniFile oIni(argv[1]);
	if(!oIni.IsValid())
	{
		cout << "read ini " << argv[1] << " fail" << endl;
		return 0;
	}

	char ip[64] = {0}; 
	int epollTimeoutUs = 0;
	char sports[256] = {0};
	int globeID = 0;

	//open log
	config.logConf.read_from_ini(oIni, "CONNECT");	
	LOG_CONFIG_SET(config.logConf);
	cout << "log open=" << LOG_OPEN("connect",LOG_DEBUG) << " " << LOG_GET_ERRMSGSTRING << endl;

	if( oIni.GetString("CONNECT", "SERVER_IP", "", ip, sizeof(ip)) != 0)
	{
		cout << "CONNECT.SERVER_IP not found" << endl;
		return 0;
	}

	if(oIni.GetString("CONNECT", "SERVER_PORT", "", sports, sizeof(sports)) != 0)
	{
		cout << "CONNECT.SERVER_PORT not found" << endl;
		return 0;
	}

	if(oIni.GetInt("CONNECT", "GLOBE_PIPE_ID", 0,&globeID) != 0)
	{
		cout << "CONNECT.GLOBE_PIPE_ID not found" << endl;
		return 0;
	}

	oIni.GetInt("CONNECT", "EPOLL_TIMEOUT_US", 1000,&epollTimeoutUs);
	config.ip = ip;
	config.ports = sports;
	config.epollTimeoutUs = epollTimeoutUs; //1ms


	oIni.GetInt("CONNECT", "MAX_CLIENTS", 10000,&(config.maxclients));
	oIni.GetInt("CONNECT", "PROTOCOL_TYPE", PROTOCOL_TYPE_BIN,&(config.protocolType));
	oIni.GetInt("CONNECT", "IDLE_TIMEOUT_S", 0, &(config.fdIdleTimeoutS));
	
	CPIPEConfigInfo pipeconfig;
	if(pipeconfig.set_config(argv[2])!= 0)
	{
		cout << "parse ini fail " << endl;
		return 0;
	}

	if(pipeconfig.get_config(globeID, true,config.shmkey_r,config.dequesize_r,config.shmkey_w,config.dequesize_w, config.semKey) != 0)
	{
	 	cout << "get_config for " << globeID << " fail" << endl;
		return 0;
	}
	
	config.debug(cout);

	//lock & daemon
	if(CServerTool::run_by_ini(&oIni, "CONNECT")!=0)
	{
		cout << "run_by_ini fail" << endl;
		return 0;
	}

	CServerTool::sighandle(SIGTERM, stophandle);
	CServerTool::sighandle(SIGUSR1, usr1handle);
	CServerTool::sighandle(SIGUSR2, usr2handle);
	CServerTool::ignore(SIGPIPE);

	//start server
	int ret = connect.start(config);
	if(ret != 0)
	{
		cout << "start =" << ret << endl;
		return 0;
	}

	return 1;
}

