#include "../driver.h"
#include <iostream>
#include "log/log.h"
#include <unistd.h>

using namespace std;

class CLogicClient:public CLogicProcessor
{
	public:
		virtual void on_init()
		{
			cout << "processor(" << m_id << ") on_init" << endl;
		}
		
		//有msg到达的时候激活对象
		virtual int on_active(CLogicMsg& msg)
		{
			msg.head()->debug(cout);
			cout << m_ptoolkit->get_body(msg) << endl;

			if(m_ptoolkit->get_cmd(msg) == 0x2001)
			{
				//给server发一个包
				unsigned int strlen = snprintf(m_ptoolkit->send_buff(), m_ptoolkit->send_buff_len(), "to server");
				if(m_ptoolkit->send_to_queue(0x1001, 1, strlen+1) != 0 )
				{
					cout << "send to client fail" << endl;
				}

				//这里可以等server回包，也可以回包时再触发一次逻辑。
				//对于无状态的服务，选择后者
			}

			return RET_DONE;
		}
		
		//对象销毁前调用一次
		virtual void on_finish()
		{
			cout << "processor(" << m_id << ") on_finish" << endl;
		}

		virtual CLogicProcessor* create()
		{
			return new CLogicClient;
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

	cout << "log open=" << LOG_OPEN("client",LOG_DEBUG) << " " << LOG_GET_ERRMSGSTRING << endl;

	int ret = 0;

	CDequePIPE pipe;
	ret = pipe.init(0x10002, 10000, 0x10001, 10000);
	if(ret != 0)
	{
		cout << "pipe.init " << pipe.errmsg() << endl;
		return -1;
	}
	CMsgQueuePipe queuePipe(pipe);

#if 0
	CLogicDriverConfig config;
	config.atWhichServer = 1001;

	CLogicDriver driver;

	ret = driver.add_msg_queue(1,&queuePipe);
	if(ret != 0)
	{
		//一定失败不能为0
		cout << "add_msg_queue(0) fail "  << endl;
		return -1;
	}

	ret = driver.regist_handle(0x2001,CLogicCreator(new CLogicClient));
	if(ret != 0)
	{
		cout << "regist_handle fail "  << endl;
		return -1;
	}

	ret = driver.init(config);
	if(ret != 0)
	{
		cout << "init fail" << endl;
		return -1;
	}

	//server回包的响应
	ret = driver.regist_handle(0x1002,CLogicCreator(new CLogicClient));
	if(ret != 0)
	{
		cout << "regist_handle2 fail "  << endl;
		return -1;
	}

	CToolkit toolkit; //用来组msg
	unsigned int strlen = snprintf(toolkit.send_buff(), toolkit.send_buff_len(), "do_msg");
	//直接触发一个发包逻辑
	ret = driver.do_msg(toolkit.make_send_msg(0x2001, strlen+1));
	if(ret != 0)
	{
		cout << "do_msg fail" << endl;
		return -1;
	}

	cout << "main_loop=" << driver.main_loop(10) << endl; //应该10个循环能等到包了

#else
	//更方便的就是直接发包了
	CToolkit toolkit;
	toolkit.init(NULL, NULL, 1001);
	unsigned int strlen = snprintf(toolkit.send_buff(), toolkit.send_buff_len(), "do_msg");
	ret = toolkit.send_to_queue(0x1005, &queuePipe, strlen+1);
	if(ret != 0)
	{
		cout << "send_to_queue fail" << endl;
		return -1;
	}

	sleep(1);

	CLogicMsg msg(toolkit.readBuff, toolkit.BUFFLEN); //buff 可能被replace掉的，所以段生命期吧
	ret = queuePipe.get_msg(msg);
	if(ret == CMsgQueue::ERROR)
	{
		cout << "queuePipe.get_msg fail" << endl;
		return -1;
	}
	else if(ret == CMsgQueue::EMPTY)
	{
		
	}
	else
	{
		msg.head()->debug(cout);
		cout << toolkit.get_body(msg) << endl;
	}
#endif

	return 0;
}

