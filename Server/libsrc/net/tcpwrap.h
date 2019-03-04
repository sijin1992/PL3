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
		//地址转换包装函数
		//二进制到字符串
		static string addr_to_str(in_addr_t addr);
		//字符串到二进制，返回0=串有效，-1错误
		static int str_to_addr(string str, in_addr& addr);

		//字符串到二进制，返回0=串有效，-1错误
		static int str_to_addr(string str, unsigned int& addr);
		
		//填写地址的包装函数, port是本地字节序的
		static void set_addr(sockaddr_in& sockaddr, in_addr_t addr, unsigned short port);

		CTcpSocket();
		/*析构就close，对象要注意生命期，可以使用pass_socket()方法，对象不再维护改fd*/
		~CTcpSocket();

		
		//分配socket。0=ok -1=fail。重新init会关闭上一次的fd
		int init();

		//非阻塞。 0=ok -1=fail
		int set_nonblock();
		int set_rcv_timeout(unsigned int s/*秒*/, unsigned int us =  0/*微秒*/);
		int set_snd_timeout(unsigned int s/*秒*/, unsigned int us = 0/*微秒*/);
		int set_reuse_addr();

		//read, write操作，包装一下错误信息
		//return 实际的长度或-1，看errno
		int write(const char* buff, int len);

		//return 实际的长度或-1，看errno
		int read(char* buff, int len);

		//end = 结束字符串, 如果end出现，则pend指向出现的位置，否则=NULL;
		//return 实际的长度或-1，看errno
		int read_until(char* buff, int len, const char* end, char*& pend);

		//getsockname & getpeername 确认是tcp可以简化下,port是本地序的
		int get_sock_name(in_addr_t& addr, unsigned short& port);
		int get_peer_name(in_addr_t& addr, unsigned short& port);

		//修改buff
		int set_snd_buffsize(int size);
		int set_rcv_buffsize(int size);
	

		//错误信息
		inline const char* errmsg()
		{
			return m_errmsg;
		}

		inline int get_socket()
		{
			return m_socket;
		}

		//传递socket
		inline int pass_socket()
		{
			int ret = m_socket;
			m_socket = -1;
			return ret;
		}

		//set socket. 调用者保证传入的有效性，会导致当前socket close，转而维护新的socket
		inline void set_socket(int socket)
		{
			if(m_socket >=0 )
				close();
			m_socket = socket;
		}

		//return 0=0k, -1=err，一般来说不需要主动调用
		int close();
		
	protected:
		int m_socket;
		static char m_errmsg[256];
};

class CTcpClientSocket: public CTcpSocket
{
	public:
		//connect, 调用着可以考虑使用nonblock，自己监听可写事件
		//linux下 set_snd_timeout对connect有效
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
#define SOMAXCONN 128   //更大的不知道喽
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

