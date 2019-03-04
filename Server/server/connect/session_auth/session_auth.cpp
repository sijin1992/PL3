/*
* �����û������֤��
* ά���û�-���ӱ�
* ����Ϣ���˳ɺ�����߼�server���Դ������ʽ
*/

#include "common/queue_pipe.h"
#include <iostream>
#include <unistd.h>
#include "connect/connect_protocol.h"
#include "parse_pb.h"
#include "connect_map.h"
#include "logic/driver.h"
#include "common/server_tool.h"
#include "net/tcpwrap.h"
#include "proto/gateway.pb.h"
#include "net/epoll_wrap.h"

#include "proto/CmdLogin.pb.h"

using namespace std;

unsigned int MSG_QUEUE_ID_SESSION;
unsigned int MSG_QUEUE_ID_LOGIC;
unsigned int MSG_QUEUE_ID_AUTH;

CSessionMap gSessionMap;
CParsePacket gParsePacket;
int gTimeout = 1;
int gDebugFlag = 0;
int gSendLogoutOnClose = 0;
int gLoginNoAuth = 0; //����Ҫ��֤
int gIgnoreLoginCmd = 0; //����Ҫlogin

//��connect->logic�Ľ�����
class CLogicForward:public CLogicProcessor
{
	protected:
		void send_logout_to_logic(USER_NAME& userName)
		{
			if(gDebugFlag)
			{
				LOG(LOG_DEBUG, "CLogicForward::send_logout_to_logic(user=%s)", userName.str());
			}

			int sendLen = m_ptoolkit->send_buff_len();
			if(gParsePacket.create_logout_to_logic(userName, m_ptoolkit->send_buff(), sendLen) == 0)
			{
				if(m_ptoolkit->send_to_queue(CMD_LOGOUT_REQ,MSG_QUEUE_ID_LOGIC,sendLen) != 0)
				{
					LOG(LOG_ERROR, "send_to_queue(CMD_LOGOUT_REQ,MSG_QUEUE_ID_LOGIC) fail");
				}
			}

			LOG(LOG_INFO, "%s closed send logout to logic", userName.str());
		}

		void send_fail_resp(USER_NAME& userName, unsigned int cmd)
		{
			if(gDebugFlag)
			{
				LOG(LOG_DEBUG, "CLogicForward::send_fail_resp(user=%s)", userName.str());
			}
			
			//����sessionͷ
			CConnectProtocol conpro(m_ptoolkit->send_buff(), m_ptoolkit->send_buff_len());
			MSG_SESSION* p = conpro.session();
			*p = m_sessionBuff;
			p->flag = SESSION_FLAG_ZERO;// ��ֹ����
			
			int sendLen = conpro.packet_len();
			if(gParsePacket.create_fail_resp(userName, cmd, conpro.packet(), sendLen) == 0)
			{
				if(m_ptoolkit->send_to_queue(CMD_SESSION_RESP, MSG_QUEUE_ID_SESSION, conpro.total_len(sendLen)) != 0)
				{
					LOG(LOG_ERROR, "send_to_queue(CMD_SESSION_RESP,MSG_QUEUE_ID_SESSION,AuthError)  fail");
				}
			}
		}

		void send_auth_fail_to_connect(USER_NAME& userName)
		{
			if(gDebugFlag)
			{
				LOG(LOG_DEBUG, "CLogicForward::send_auth_fail_to_connect(user=%s)", userName.str());
			}
			//����sessionͷ
			CConnectProtocol conpro(m_ptoolkit->send_buff(), m_ptoolkit->send_buff_len());
			MSG_SESSION* p = conpro.session();
			*p = m_sessionBuff;
			p->flag = SESSION_FLAG_ZERO;// ��ֹ����
			
			//����connect
			int packetLen = conpro.packet_len();
			if(gParsePacket.create_login_fail_to_connect(userName, conpro.packet(), packetLen)==0)
			{
				if(m_ptoolkit->send_to_queue(CMD_SESSION_RESP,MSG_QUEUE_ID_SESSION,conpro.total_len(packetLen)) != 0)
				{
					LOG(LOG_ERROR, "send_to_queue(CMD_SESSION_RESP,MSG_QUEUE_ID_SESSION,AuthError)  fail");
				}
			}

			LOG(LOG_INFO, "%s auth fail", userName.str());
		}

		void send_close_to_connect(unsigned long long sessionid, int fd)
		{
			if(gDebugFlag)
			{
				CEpollWrap::UN_SESSION_ID uSession;
				uSession.id = sessionid;
				LOG(LOG_DEBUG, "CLogicForward::send_close_to_connect(fd=%d,%s:%d,%d)", 
					fd, CTcpSocket::addr_to_str(uSession.tcpaddr.ip).c_str(), uSession.tcpaddr.port, uSession.tcpaddr.seq);
			}
			
			//����sessionͷ
			CConnectProtocol conpro(m_ptoolkit->send_buff(), m_ptoolkit->send_buff_len());
			MSG_SESSION* p = conpro.session();
			p->fd = fd;
			p->id = sessionid;
			p->flag = SESSION_FLAG_CLOSE;

			if(m_ptoolkit->send_to_queue(CMD_SESSION_RESP,MSG_QUEUE_ID_SESSION, conpro.total_len(0)) != 0)
			{
				LOG(LOG_ERROR, "send_to_queue(CMD_SESSION_RESP,MSG_QUEUE_ID_SESSION,close) fail");
			}
		}

		void pass_to_logic(char* packet, int packetLen,unsigned int cmd, const char *sid)
		{
			//�������ط�ʹ��protobuf����
			if(gDebugFlag)
			{
				LOG(LOG_DEBUG, "CLogicForward::pass_to_logic(cmd=0x%x, len=%d)", cmd, packetLen);
			}

			//����Ҫ����username������Ϊԭuid + xxxx(5λsid)
			{
				CBinProtocol binpro(packet, packetLen);
				if(!binpro.valid())
				{
					LOG(LOG_ERROR, "binProtocol not valid");
					return;
				}
				USER_NAME inn_name;
				USER_NAME real_name = binpro.head()->parse_name();

				get_inner_username(inn_name, real_name, sid);
				
				binpro.head()->reset_name(inn_name);
			}
			
			//buffһ������
			memcpy(m_ptoolkit->send_buff(), packet, packetLen);
			if(m_ptoolkit->send_to_queue(cmd, MSG_QUEUE_ID_LOGIC, packetLen) != 0)
			{
				LOG(LOG_ERROR, "send_to_queue(%d,MSG_QUEUE_ID_LOGIC) fail", cmd);
			}
		}

		int on_cmd_session_req(CLogicMsg& msg)
		{
			//����state
			m_state = 0;
			
			//sessionЭ��
			unsigned int bodyLen = m_ptoolkit->get_body_len(msg);
			char* body = m_ptoolkit->get_body(msg);
			
			CConnectProtocol conpro(body, bodyLen);
			if(!conpro.valid())
			{
				LOG(LOG_ERROR, "readBuffLen=%d too small", bodyLen);
				return -1;
			}
			
			MSG_SESSION* pSession = conpro.session();
			//����session
			m_sessionBuff = *pSession;
			
			unsigned int packLen = conpro.packet_len();
			char* packet = conpro.packet();
			
			//�Ƿ��ǿ��ư�
			if(pSession->flag == SESSION_FLAG_CLOSE)
			{
				USER_NAME tmp;
				char sid[16];
				USER_NAME inner_name;
				int ret = gSessionMap.force_close_session(pSession->id, tmp, sid);
				get_inner_username(inner_name,tmp,sid);
				if(ret == 1)
				{
					if(gDebugFlag)
					{
						LOG(LOG_DEBUG, "CLogicForward::force_close_session(usr=%s)",inner_name.str());
					}
					//����logout����,�������ֶ������Ƿ��ǿͻ��˷�����(nothing=1)�������logic server���ûذ�����
					if(gSendLogoutOnClose)
						send_logout_to_logic(inner_name);
				}
				return RET_DONE;
			}
			
			//������
			PARSE_REQ_PACKET_RESULT result;
			if(gParsePacket.parseReq(result, packet, packLen) != 0)
			{
				return RET_DONE;
			}

			if(gIgnoreLoginCmd) //����Ҫ��¼,ÿ�ζ�������
			{
				unsigned long long needCloseSession = 0;
				int needCloseFd = 0;
				int ret = gSessionMap.set_authed_user(result.userName,result.userKey,m_sessionBuff.id, m_sessionBuff.fd, needCloseSession, needCloseFd, result.sid);
				if(ret != 0)
				{
					LOG(LOG_ERROR, "set_authed_user fail");
					send_auth_fail_to_connect(result.userName);
					return RET_DONE;
				}
				
				//����оɵ����ӱ��ر�
				if(needCloseSession != 0)
				{
					send_close_to_connect(needCloseSession, needCloseFd);
				}
				
				//���˼�������¼����
				pass_to_logic(packet,packLen, result.cmd, result.sid);
				return RET_DONE;
			}
			
			//����Ƿ��¼����
			if(result.isLogin)
			{
				if(!gLoginNoAuth) //��Ҫȥ��֤
				{
					//Ƕ����֤�߼�
					m_saveReq.set_key(result.userKey.to_str());
					m_saveReq.set_domain(result.platform);
					m_saveUser = result.userName;
					
					//auth��ʱ��
					m_timerID = 0;
					//LOG(LOG_DEBUG, "-----------------------------------before set-----------------------------------");
					//m_ptoolkit->debug_timer();
					int ret = m_ptoolkit->set_timer_s(m_timerID, gTimeout, m_id, CMD_AUTH_TIMEOUT_REQ);
					//LOG(LOG_DEBUG, "-----------------------------------after set------------------------------------");
					//m_ptoolkit->debug_timer();
					if(ret!=0)
					{
						LOG(LOG_ERROR, "set_timer_s() fail");
						return RET_DONE;
					}

					if(m_ptoolkit->send_protobuf_msg(gDebugFlag, m_saveReq, CMD_AUTH_REQ, result.userName, MSG_QUEUE_ID_AUTH)!=0)
					{
						LOG(LOG_ERROR, "send_protobuf_msg(CMD_AUTH_REQ, MSG_QUEUE_ID_AUTH) fail");
						m_ptoolkit->del_timer(m_timerID);
						return RET_DONE;
					}

					
					//����£���ֹ���ҵİ�
					m_state = 1;
					m_cmdLogin = result.cmd;
					memcpy(m_packetLoginBuff, packet, packLen);
					m_packetLoginLen = packLen;
				
					return RET_YIELD;
				}
				else
				{
					//��Ȩͨ����
					CBinProtocol thebin(packet, packLen);
					LoginReq thereq;
					if(m_ptoolkit->parse_protobuf_bin(gDebugFlag, thebin, thereq)!=0)
					{
						LOG(LOG_ERROR, "parse authed loginreq fail");
						send_auth_fail_to_connect(result.userName);
						return RET_DONE;
					}
					
					unsigned long long needCloseSession = 0;
					int needCloseFd = 0;
					int platform = atoi(result.platform.c_str());
					int ret = gSessionMap.set_authed_user(result.userName,result.userKey,m_sessionBuff.id, m_sessionBuff.fd,
						needCloseSession, needCloseFd, result.sid, platform);
					if(ret != 0)
					{
						LOG(LOG_ERROR, "set_authed_user fail");
						send_auth_fail_to_connect(result.userName);
						return RET_DONE;
					}
					
					//����оɵ����ӱ��ر�
					if(needCloseSession != 0)
					{
						send_close_to_connect(needCloseSession, needCloseFd);
					}

					CEpollWrap::UN_SESSION_ID uSession;
					uSession.id = m_sessionBuff.id;
					thereq.set_userip(uSession.tcpaddr.ip);
					in_addr st;
					st.s_addr = uSession.tcpaddr.ip;
					thereq.set_ip(inet_ntoa(st));

					USER_NAME inner_name;
					get_inner_username(inner_name, result.userName, result.sid);
					m_ptoolkit->send_protobuf_msg(gDebugFlag, thereq, result.cmd, inner_name, MSG_QUEUE_ID_LOGIC);
					return RET_DONE;
					
					//���˼�������¼����
					//pass_to_logic(packet,packLen, result.cmd);
					//return RET_DONE;
				}
			}

			char sid[16];
			int platform = 0;
			//��ͨ���������Ƿ���Ҫ��Ȩ
			if(result.cmdNeedLogin)
			{
				bool checkResult;
				
				if(gSessionMap.check_authed(pSession->id, pSession->fd, result.userName, checkResult, sid, &platform) !=0)
				{
					//���sendû����, ������Ҫ�ⲿ������ѭresp=req+1
					send_fail_resp(result.userName, result.cmd+1);
					return RET_DONE;
				}
			
				if(!checkResult)
				{
					//���sendû����
					send_fail_resp(result.userName, result.cmd+1);
					return RET_DONE;
				}

			}
			if(result.cmd == CMD_REGIST_REQ)
			{
				CBinProtocol thebin(packet, packLen);
				RegistReq thereq;
				if(m_ptoolkit->parse_protobuf_bin(gDebugFlag, thebin, thereq)!=0)
				{
					LOG(LOG_ERROR, "parse regist_req fail");
					return RET_DONE;
				}
				
				char szSvrNo[16];
				snprintf(szSvrNo, sizeof(szSvrNo), "%05d", thereq.server());
				CEpollWrap::UN_SESSION_ID uSession;
				uSession.id = m_sessionBuff.id;
				in_addr st;
				st.s_addr = uSession.tcpaddr.ip;
				thereq.set_ip(inet_ntoa(st));
				thereq.set_platform(platform);
				thereq.set_real_name(result.userName.str());
				USER_NAME inner_name;
				get_inner_username(inner_name, result.userName, szSvrNo);
				LOG(LOG_INFO, "UserName,%s,inner_name,%s,sid,%s,platform,%s", result.userName.str(), inner_name.str(), szSvrNo, result.platform.c_str());

				unsigned long long needCloseSession = 0;
				int needCloseFd = 0;
				int ret = gSessionMap.set_authed_user(result.userName, result.userKey, m_sessionBuff.id, m_sessionBuff.fd, needCloseSession, needCloseFd, szSvrNo);
				if(ret != 0)
				{
					LOG(LOG_ERROR, "set_authed_user fail");
					send_auth_fail_to_connect(result.userName);
					return RET_DONE;
				}

				m_ptoolkit->send_protobuf_msg(gDebugFlag, thereq, result.cmd, inner_name, MSG_QUEUE_ID_LOGIC);
				return RET_DONE;
			}
				
			//����ת��
			pass_to_logic(packet,packLen, result.cmd, sid);
			return RET_DONE;
		}

		int on_auth_timeout(CLogicMsg& msg)
		{
			if(m_state != 1)
			{
				LOG(LOG_ERROR, "recv CMD_AUTH_TIMEOUT_REQ, but state != 1");
				return RET_DONE;
			}
			
			send_auth_fail_to_connect(m_saveUser);
			
			return RET_DONE;
		}

		int on_auth_resp(CLogicMsg& msg)
		{
			if(m_state != 1)
			{
				LOG(LOG_ERROR, "recv CMD_AUTH_RESP, but state != 1");
				return RET_DONE;
			}

			//ɾ����ʱ��
			//LOG(LOG_DEBUG, "---------------------------before del------------------------------");
			//m_ptoolkit->debug_timer();
			m_ptoolkit->del_timer(m_timerID);
			//LOG(LOG_DEBUG, "---------------------------after del------------------------------");
			//m_ptoolkit->debug_timer();

			AuthResp resp;
			USER_NAME theuser;
			if(m_ptoolkit->parse_protobuf_msg(gDebugFlag, msg, theuser, resp) != 0)
			{
				LOG(LOG_ERROR, "parse_protobuf_msg AuthResp fail");
				send_auth_fail_to_connect(m_saveUser);
				return RET_DONE;
			}
			
			if(resp.result() != resp.OK)
			{
				LOG(LOG_ERROR, "AuthResp result=%d", resp.result());
				send_auth_fail_to_connect(m_saveUser);
			}
			else
			{
				//��Ȩͨ����
				CBinProtocol thebin(m_packetLoginBuff, m_packetLoginLen);
				LoginReq thereq;
				if(m_ptoolkit->parse_protobuf_bin(gDebugFlag, thebin, thereq)!=0)
				{
					LOG(LOG_ERROR, "parse authed loginreq fail");
					send_auth_fail_to_connect(m_saveUser);
					return RET_DONE;
				}
				
				unsigned long long needCloseSession = 0;
				int needCloseFd = 0;
				USER_KEY thekey;
				thekey.from_str(m_saveReq.key());
				
				int platform = atoi(thereq.domain().c_str());
				const char *sid = "1";
				if(thereq.has_sid())
					sid = thereq.sid().c_str();
				int ret = gSessionMap.set_authed_user(m_saveUser,thekey,m_sessionBuff.id, m_sessionBuff.fd, 
					needCloseSession, needCloseFd, sid, platform);
				if(ret != 0)
				{
					LOG(LOG_ERROR, "set_authed_user fail");
					send_auth_fail_to_connect(m_saveUser);
					return RET_DONE;
				}
		
				//����оɵ����ӱ��ر�
				if(needCloseSession != 0)
				{
					send_close_to_connect(needCloseSession, needCloseFd);
				}

				LOG(LOG_INFO, "%s authed", m_saveUser.str());

				CEpollWrap::UN_SESSION_ID uSession;
				uSession.id = m_sessionBuff.id;
				thereq.set_userip(uSession.tcpaddr.ip);
				in_addr st;
				st.s_addr = uSession.tcpaddr.ip;
				thereq.set_ip(inet_ntoa(st));

				USER_NAME inner_name;
				get_inner_username(inner_name, theuser, sid);
				//pass_to_logic(m_packetLoginBuff, m_packetLoginLen, m_cmdLogin);
				m_ptoolkit->send_protobuf_msg(gDebugFlag,thereq,
					m_cmdLogin, inner_name, MSG_QUEUE_ID_LOGIC);
				return RET_DONE;

			}
			
			return RET_DONE;
		}
		
	public:
		virtual void on_init()
		{
		}
		
		//��msg�����ʱ�򼤻����
		virtual int on_active(CLogicMsg& msg)
		{
			if(gDebugFlag)
			{
				LOG(LOG_DEBUG, "CLogicForward(%u)::on_active(cmd=%u)", m_id, m_ptoolkit->get_cmd(msg));
			}
			//cout << m_ptoolkit->get_body(msg) << endl;
			if(m_ptoolkit->get_cmd(msg) == CMD_SESSION_REQ)
			{
				return on_cmd_session_req(msg);
			}
			else if(m_ptoolkit->get_cmd(msg) == CMD_AUTH_TIMEOUT_REQ)
			{
				//��ʱ�߼�
				return on_auth_timeout(msg);
			}
			else if(m_ptoolkit->get_cmd(msg) == CMD_AUTH_RESP)
			{
				//��ȨӦ��
				return on_auth_resp(msg);
			}
			else
				LOG(LOG_ERROR, "unexpect cmd=%u" , m_ptoolkit->get_cmd(msg) );

			return RET_DONE;
		}
		
		//��������ǰ����һ��
		virtual void on_finish()
		{
		}

		virtual CLogicProcessor* create()
		{
			return new CLogicForward;
		}

	
	protected:
		unsigned int m_timerID;
		unsigned int m_state;
		MSG_SESSION m_sessionBuff;
		AuthReq m_saveReq;
		USER_NAME m_saveUser;
		char m_packetLoginBuff[MSG_BUFF_LIMIT];
		int m_packetLoginLen;
		unsigned int m_cmdLogin;
};

//��logic->connect�Ľ�����
class CLogicBackward:public CLogicProcessor
{
protected:
	void pass_to_connect(const char* packet, int packetLen, MSG_SESSION& session)
	{
		if(gDebugFlag)
		{
			CEpollWrap::UN_SESSION_ID uSession;
			uSession.id = session.id;
			LOG(LOG_DEBUG, "CLogicBackward::pass_to_connect(fd=%d,%s:%d,%d)", 
				session.fd, CTcpSocket::addr_to_str(uSession.tcpaddr.ip).c_str(), uSession.tcpaddr.port, uSession.tcpaddr.seq);
		}
		
		CConnectProtocol conpro(m_ptoolkit->send_buff(), m_ptoolkit->send_buff_len());
		MSG_SESSION* p = conpro.session();
		p->fd = session.fd;
		p->id = session.id;
		p->flag = session.flag;
		p->channel_id = session.channel_id;

		if(conpro.packet_len() < packetLen)
		{
			LOG(LOG_ERROR, "resp msg too long");
			return;
		}

		memcpy(conpro.packet(), packet, packetLen);

		//����
		if(m_ptoolkit->send_to_queue(CMD_SESSION_RESP, MSG_QUEUE_ID_SESSION, conpro.total_len(packetLen)) != 0)
		{
			LOG(LOG_ERROR, "send_to_queue %u fail", MSG_QUEUE_ID_SESSION);
		}
	}

	void send_close_to_connect(unsigned long long sessionid, int fd)
	{
		if(gDebugFlag)
		{
			CEpollWrap::UN_SESSION_ID uSession;
			uSession.id = sessionid;
			LOG(LOG_DEBUG, "CLogicBackward::send_close_to_connect(fd=%d,%s:%d,%d)", 
				fd, CTcpSocket::addr_to_str(uSession.tcpaddr.ip).c_str(), uSession.tcpaddr.port, uSession.tcpaddr.seq);
		}
		
		//����sessionͷ
		CConnectProtocol conpro(m_ptoolkit->send_buff(), m_ptoolkit->send_buff_len());
		MSG_SESSION* p = conpro.session();
		p->fd = fd;
		p->id = sessionid;
		p->flag = SESSION_FLAG_CLOSE;
	
		if(m_ptoolkit->send_to_queue(CMD_SESSION_RESP,MSG_QUEUE_ID_SESSION, conpro.total_len(0)) != 0)
		{
			LOG(LOG_ERROR, "send_to_queue(CMD_SESSION_RESP,MSG_QUEUE_ID_SESSION,close) fail");
		}
	}

	void send_msg_to_connect_by_uid(USER_NAME &uid, const char* packet, int packetLen)
	{
		unsigned long long sessionID;
		int fd;
		int ret = gSessionMap.find_session(uid,sessionID, fd);
		if(ret <= 0)
		{
			LOG(LOG_ERROR, "find_session for %s =%d fail", uid.str(),ret);
			return;
		}

		if(gDebugFlag)
		{
			CEpollWrap::UN_SESSION_ID uSession;
			uSession.id = sessionID;
			LOG(LOG_DEBUG, "CLogicBackward::pass_to_connect(fd=%d,%s:%d,%d)", 
				fd, CTcpSocket::addr_to_str(uSession.tcpaddr.ip).c_str(), uSession.tcpaddr.port, uSession.tcpaddr.seq);
		}
		
		CConnectProtocol conpro(m_ptoolkit->send_buff(), m_ptoolkit->send_buff_len());
		MSG_SESSION* p = conpro.session();
		p->fd = fd;
		p->id = sessionID;
		p->flag = SESSION_FLAG_ZERO;

		if(conpro.packet_len() < packetLen)
		{
			LOG(LOG_ERROR, "resp msg too long");
			return;
		}

		memcpy(conpro.packet(), packet, packetLen);

		//����
		if(m_ptoolkit->send_to_queue(CMD_SESSION_RESP, MSG_QUEUE_ID_SESSION, conpro.total_len(packetLen)) != 0)
		{
			LOG(LOG_ERROR, "send_to_queue %u fail", MSG_QUEUE_ID_SESSION);
		}
	}
	
public:
	virtual void on_init()
	{
	}
	
	//��msg�����ʱ�򼤻����
	virtual int on_active(CLogicMsg& msg)
	{
		//������
		PARSE_RESP_PACKET_RESULT result;
		char* packet = m_ptoolkit->get_body(msg);
		int packLen =  m_ptoolkit->get_body_len(msg);
		int ret = gParsePacket.parseResp(result, packet, packLen);
		if(ret != 0)
		{
			return RET_DONE;
		}

		//����session
		MSG_SESSION sessionHead;
		if( (result.cmd != CMD_CHANNEL_CMD && result.cmd != CMD_CHAT_MSG)
			|| (result.cmd == CMD_CHANNEL_CMD && result.channel_info.cmd != CHANNEL_SYNC)
			)
		{
			ret = gSessionMap.find_session(result.userName,sessionHead.id, sessionHead.fd);
			if(ret <= 0)
			{
				LOG(LOG_ERROR, "find_session for %s =%d fail", result.userName.str(),ret);
				return RET_DONE;
			}
		}
		if(result.cmd == CMD_CHANNEL_CMD)
		{
			if(result.channel_info.cmd == CHANNEL_ADD)
			{
				sessionHead.flag = SESSION_FLAG_ADD;
				sessionHead.channel_id = result.channel_info.channel_id;
			}
			else if(result.channel_info.cmd == CHANNEL_REMOVE)
			{
				sessionHead.flag = SESSION_FLAG_REMOVE;
				sessionHead.channel_id = result.channel_info.channel_id;
			}
			else if(result.channel_info.cmd == CHANNEL_SYNC)
			{
				sessionHead.flag = SESSION_FLAG_SYNC;
				sessionHead.channel_id = result.channel_info.channel_id;
				packet += (sizeof(CHANNEL_CTRL) + sizeof(BIN_PRO_HEADER));
				packLen -= (sizeof(CHANNEL_CTRL) + sizeof(BIN_PRO_HEADER));
			}
		}
		else if(result.cmd == CMD_CHAT_MSG)
		{
			if(result.chat_info.channel == 1 || result.chat_info.channel == 2)
			{// ˽��
				vector<string>::iterator it = result.chat_info.recvs.begin();
				for(;it != result.chat_info.recvs.end(); it++)
				{
					USER_NAME uid;
					uid.from_str(*it);
					send_msg_to_connect_by_uid(uid, packet, packLen);
				}
			}
			else if(result.chat_info.channel == 0)
			{//ȫ��
				sessionHead.flag = SESSION_FLAG_BROADCAST;
				pass_to_connect(packet, packLen, sessionHead);
			}
			return RET_DONE;
		}
		else if(result.cmd == CMD_MULTICAST)
		{	// �鲥
			int data_len = sizeof(BIN_PRO_HEADER);
			char *buff = (char *)malloc(packLen);
			if(buff == NULL)
			{
				LOG(LOG_ERROR, "malloc err");
				return RET_DONE;
			}
			memcpy(buff, packet, sizeof(BIN_PRO_HEADER));
			if (result.multicast_info.cmd == CMD_GROUP_UPDATE)
			{
				if (!result.multicast_info.group_update.SerializeToArray(buff + sizeof(BIN_PRO_HEADER), packLen - sizeof(BIN_PRO_HEADER)))
				{
					LOG(LOG_ERROR, "multicast serialize to array error");
					free(buff);
					return RET_DONE;
				}
				data_len += result.multicast_info.group_update.GetCachedSize();
				LOG(LOG_DEBUG, "%d | %s", result.multicast_info.group_update.GetCachedSize(), result.multicast_info.group_update.DebugString().c_str());
			}
			else if(result.multicast_info.cmd == CMD_USER_SYNC_UPDATE){
				if (!result.multicast_info.user_sync.SerializeToArray(buff + sizeof(BIN_PRO_HEADER), packLen - sizeof(BIN_PRO_HEADER)))
				{
					LOG(LOG_ERROR, "multicast serialize to array error");
					free(buff);
					return RET_DONE;
				}
				data_len += result.multicast_info.user_sync.GetCachedSize();
				LOG(LOG_DEBUG, "%d | %s", result.multicast_info.user_sync.GetCachedSize(), result.multicast_info.user_sync.DebugString().c_str());
			}
			else{
				memcpy(buff + sizeof(BIN_PRO_HEADER), result.multicast_info.msg_buff.c_str(),  result.multicast_info.msg_buff.size());
				data_len += result.multicast_info.msg_buff.size();
				LOG(LOG_DEBUG, "%d | %s", (int)result.multicast_info.msg_buff.size(), result.multicast_info.msg_buff.c_str());
			}

			
			BIN_PRO_HEADER * head = (BIN_PRO_HEADER *)(buff);
			if(head->useNetOrder)
			{
				head->packetLen = htonl(data_len);
				head->cmd = htonl(result.multicast_info.cmd);
			}
			else
			{
				head->cmd = result.multicast_info.cmd;
				head->packetLen = data_len;
			}
			
			vector<string>::iterator it = result.multicast_info.recv_list.begin();
			for(;it != result.multicast_info.recv_list.end(); it++)
			{
				USER_NAME uid;
				uid.from_str(*it);
				send_msg_to_connect_by_uid(uid, buff, data_len);
			}
			free(buff);
			return RET_DONE;
		}
		else
			sessionHead.flag = SESSION_FLAG_ZERO;
			
		pass_to_connect(packet, packLen, sessionHead);
		
		//����Ƿ�logout�ذ��������sessionMap��ɾ��user����׷��һ��close��
		if(result.isLogoutOK)
		{
			//sessionHead��id��fdӦ�ò���ı�
			USER_NAME real_name;
			get_real_username(real_name, result.userName);
			ret = gSessionMap.del_authed_user(real_name,sessionHead.id, sessionHead.fd);
			if(ret != 0)
			{
				LOG(LOG_ERROR, "del_authed_user for %s fail", result.userName.str());
			}

			//close��
			send_close_to_connect(sessionHead.id, sessionHead.fd);
			LOG(LOG_INFO, "%s logouted close connection", result.userName.str());
		}

		return RET_DONE;
	}
	
	//��������ǰ����һ��
	virtual void on_finish()
	{
	}
	
	virtual CLogicProcessor* create()
	{
		return new CLogicBackward;
	}

};


struct SESSION_AUTH_CONFIG
{
	LOG_CONFIG logConf;

	//map����
	unsigned int shmkey_map;
	size_t mapUserNum;
	size_t mapHashNum;

	//time out ����
	unsigned int timeoutS;

	void debug(ostream& out)
	{
		out << "SESSION_AUTH_CONFIG{" << endl;
		out << "shmkey_map|0x" << hex << shmkey_map << dec << endl; 
		out << "mapUserNum|" << mapUserNum << endl; 
		out << "mapHashNum|" << mapHashNum << endl; 
		out << "timeoutS|" << timeoutS << endl;
		out << "}END SESSION_AUTH_CONFIG" << endl;
	}
};


CLogicBackward gSuperLogicProto;

class CLogicAuthDriver:public CLogicDriver
{
	public:
		
		//return 0=����superCreator, ������ʹ��
		int set_super_creator(CLogicMsg& msg, CLogicCreator& superCreator)
		{
			if(msg.head()->queueID == MSG_QUEUE_ID_LOGIC)
			{
				superCreator = CLogicCreator(&gSuperLogicProto); //ǧ��Ҫnew CLogicAuth û���ͷŵ�
				return 0;
			}
			return -1;
		}
};

CLogicAuthDriver driver; // ʹ����set_super_creator
static void stophandle(int iSigNo)
{
	driver.stopFlag = 1;
	LOG(LOG_INFO, "recieve siganal %d, stop",  iSigNo);
	LOG(LOG_ERROR, "recieve siganal %d, stop",  iSigNo);
}

static void usr1handle(int iSigNo)
{
	gDebugFlag = (gDebugFlag+1)%2;
	cout << "session_auth debug=" << gDebugFlag << endl;
}


int main(int argc, char** argv)
{
	if(argc < 3)
	{
		cout << argv[0] << " connect_config_ini pipe_conf_ini" << endl;
		return 0;
	}

	CIniFile oIni(argv[1]);
	if(!oIni.IsValid())
	{
		cout << "read ini " << argv[1] << "fail" << endl;
		return 0;
	}
	
	SESSION_AUTH_CONFIG config;
	CLogicDriverConfig configDriver;
	int ret = 0;

	//log
	config.logConf.read_from_ini(oIni, "SESSION_AUTH");
	LOG_CONFIG_SET(config.logConf);
	cout << "log open=" << LOG_OPEN("session_auth",LOG_DEBUG) << " " << LOG_GET_ERRMSGSTRING << endl;

	//logic driver ����
	ret = configDriver.readFromIni(oIni);
	if(ret < 0)
	{
		cout << "CLogicDriverConfig readFromIni fail" << endl;
		return 0;
	}
	configDriver.useSuperCreator = true; //�򿪲���ʹset_super_creator��Ч

	//pipe config
	CPIPEConfigInfo pipeconfig;
	if(pipeconfig.set_config(argv[2])!= 0)
	{
		cout << "parse ini fail " << endl;
		return 0;
	}

	//gSendLogoutOnClose
	oIni.GetInt("SESSION_AUTH", "SEND_LOGOUT_ON_CLOSE", 0, &gSendLogoutOnClose);
	cout << "gSendLogoutOnClose=" << gSendLogoutOnClose << endl;

	oIni.GetInt("SESSION_AUTH", "LOGIN_NO_AUTH", 0, &gLoginNoAuth);
	cout << "gLoginNoAuth=" << gLoginNoAuth << endl;

	oIni.GetInt("SESSION_AUTH", "IGNORE_LOGIN_CMD", 0, &gIgnoreLoginCmd);
	cout << "gIgnoreLoginCmd=" << gIgnoreLoginCmd << endl;

	//queue����
	if(oIni.GetInt("CONNECT", "GLOBE_PIPE_ID", 0, &MSG_QUEUE_ID_SESSION)!=0)
	{
	 	cout << "CONNECT.GLOBE_PIPE_ID not found" << endl;
		return 0;
	}
	
	if(oIni.GetInt("SESSION_AUTH", "GLOBE_PIPE_ID_BACK", 0, &MSG_QUEUE_ID_LOGIC)!=0)
	{
		cout << "SESSION_AUTH.GLOBE_PIPE_ID_BACK not found" << endl;
		return 0;
	}

	if(oIni.GetInt("SESSION_AUTH", "GLOBE_PIPE_ID_AUTH", 0, &MSG_QUEUE_ID_AUTH)!=0)
	{
		cout << "SESSION_AUTH.GLOBE_PIPE_ID_AUTH not found" << endl;
		return 0;
	}
	
	if(oIni.GetInt("SESSION_AUTH", "SESSION_MAP_KEY", 0, &config.shmkey_map)!=0)
	{
		cout << "SESSION_AUTH.SESSION_MAP_KEY not found" << endl;
		return 0;
	}

	unsigned int mapUserNum = 0;
	if(oIni.GetInt("SESSION_AUTH", "SESSION_MAP_NODE_NUM", 10000, &mapUserNum)!=0)
	{
		cout << "SESSION_AUTH.SESSION_MAP_NODE_NUM not found" << endl;
		return 0;
	}
	config.mapUserNum = mapUserNum;

	unsigned int mapHashNum = 0;
	if(oIni.GetInt("SESSION_AUTH", "SESSION_MAP_HASH_NUM", 10000, &mapHashNum)!=0)
	{
		cout << "SESSION_AUTH.SESSION_MAP_HASH_NUM not found" << endl;
		return 0;
	}
	config.mapHashNum = mapHashNum;

	//conf.timeoutS = 1;
	//auth time out
	oIni.GetInt("SESSION_AUTH", "AUTH_TIMEOUT_S", 1, &config.timeoutS);
	if(config.timeoutS > 0)
		gTimeout = config.timeoutS;

	config.debug(cout);
	if(config.mapHashNum == 0 || config.mapUserNum == 0 || config.shmkey_map == 0)
	{
		cout << "session map config fail" << endl;
		return 0;
	}
	
	//map
	ret = gSessionMap.init(config.shmkey_map, config.mapUserNum, config.mapHashNum);
	if(ret != 0)
	{
		cout << "gSessionMap.init fail" << endl;
		return 0;
	}
	int sessionTimeout = 0;
	oIni.GetInt("CONNECT", "IDLE_TIMEOUT_S", 3600, &sessionTimeout);
	cout << "sessionTimeout=" << sessionTimeout << endl;
	gSessionMap.cleanTimeoutNode(sessionTimeout);
	
	CDequePIPE pipeForward;
	ret = pipeForward.init(pipeconfig, MSG_QUEUE_ID_SESSION, false);
	if(ret != 0)
	{
		cout << "pipeForward.init " << pipeForward.errmsg() << endl;
		return 0;
	}
	CMsgQueuePipe queuePipeForward(pipeForward, &gDebugFlag);

	CDequePIPE pipeBackward;
	ret = pipeBackward.init(pipeconfig, MSG_QUEUE_ID_LOGIC, true);
	if(ret != 0)
	{
		cout << "pipeBackward.init " << pipeBackward.errmsg() << endl;
		return 0;
	}
	CMsgQueuePipe queuePipeBackward(pipeBackward, &gDebugFlag);

	CDequePIPE pipeAuth;
	ret = pipeAuth.init(pipeconfig, MSG_QUEUE_ID_AUTH, true);
	if(ret != 0)
	{
		cout << "pipeAuth.init " << pipeAuth.errmsg() << endl;
		return 0;
	}
	CMsgQueuePipe queuePipeAuth(pipeAuth, &gDebugFlag);

	ret = driver.add_msg_queue(MSG_QUEUE_ID_SESSION,&queuePipeForward);
	if(ret != 0)
	{
		cout << "add_msg_queue(" << MSG_QUEUE_ID_SESSION << ") fail "  << endl;
		return 0;
	}

	ret = driver.add_msg_queue(MSG_QUEUE_ID_LOGIC,&queuePipeBackward);
	if(ret != 0)
	{
		cout << "add_msg_queue(" << MSG_QUEUE_ID_LOGIC << ") fail "  << endl;
		return 0;
	}

	ret = driver.add_msg_queue(MSG_QUEUE_ID_AUTH,&queuePipeAuth);
	if(ret != 0)
	{
		cout << "add_msg_queue(" << MSG_QUEUE_ID_AUTH << ") fail "  << endl;
		return 0;
	}

	//ע������(������init֮ǰ������fail)
	ret = driver.regist_handle(CMD_SESSION_REQ, CLogicCreator(new CLogicForward));
	if(ret != 0)
	{
		cout << "regist_handle CLogicAuth fail "  << endl;
		return 0;
	}

	//init
	ret = driver.init(configDriver);
	if(ret != 0)
	{
		cout << "init fail" << endl;
		return 0;
	}

	//lock & daemon
	if(CServerTool::run_by_ini(&oIni, "SESSION_AUTH")!=0)
	{
		cout << "run_by_ini  fail" << endl;
		return 0;
	}
	CServerTool::sighandle(SIGTERM, stophandle);
	CServerTool::sighandle(SIGUSR1, usr1handle);

	//��ʼrun��
	cout << "main_loop=" << driver.main_loop(-1) << endl;
	
	return 1;

}



