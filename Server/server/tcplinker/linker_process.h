#ifndef __LINKER_PROCESS_H__
#define __LINKER_PROCESS_H__
#include "linker_io.h"
#include "linker_config.h"
#include "logic/msg_queue.h"
#include "logic/toolkit.h"
#include "logic/msg.h"
#include "common/queue_pipe.h"
#include "linker_net.h"
#include <map>
#include <vector>
#include "common/sleep_control.h"
#include "time/interval_ms.h"

extern int gDebug;
extern int gStopFlag;
using namespace std;

typedef map<unsigned int, CMsgQueuePipe*> SVR_QUEUE_MAP;
typedef map<unsigned int, CLinkerWriter*> SVR_WRITE_MAP;
typedef map<int, CLinkerReader*> SVR_READ_MAP;
typedef vector<CDequePIPE*> DEL_PIPE_VEC;
typedef vector<CMsgQueuePipe*> DEL_MSG_VEC;
typedef vector<CLinkerWriter*> DEL_WRITER_VEC;

struct LINKER_SVRSET_SLOT
{
	CIntervalMs theInterval;
	unsigned int svrID; 
};

struct LINKER_SVRSET_INFO
{
	unsigned int id;
	int aliveTimeout;
	map<unsigned int, LINKER_SVRSET_SLOT>  slotMap;
	map<unsigned int, LINKER_SVRSET_SLOT>::iterator randSlotMapIt;
};

typedef map<unsigned int, LINKER_SVRSET_INFO*> SVRSET_MAP;
typedef map<unsigned int, unsigned int> CMD_MASK_MAP;

class CLinkerProcess
{
public:
	CLinkerProcess():m_buffMsg(NULL, 0, false)
	{
		m_inited = false;
		m_buffMsg.replace_buffer(m_toolkit.readBuff, sizeof(m_toolkit.readBuff));
	}

	~CLinkerProcess()
	{
		unsigned int i=0;
		for(i=0; i<m_delMsg.size(); ++i)
		{
			delete m_delMsg[i];
		}
		
		for(i=0; i<m_delPipe.size(); ++i)
		{
			delete m_delPipe[i];
		}

		for(i=0; i<m_delWriter.size(); ++i)
		{
			delete m_delWriter[i];
		}

		for(SVR_READ_MAP::iterator it=m_readMap.begin(); it!=m_readMap.end(); ++it)
		{
			m_net.close_fd(it->first);
			delete it->second;
		}

		for(SVRSET_MAP::iterator it=m_svrsetMap.begin(); it!=m_svrsetMap.end(); ++it)
		{
			delete it->second;
		}
	}

	int init(CLinkerConfig& config, CPIPEConfigInfo& pipeConfig)
	{
		//attach queue
		CONF_QUEUE_POOL::iterator queueIt;
		CONF_DES_POOL::iterator desIt;
		CONF_CMD_POOL::iterator cmdIt;
		unsigned int queueID;
		unsigned int svrID;
		bool active;
		for(queueIt = config.queueConf.begin(); queueIt != config.queueConf.end(); ++queueIt)
		{
			queueID = queueIt->queueID;
			svrID  = queueIt->svrID;
			active = queueIt->active;
			CDequePIPE* ppipe = new CDequePIPE;
			if(!ppipe)
			{
				LOG(LOG_ERROR, "new CDequePIPE fail");
				return -1;
			}
			m_delPipe.push_back(ppipe);

			if(ppipe->init(pipeConfig, queueID, active) != 0)
			{
				LOG(LOG_ERROR, "CDequePIPE init fail %s", ppipe->errmsg());
				return -1;
			}

			CMsgQueuePipe* pqueue = new CMsgQueuePipe(*ppipe, &gDebug);
			if(!pqueue)
			{
				LOG(LOG_ERROR, "new CMsgQueuePipe fail");
				return -1;
			}
			m_delMsg.push_back(pqueue);

			pair<SVR_QUEUE_MAP::iterator, bool> retPair = m_queueMap.insert(make_pair(svrID, pqueue));
			if(!retPair.second)
			{
				LOG(LOG_ERROR, "%u insert existed", svrID);
				return -1;
			}
		}

		for(desIt=config.desConf.begin(); desIt != config.desConf.end(); ++desIt)
		{
			CLinkerWriter* newWriter = new CLinkerWriter;
			if(newWriter == NULL)
			{
				LOG(LOG_ERROR, "new CLinkerWriter fail");
				return -1;
			}
			newWriter->set_svr(desIt->ip, desIt->port);
			m_delWriter.push_back(newWriter);
			svrID = desIt->svrID;

			pair<SVR_WRITE_MAP::iterator, bool> retPair = m_writeMap.insert(make_pair(svrID, newWriter));
			if(!(retPair.second))
			{
				LOG(LOG_ERROR, "%u insert existed", svrID);
				return -1;
			}
		}

		//svr set 初始化
		for(cmdIt=config.cmdConf.begin(); cmdIt != config.cmdConf.end(); ++cmdIt)
		{
			if(cmdIt->type == 0)
			{
				m_randomCmdMap[cmdIt->cmd] = cmdIt->mask;
			}
			else if(cmdIt->type == 1)
			{
				m_broadcastCmdMap[cmdIt->cmd] = cmdIt->mask;
			}
			else if(cmdIt->type == 2)
			{
				m_aliveCmdMap[cmdIt->cmd] = cmdIt->mask;
			}
		}

		CONF_SVRSET_POOL::iterator svrsetIt;
		LINKER_SVRSET_SLOT tmp;
		for(svrsetIt = config.svrSetConf.begin(); svrsetIt!= config.svrSetConf.end(); ++svrsetIt)
		{
			LINKER_SVRSET_INFO* pinfo = new LINKER_SVRSET_INFO;
			pinfo->id = (*svrsetIt)->id;
			pinfo->aliveTimeout = (*svrsetIt)->aliveTimeout;
			for(unsigned int i=0; i< (*svrsetIt)->vSvrIDs.size(); ++i)
			{
				tmp.svrID = (*svrsetIt)->vSvrIDs[i];
				pinfo->slotMap[tmp.svrID] = tmp;
			}
			pinfo->randSlotMapIt = pinfo->slotMap.begin();
			m_svrsetMap[pinfo->id] = pinfo;
		}
		
		int ret = m_net.init(config.listenIP,config.listenPort);
		if(ret != 0)
		{
			return -1;
		}

		pConfig = &config;
		m_inited = true;
		return 0;
	}


	int main_loop()
	{
		if(!m_inited)
		{
			LOG(LOG_ERROR, "not inited" );
			return -1;
		}

		int ret = 0;
		epoll_event* ptheEvent;
		//有epoll阻塞就不sleep了
//		m_sleep.setparam(1000, 1000, 100000);
		while(!gStopFlag)
		{
			//更新下时间
			gettimeofday(&m_nowtime, NULL);
			//各个消息通道
			for(SVR_QUEUE_MAP::iterator it = m_queueMap.begin(); it!= m_queueMap.end(); ++it)
			{
				CMsgQueuePipe* pqueue = it->second;
				int i;
				for(i=0; i<pConfig->readlimitPerQueue; ++i)
				{
					ret = pqueue->get_msg(m_buffMsg);
					if(ret == pqueue->EMPTY)
					{
						break;
					}
					else if(ret == pqueue->OK)
					{
						bool ifContinue = false;
						if(test_random_cmd(ifContinue))
						{
							
						}
						else if(test_broadcast_cmd(ifContinue))
						{
						}
						else
						{
							unsigned int desSvr = m_toolkit.get_des_server(m_buffMsg);
							ifContinue = put_msg_to_writer(desSvr);
						}

						if(!ifContinue)
						{
							break;
						}
					}
					else
					{
						//出错，break，给别的queue机会
						break;
					}
				}
				//m_sleep.work(i);
			}

			//网络
			ret= m_net.do_poll();
			if(ret != 0)
			{
				//m_sleep.delay();
				continue;
			}

			//m_sleep.cancel_delay();
			
			while(m_net.fetch_event(ptheEvent))
			{
				int fd = ptheEvent->data.fd;
				int events = ptheEvent->events;
				int bin = events & EPOLLIN;
				int bout = events & EPOLLOUT;
				int berror = events & EPOLLERR;
				int bhup = events & EPOLLHUP;
				if(gDebug)
				{
					LOG(LOG_DEBUG, "fd[%d] recv event[%d,%d,%d,%d]", fd, 
						bin, bout, berror, bhup);
				}
				
				//if listen
				if(m_net.is_listen_fd(ptheEvent) && bin)
				{
					int newFD;
					ret = m_net.do_accept(newFD);
					if(ret == 0)
					{
						insert_reader(newFD);
					}
				}
				else
				{
					//错误
					if(berror || bhup)
					{
						LOG(LOG_ERROR, "%d EPOLLERR or EPOLLHUP", fd);
						//反正在两个map之一
						if(del_reader(fd) == 0)
						{
							disable_writer(fd);
						}

						continue;
					}

					if(bin)
					{
						//可读，先尝试是否是读者
						CLinkerReader* preader = find_reader(fd);
						if(!preader)
						{
							//那可能是写者的链接断开了
							char buff;
							if(read(fd, &buff, 1)!=0)
							{
								LOG(LOG_ERROR, "shit fd(%d) should be writeMap, but can read", fd);
							}
							else
							{
								disable_writer(fd);
							}
						}
						else
						{
							int i;
							//借用queue的限制
							for(i=0; i<pConfig->readlimitPerQueue; ++i)
							{
								ret = preader->test_recv(fd, m_buffMsg);
								if(gDebug)
								{
									LOG(LOG_DEBUG, "test_recv=%d", ret);
								}
								if(ret==0)
								{
									unsigned int desSvr = m_toolkit.get_des_server(m_buffMsg);
									if(!test_alive_cmd())
									{
										//传递给某个消息通道
										CMsgQueuePipe* p = find_queue(desSvr);
										if(p)
										{
//CBinProtocol bin;
//bin.bind(m_buffMsg.body(), m_buffMsg.head()->bodySize);
//LOG(LOG_INFO, "%s|receive msg cmd(%u) len(%u) id(%u,%u)", bin.head()->parse_name().str(), 
//	m_buffMsg.head()->cmdID, m_buffMsg.head()->bodySize,m_buffMsg.head()->srcHandleID, m_buffMsg.head()->desHandleID);
//LOG(LOG_INFO, "recv net to queue");
											p->send_msg(m_buffMsg);
										}
										else
										{
											LOG(LOG_ERROR, "shit desSvr(%s) no queue", CTcpSocket::addr_to_str(desSvr).c_str());
										}
									}
								}
								else if(ret == 2)
								{
									//closed
									del_reader(fd);
									break;
								}
								else 
								{
									break;
								}
							}
							//m_sleep.work(i);
						}
					}

					if(bout)
					{
						//可写
						CLinkerWriter* pIO = find_writer(fd);
						if(pIO)
						{
							ret = pIO->buff_send(m_net);
							if(gDebug)
							{
								LOG(LOG_DEBUG, "buff_send=%d", ret);
							}
							if(ret !=0)
							{
								LOG(LOG_ERROR, "send should be ok");
							}
							
//LOG(LOG_INFO, "buff to net");
//							m_sleep.work(1);
						}
						else
						{
							LOG(LOG_ERROR, "shit fd(%d) should in writeMap", fd);
							m_net.close_fd(fd);
						}
						
					}
					
				}

			}


			//sleep
			//m_sleep.sleep();
		}

		return 0;
	}

protected:

	inline bool test_random_cmd(bool& bcontinue)
	{
		unsigned int desSvr = m_toolkit.get_des_server(m_buffMsg);
		unsigned int cmd = m_toolkit.get_cmd(m_buffMsg);
		//查看是否是random命令
		LINKER_SVRSET_INFO* p;
		bool ret = find_svrset_info(desSvr, cmd, m_randomCmdMap, p);
		if(p)
		{
			unsigned int desSvrID = 0;
			for(unsigned int i=0; i< p->slotMap.size(); ++i)
			{
				//轮着来，最多一个遍
				if(++(p->randSlotMapIt) == p->slotMap.end())
					p->randSlotMapIt = p->slotMap.begin();

				if(p->aliveTimeout==0 || !(p->randSlotMapIt->second.theInterval.check_timeout(p->aliveTimeout,false,&m_nowtime)))
				{
					desSvrID = p->randSlotMapIt->first;
					break;
				}
			}
			
			if(desSvrID == 0)
			{
				LOG(LOG_ERROR, "all svr down!!! for cmd(0x%x)", cmd);
				bcontinue = true;
			}
			else
			{
				//修改desSvrID
				m_buffMsg.head()->desServerID = desSvrID;
				bcontinue = put_msg_to_writer(desSvrID);
			}
		}

		return ret;
	}

	inline bool test_broadcast_cmd(bool& bcontinue)
	{
		unsigned int desSvr = m_toolkit.get_des_server(m_buffMsg);
		unsigned int cmd = m_toolkit.get_cmd(m_buffMsg);
		//查看是否是broadcast命令
		LINKER_SVRSET_INFO* p;
		bool ret = find_svrset_info(desSvr, cmd,m_broadcastCmdMap,p);
		if(p)
		{
	//LOG(LOG_ERROR, "test_broadcast_cmd");
			unsigned int desSvrID = 0;
			map<unsigned int, LINKER_SVRSET_SLOT>::iterator slotIt;
			for(slotIt = p->slotMap.begin(); slotIt!=p->slotMap.end(); ++slotIt)
			{
	//LOG(LOG_ERROR, "alivetimeout=%d, iftimeout=%d", p->aliveTimeout, slotIt->second.theInterval.check_timeout(p->aliveTimeout,false));
				if(p->aliveTimeout==0 || !(slotIt->second.theInterval.check_timeout(p->aliveTimeout,false,&m_nowtime)))
				{
					desSvrID = slotIt->first;
					m_buffMsg.head()->desServerID = desSvrID;
					bcontinue = put_msg_to_writer(desSvrID);
		//LOG(LOG_ERROR, "send to %s = %d", CTcpSocket::addr_to_str(desSvrID).c_str(), bcontinue); 		
					if(!bcontinue)
						break;
				}
			}
		}
		
		return ret;
	}
	
	inline bool test_alive_cmd()
	{
		unsigned int srcSvr = m_toolkit.get_src_server(m_buffMsg);
		unsigned int cmd = m_toolkit.get_cmd(m_buffMsg);
		//查看是否是alive命令
		LINKER_SVRSET_INFO* p;
		bool ret = find_svrset_info(srcSvr, cmd, m_aliveCmdMap,p);
		if(p)
		{
			if(p->aliveTimeout != 0) //=0没有必要更新
			{
				map<unsigned int, LINKER_SVRSET_SLOT>::iterator slotIt;
				slotIt = p->slotMap.find(srcSvr);
				if(slotIt != p->slotMap.end())
				{
					slotIt->second.theInterval.update_self(&m_nowtime);
				}
				else
				{
					LOG(LOG_ERROR, "aliveCmd(0x%x) svr=%s svrSet=%s server not in set",
						cmd, CTcpSocket::addr_to_str(srcSvr).c_str(), 
						CTcpSocket::addr_to_str(p->id).c_str());
				}
			}
		}
	
		return ret;
	}

	inline bool find_svrset_info(unsigned int theSvrID, unsigned int theCmd, CMD_MASK_MAP& theMaskMap, LINKER_SVRSET_INFO* & ptheInfo)
	{
		ptheInfo = NULL;
		CMD_MASK_MAP::iterator it = theMaskMap.find(theCmd);
		if(it != theMaskMap.end())
		{
			//是的
			unsigned int svrsetID = theSvrID & it->second;
			if(gDebug)
			{
				LOG(LOG_DEBUG, "recive cmd(0x%x) svr=%s mask=%s setid=%s",
					theCmd, CTcpSocket::addr_to_str(theSvrID).c_str(), 
					CTcpSocket::addr_to_str(it->second).c_str(),
					CTcpSocket::addr_to_str(svrsetID).c_str());
			}
			SVRSET_MAP::iterator svrIt = m_svrsetMap.find(svrsetID);
			if(svrIt != m_svrsetMap.end())
			{
				ptheInfo = svrIt->second;
			}
			else
			{
				LOG(LOG_ERROR, "cmd(0x%x) svr=%s mask=%s setid=%s not exsit",
					theCmd, CTcpSocket::addr_to_str(theSvrID).c_str(), 
					CTcpSocket::addr_to_str(it->second).c_str(),
					CTcpSocket::addr_to_str(svrsetID).c_str());
			}	
			return true;
		}
		
		return false;
	}

	//return 是否继续循环
	inline bool put_msg_to_writer(unsigned int desSvr)
	{
		CLinkerWriter* ptheIO = find_writer(desSvr);
		if(!ptheIO)
		{
			return true;
		}
		
		int ret = ptheIO->test_send(m_buffMsg, m_net);
		if(gDebug)
		{
			LOG(LOG_DEBUG, "test_send=%d", ret);
		}
		if(ret < 0)
		{
			return false;
		}
		else if(ret == 1)
		{
			return false;
		}

//CBinProtocol bin;
//bin.bind(m_buffMsg.body(), m_buffMsg.head()->bodySize);
//LOG(LOG_INFO, "%s|send to net cmd(%u) len(%u) id(%u,%u)", 
//	bin.head()->parse_name().str(),msg.head()->cmdID, msg.head()->bodySize, msg.head()->srcHandleID, msg.head()->desHandleID);
//LOG(LOG_INFO, "write to net");
		return true;
	}


	inline CMsgQueuePipe* find_queue(unsigned int svrID)
	{
		SVR_QUEUE_MAP::iterator it = m_queueMap.find(svrID);
		if(it == m_queueMap.end())
		{
			LOG(LOG_ERROR, "queue for %u not exsit", svrID);
			return NULL;
		}

		return it->second;
	}

	inline CLinkerWriter* find_writer(unsigned int svrID)
	{
		SVR_WRITE_MAP::iterator it = m_writeMap.find(svrID);
		if(it == m_writeMap.end())
		{
			LOG(LOG_ERROR, "CLinkerWriter for svrID[%u] not exsit", svrID);
			return NULL;
		}

		return it->second;
	}

	inline CLinkerWriter* find_writer(int fd)
	{
		SVR_WRITE_MAP::iterator it;
		for(it = m_writeMap.begin(); it!=m_writeMap.end(); ++it)
		{
			if(it->second->get_fd() == fd)
			{
				return  it->second;
			}
		}
		LOG(LOG_ERROR, "CLinkerWriter for fd[%d] not exsit", fd);
		return NULL;
	}

	inline CLinkerReader* find_reader(int fd)
	{
		SVR_READ_MAP::iterator it = m_readMap.find(fd);
		if(it == m_readMap.end())
		{
			LOG(LOG_ERROR, "readIO for fd[%d] not exsit", fd);
			return NULL;
		}

		return it->second;
	}

	inline int insert_reader(int fd)
	{
		SVR_READ_MAP::iterator it = m_readMap.find(fd);
		if(it != m_readMap.end())
		{
			LOG(LOG_ERROR, "m_readMap fd(%d) exists", fd);
			m_net.close_fd(fd);
			return -1;
		}

		CLinkerReader* ptheReader = new CLinkerReader;
		if(ptheReader == NULL)
		{
			LOG(LOG_ERROR, "new CLinkerReader fail");
			m_net.close_fd(fd);
			return -1;
		}

		m_readMap[fd] = ptheReader;
		return 0;
	}

	inline int del_reader(int fd)
	{
		m_net.close_fd(fd);
		SVR_READ_MAP::iterator it = m_readMap.find(fd);
		if(it != m_readMap.end())
		{
			if(it->second != NULL)
				delete it->second;
			m_readMap.erase(it);
			return 1;
		}

		return 0;
	}

	void disable_writer(int fd)
	{
		m_net.close_fd(fd);
		SVR_WRITE_MAP::iterator it;
		for(it = m_writeMap.begin(); it!=m_writeMap.end(); ++it)
		{
			if(it->second->get_fd() == fd)
			{
				it->second->clean();
				break;
			}
		}
	}
	
public:
	CLinkerConfig* pConfig;
	
protected:
	DEL_PIPE_VEC m_delPipe;
	DEL_MSG_VEC m_delMsg;
	DEL_WRITER_VEC m_delWriter;
	SVR_QUEUE_MAP m_queueMap;
	CLinkerNet m_net;
	SVR_WRITE_MAP m_writeMap;
	SVR_READ_MAP m_readMap; //read map自己管理释放
	bool m_inited;
	CLogicMsg m_buffMsg;
	CToolkit m_toolkit;
	CSleepControl m_sleep;

	//svr set 相关内容
	CMD_MASK_MAP m_randomCmdMap;
	CMD_MASK_MAP m_broadcastCmdMap;
	CMD_MASK_MAP m_aliveCmdMap;
	SVRSET_MAP m_svrsetMap;

	timeval m_nowtime;
};

#endif

