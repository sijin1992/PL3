#ifndef __TCP_CLIENT_H__
#define __TCP_CLIENT_H__

#include "tcpwrap.h"
#include <vector>
#include "../random/random.h"
#include <errno.h>
#include <signal.h> 
#include <iostream>

using namespace std;

//�ṩ����ʽ�Ķ�д
class CTcpClient
{
public:
	struct CONFIG
	{
		//���ԴӶ��server��ѡ��һ��
		vector<string> ips;
		vector<unsigned short> ports;
		//�Ƿ���������(��������SIG_PIPE,����E_PIPE���� or read=0)
		//һ����һ��һ��ʽ�ķ������´�send��ʱ������������
		bool autoReconnect; //Ĭ��ture
		//������������������ֵʱ���ر�����(��������)��0=������
		//д���˶Է��ر�һ�㲻��������Ҫ�ǿ���ʱ
		unsigned int errClose; //Ĭ����3
		
		//����ʹ������ip���ӵĴ���
		unsigned int tryTimes;//Ĭ��1
		//�Ƿ����ip���������idx=0��ʼʹ��
		bool randIP; //Ĭ��ture
		//timeout��λ���룬��д����һ��timeout 0=�����ƣ�
		unsigned int timeout;//Ĭ��0
		//ʹ��select+noblock
		bool useSelect;//Ĭ��false
		//����SIGPIPE
		bool ignoreSIGPIPE;//Ĭ��true

		int sndBuffSize; //Ĭ��-1��ʹ��ϵͳĬ��
		int rcvBuffSize; //Ĭ��-1��ʹ��ϵͳĬ��
		
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
	
	//config��init֮ǰҪ���úã�����û��ip����
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

	//��ʼ����doConnect connect��server������Ҫ����config.autoReconnect ��sendʱ����
	int init(bool doConnect = true);

	void debug(ostream& os);


public:
	/*
	*����>0ʵ��д������
	*/
	int send(const char* src, int len);

	/*
	*����>0ʵ�ʶ�������
	*/
	int recieve(char* dst, int len);
	
	/*
	*���ӵ��¸�server��Ҫ���ù�init����Ŷ
	*/
	inline int shift_server()
	{
		m_curIdx = (m_curIdx+1)%m_ipCount; //�ֻ���
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

