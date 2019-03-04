#ifndef __CLIENT_INTERFACE_H__
#define __CLIENT_INTERFACE_H__
#include <google/protobuf/message.h>
#include <iostream>
#include <string>
#include "common/msg_define.h"
#include "net/tcpwrap.h"
#include "net/tcp_client.h"
#include "common/bin_protocol.h"
using namespace std;
using namespace google::protobuf;


class CClientInterface
{
	public:
		CClientInterface()
		{
			m_binreq.bind(m_sendBuff, sizeof(m_sendBuff));
			m_binResp.bind(m_recvBuff, sizeof(m_recvBuff));
			m_pTcp = NULL;
			pout = NULL;
		}

		virtual ~CClientInterface() {}

		inline void set_param(CTcpClient* pTcpObj, ostream* out, const char* userName, const char* userKey) 
		{
			m_pTcp = pTcpObj;
			m_userName = userName;
			m_userKey = userKey;
			pout = out;
		}
		
		//打印提示信息
		virtual void help(ostream& out) = 0;

		virtual bool req_msg(int argc, char** argv, Message*& retpReq) = 0;
		virtual unsigned int req_cmd() = 0;
		virtual unsigned int resp_cmd() = 0;
		virtual Message* resp_msg() = 0;

		virtual void hook_recved()
		{
		}

		//阻塞模式的入口
		bool run(int argc, char** argv);

		//只管发送
		bool send(int argc, char** argv);

		//只管接收
		bool on_recv(CBinProtocol& theRespBin, ostream& os, int temp = 0);


	protected:
		//阻塞调用
		int send_and_recv(Message* preq, Message* presp, unsigned int cmdReq, unsigned int cmdResp);

	protected:
		CTcpClient* m_pTcp;
		const char* m_userName;
		const char* m_userKey;
		CBinProtocol m_binreq;
		CBinProtocol m_binResp;
		static char m_sendBuff[MSG_BUFF_LIMIT];
		static char m_recvBuff[MSG_BUFF_LIMIT];
		ostream* pout;
		static string m_argbuf;
};

#endif

