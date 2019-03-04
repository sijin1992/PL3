#include <iostream>
#include "log/log.h"
#include "../driver.h"

using namespace std;

class CLogicXXX:public CLogicProcessor
{
	public:
		virtual void on_init()
		{
			cout << "CLogicXXX(" << m_id << ") on_init" << endl;
		}
		
		//有msg到达的时候激活对象
		virtual int on_active(CLogicMsg& msg)
		{
			cout << "CLogicXXX(" << m_id << ") on_active(cmd=" << m_ptoolkit->get_cmd(msg) << ")" << endl;
			//msg.head()->debug(cout);
			cout << m_ptoolkit->get_body(msg) << endl;
			unsigned int strlen = 0;
			switch(m_ptoolkit->get_cmd(msg))
			{
				case 0x1001:
					//给client回一个包
					strlen = snprintf(m_ptoolkit->send_buff(), m_ptoolkit->send_buff_len(), "to client");
					if(m_ptoolkit->send_to_queue(0x1002, 1, strlen+1) != 0 )
					{
						cout << "send to client fail" << endl;
					}
					//再给自己发一个包
					strlen = snprintf(m_ptoolkit->send_buff(), m_ptoolkit->send_buff_len(), "to self");
					if(m_ptoolkit->send_to_queue(0x1003, 2, strlen+1, 0, m_id) != 0 )
					{
						cout << "send to client fail" << endl;
					}

					//还是这个对象处理
					return RET_YIELD;
					break;
					
				case 0x1003:
					//给自己的包，然后设置一个定时器，driver的配置中需要带上定时器才行
					break;

				default:
					cout << "unexpect cmd=" << m_ptoolkit->get_cmd(msg) << endl;
					break;
			}

			return RET_DONE;
		}
		
		//对象销毁前调用一次
		virtual void on_finish()
		{
			cout << "CLogicXXX(" << m_id << ") on_finish" << endl;
		}

		virtual CLogicProcessor* create()
		{
			return new CLogicXXX;
		}
		
};

struct LOGIC_IN_SHM_DATA
{
	unsigned int timerID;
	unsigned int timerIDToDel;
};

class CLogicInShm: public CLogicProcessorTyped<LOGIC_IN_SHM_DATA>
{
	virtual void on_init()
	{
		cout << "CLogicInShm(" << m_id << ") on_init" << endl;
	}

	virtual int on_active(CLogicMsg& msg)
	{
		unsigned int cmd = m_ptoolkit->get_cmd(msg);
		cout << "CLogicInShm(" << m_id << ") on_active(cmd=" << cmd << ")" << endl;
		

		if(cmd == 0x1005)
		{
			//client 请求, set 3s的timer, 然后重启server测试是否保存ok
			cout << "set timer=" << m_ptoolkit->set_timer_s(m_shm->timerID, 3, m_id, 0x1007, 1) << endl;
			cout << "timerID = " << m_shm->timerID << endl;

			//在set一个 10s的
			cout << "set timer=" << m_ptoolkit->set_timer_s(m_shm->timerIDToDel, 10, m_id, 0x1009) << endl;

			return RET_YIELD;
		}
		else if(cmd == 0x1007)
		{
			//定时器请求 
			unsigned int flag = *((unsigned int*)(m_ptoolkit->get_body(msg)));
			cout << "saved timerID=" << m_shm->timerID << ", flag=" << flag << endl;
			cout << "del timer(" << m_shm->timerIDToDel << ")=" << m_ptoolkit->del_timer(m_shm->timerIDToDel) << endl;
		}
		else if(cmd == 0x1009)
		{
			//不会被触发
			cout << "can't be invoked" << endl;
		} 

		return RET_DONE;
	}
	
	virtual void on_finish()
	{
		cout << "CLogicInShm(" << m_id << ") on_finish" << endl;
	}
	
	virtual CLogicProcessor* create()
	{
		return new CLogicInShm;
	}

};

int main(int argc,char * * argv)
{
	//open log
	LOG_CONFIG conf;
	conf.globeLogLevel = LOG_DEBUG;
	conf.logPath = "../../log";
	conf.proxyType = LOG_LOCAL;

	LOG_CONFIG_SET(conf);

	cout << "log open=" << LOG_OPEN("logictest",LOG_DEBUG) << " " << LOG_GET_ERRMSGSTRING << endl;
	
	int ret = 0;

	CLogicDriverConfig config;
	config.atWhichServer = 1002;
	config.saveLogicInMsa = true;
	config.msaBlocksize = 10*1024;
	config.msaKey = 0x10000;
	config.msaSize = 100*1024;
	config.useTimer = true;
	config.timerKey = 0x20000;
	config.timerMaxNum = 10000;
		
	CLogicDriver driver;

	CDequePIPE pipe;
	ret = pipe.init(0x10001, 10000, 0x10002, 10000);
	if(ret != 0)
	{
		cout << "pipe.init " << pipe.errmsg() << endl;
		return -1;
	}
	CMsgQueuePipe queuePipe(pipe);

	CDequePIPE pipeLoop; //server 自己给自己发消息的通道
	ret = pipeLoop.init(0x10003, 10000, 0x10003, 10000); //读写同一队列
	if(ret != 0)
	{
		cout << "pipeLoop.init " << pipe.errmsg() << endl;
		return -1;
	}
	CMsgQueuePipe queuePipeLoop(pipeLoop);

/*	ret = driver.add_msg_queue(0,&queuePipe);
	if(ret != 0)
	{
		//一定失败不能为0
		cout << "add_msg_queue(0) fail "  << endl;
	}
*/
	ret = driver.add_msg_queue(1,&queuePipe);
	if(ret != 0)
	{
		cout << "add_msg_queue(1) fail "  << endl;
		return -1;
	}

/*
	//重复设置也失败
	ret = driver.add_msg_queue(1,&queuePipeLoop);
	if(ret != 0)
	{
		cout << "add_msg_queue(1) fail "  << endl;
	}
*/
	ret = driver.add_msg_queue(2,&queuePipeLoop);
	if(ret != 0)
	{
		cout << "add_msg_queue(2) fail "  << endl;
		return -1;
	}

	//注册命令(必须在init之前，否则fail)
	ret = driver.regist_handle(0x1001, CLogicCreator(new CLogicXXX));
	if(ret != 0)
	{
		cout << "regist_handle CLogicXXX fail "  << endl;
		return -1;
	}

	ret = driver.regist_handle(0x1005, CLogicCreator(new CLogicInShm));
	if(ret != 0)
	{
		cout << "regist_handle CLogicInShm fail "  << endl;
		return -1;
	}
	
	//init
	ret = driver.init(config);
	if(ret != 0)
	{
		cout << "init fail" << endl;
		return -1;
	}


	//开始run吧
	cout << "main_loop=" << driver.main_loop(-1) << endl;
	
	return 0;
}

