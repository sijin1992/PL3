#ifndef __TCP_CLIENT_H__
#define __TCP_CLIENT_H__

#include "tcpwrap.h"
#include <vector>
#include "../random/random.h"
#include <errno.h>
#include <signal.h> 
#include <iostream>

using namespace std;

//提供阻塞式的读写
class CTcpClient
{
public:
	struct CONFIG
	{
		//可以从多个server中选择一个
		vector<string> ips;
		vector<unsigned short> ports;
		//是否重新连接(得先屏蔽SIG_PIPE,发生E_PIPE错误 or read=0)
		//一搬是一问一答式的服务，在下次send的时候做重新连接
		bool autoReconnect; //默认ture
		//连续错误次数大于这个值时，关闭连接(触发重连)，0=不限制
		//写除了对方关闭一般不出错，读主要是看超时
		unsigned int errClose; //默认是3
		
		//尝试使用其他ip连接的次数
		unsigned int tryTimes;//默认1
		//是否随机ip，不随机从idx=0开始使用
		bool randIP; //默认ture
		//timeout单位是秒，读写共享一个timeout 0=不限制，
		unsigned int timeout;//默认0
		//使用select+noblock
		bool useSelect;//默认false
		//忽略SIGPIPE
		bool ignoreSIGPIPE;//默认true

		int sndBuffSize; //默认-1，使用系统默认
		int rcvBuffSize; //默认-1，使用系统默认
		
		//int read(const char* config_file);

		CONFIG();
		void debug(ostream& os);
	};

	
public:

	static const int VALUE_MAX_INTR = 3;
	static const int WAIT_TYPE_RD = 1;
	static const int WAIT_TYPE_WR = 2;
	static const int WAIT_TYPE_RDWR = 3;

	CTcpClient();
	
	//config在init之前要配置好，否则没有ip可用
	inline CONFIG* config()
	{
		return &m_config;
	}

	inline void add_server(string ip, unsigned short port)
	{
		m_config.ips.push_back(ip);
		m_config.ports.push_back(port);
		m_ipCount = m_config.ips.size();
	}

	const char* errmsg();

	//初始化，doConnect connect到server，否则要配置config.autoReconnect 当send时连接
	int init(bool doConnect = true);

	void debug(ostream& os);


public:
	/*
	*返回>0实际写的数量
	*/
	int send(const char* src, int len);

	/*
	*返回>0实际读的数量
	*/
	int recieve(char* dst, int len);
	
	/*
	*连接到下个server，要调用过init才行哦
	*/
	inline int shift_server()
	{
		m_curIdx = (m_curIdx+1)%m_ipCount; //轮换下
		return do_connect();
	}

	inline bool closed()
	{
		return m_closed;
	}
	
	int close();

protected:
	int do_connect();

	int block_connect();

	int block_send(const char* src, int len);

	int block_recieve(char* dst, int len);

	int nonblock_connect();

	int nonblock_send(const char* src, int len);

	int nonblock_recieve(char* dst, int len);

	int select_wait(int iType, int iTimeOut, int* piTimeUsed);

	void check_err(int ret);
	
protected:
	CTcpClientSocket m_socket;
	unsigned int m_ipCount;
	unsigned int m_curIdx;
	CONFIG m_config;
	static char m_errmsg[256];
	bool m_closed;
	unsigned int m_errcount;
};

#endif

