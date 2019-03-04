#ifndef __TCP_WRAP_H__
#define __TCP_WRAP_H__

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <string>

using namespace std;

class CTcpSocket
{
	public:
		//��ַת����װ����
		//�����Ƶ��ַ���
		static string addr_to_str(in_addr_t addr);
		//�ַ����������ƣ�����0=����Ч��-1����
		static int str_to_addr(string str, in_addr& addr);

		//�ַ����������ƣ�����0=����Ч��-1����
		static int str_to_addr(string str, unsigned int& addr);
		
		//��д��ַ�İ�װ����, port�Ǳ����ֽ����
		static void set_addr(sockaddr_in& sockaddr, in_addr_t addr, unsigned short port);

		CTcpSocket();
		/*������close������Ҫע�������ڣ�����ʹ��pass_socket()������������ά����fd*/
		~CTcpSocket();

		
		//����socket��0=ok -1=fail������init��ر���һ�ε�fd
		int init();

		//�������� 0=ok -1=fail
		int set_nonblock();
		int set_rcv_timeout(unsigned int s/*��*/, unsigned int us =  0/*΢��*/);
		int set_snd_timeout(unsigned int s/*��*/, unsigned int us = 0/*΢��*/);
		int set_reuse_addr();

		//read, write��������װһ�´�����Ϣ
		//return ʵ�ʵĳ��Ȼ�-1����errno
		int write(const char* buff, int len);

		//return ʵ�ʵĳ��Ȼ�-1����errno
		int read(char* buff, int len);

		//end = �����ַ���, ���end���֣���pendָ����ֵ�λ�ã�����=NULL;
		//return ʵ�ʵĳ��Ȼ�-1����errno
		int read_until(char* buff, int len, const char* end, char*& pend);

		//getsockname & getpeername ȷ����tcp���Լ���,port�Ǳ������
		int get_sock_name(in_addr_t& addr, unsigned short& port);
		int get_peer_name(in_addr_t& addr, unsigned short& port);

		//�޸�buff
		int set_snd_buffsize(int size);
		int set_rcv_buffsize(int size);
	

		//������Ϣ
		inline const char* errmsg()
		{
			return m_errmsg;
		}

		inline int get_socket()
		{
			return m_socket;
		}

		//����socket
		inline int pass_socket()
		{
			int ret = m_socket;
			m_socket = -1;
			return ret;
		}

		//set socket. �����߱�֤�������Ч�ԣ��ᵼ�µ�ǰsocket close��ת��ά���µ�socket
		inline void set_socket(int socket)
		{
			if(m_socket >=0 )
				close();
			m_socket = socket;
		}

		//return 0=0k, -1=err��һ����˵����Ҫ��������
		int close();
		
	protected:
		int m_socket;
		static char m_errmsg[256];
};

class CTcpClientSocket: public CTcpSocket
{
	public:
		//connect, �����ſ��Կ���ʹ��nonblock���Լ�������д�¼�
		//linux�� set_snd_timeout��connect��Ч
		//return 0=ok, -1=fail
		int connect(string addr, unsigned short port);
	protected:
		string m_addr;
		unsigned short m_port;
		sockaddr_in m_sk;
};

class CTcpAcceptedSocket: public CTcpSocket
{
	public:
		inline sockaddr_in* getSK()
		{
			return &m_sk;
		}
	protected:
		sockaddr_in m_sk;
};

class CTcpListenSocket: public CTcpSocket
{
	//bind, listen, accept
	public:
#ifndef SOMAXCONN
#define SOMAXCONN 128   //����Ĳ�֪���
#endif
		int listen(string addr, unsigned short port, int backLog=SOMAXCONN /*/proc/sys/net/core/somaxconn*/);

		int accept(CTcpAcceptedSocket& newSocket);

		inline sockaddr_in* getSK()
		{
			return &m_sk;
		}
			
	protected:
		string m_addr;
		unsigned short m_port;
		sockaddr_in m_sk;
};



#endif

