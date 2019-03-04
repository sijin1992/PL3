#ifndef __PARSE_PACKET_H__
#define __PARSE_PACKET_H__
#include "common/msg_define.h"
#include "common/packet_interface.h"
#include "common/bin_protocol.h"
#include "logic/msg.h"
#include "log/log.h"
#include "../../proto/logoutReq.pb.h"
#include <google/protobuf/message.h>
#include "../../proto/CmdLogin.pb.h"
#include "../../proto/CmdUser.pb.h"
#include "../../proto/UserSync.pb.h"
#include "../../proto/CmdGroup.pb.h"
#include "../../proto/inner_cmd.pb.h"


using namespace google::protobuf;
extern int gDebugFlag;

//����packet�Ĺ���
struct PARSE_REQ_PACKET_RESULT
{
	unsigned int cmd; //cmd������
	USER_NAME userName; //���ֱ�����
	bool isLogin; //�Ƿ���login��������cmd�ж�
	USER_KEY userKey;  //��login����������
	bool cmdNeedLogin; //��cmd�Ƿ�����ǵ�¼���͵ģ�����cmd�ж�
	string platform; //ƽ̨
	char sid[16];		//������id
};

struct ChatStruct
{
	int32 channel;
	vector<string> recvs;
};

// 
struct MulticastStruct
{
	vector<string> recv_list;
	int32 cmd;
	GroupUpdate group_update;
	string msg_buff;
	UserSync user_sync;
};

struct PARSE_RESP_PACKET_RESULT
{
	unsigned int cmd; //cmd������
	USER_NAME userName; //���ֱ�����
	bool isLogoutOK; //�Ƿ���isLogout�ذ�������cmd�����ж�
	CHANNEL_CTRL channel_info;
	ChatStruct chat_info;
	MulticastStruct multicast_info;
};

class CParsePacket
{
public:
	//��session������ģ�����֮���ǿͻ��˵Ķ����ư�
	int parseReq(PARSE_REQ_PACKET_RESULT& result, char* binPacket, unsigned int binPacketLen)
	{
		CBinProtocol binpro(binPacket, binPacketLen);
		if(!binpro.valid())
		{
			LOG(LOG_ERROR, "binProtocol not valid");
			return -1;
		}


		result.cmd = binpro.head()->parse_cmd();
		result.userName = binpro.head()->parse_name();
		
		if(result.cmd == CMD_LOGIN_REQ)
		{
			result.isLogin = true;
			result.cmdNeedLogin = false;
			
			if(get_key_from_pb(binpro.packet(), binpro.packet_len(), result)!=0)
			{
				LOG(LOG_ERROR, "get_key_from_pb fail");
				return -1;
			}

		}
		else
		{
			result.isLogin = false;
			result.cmdNeedLogin = result.cmd == CMD_REGIST_REQ ? false : true;
			result.platform = "";
		}
		
		return 0;
	}

	//��logic�������
	int parseResp(PARSE_RESP_PACKET_RESULT& result, char* binPacket, unsigned int binPacketLen)
	{
		CBinProtocol binpro(binPacket, binPacketLen);
		if(!binpro.valid())
		{
			bool err = true;
			if(binpro.head()->parse_len() < binPacketLen && binpro.head()->parse_cmd() == CMD_CHANNEL_CMD)
			{
				binpro.bind(binPacket, binpro.head()->parse_len());
				if(binpro.valid())
					err = false;
			}
			if(err)
			{
				LOG(LOG_ERROR, "binProtocol not valid");
				return -1;
			}
		}
		
		result.cmd = binpro.head()->parse_cmd();
		result.userName = binpro.head()->parse_name();
		if(result.cmd == CMD_LOGOUT_RESP)
		{
			result.isLogoutOK = true; //��Ϊlogout�϶���ok��
		}
		else
		{
			result.isLogoutOK = false;
		}
		if(result.cmd == CMD_CHANNEL_CMD)
		{
			result.channel_info = *(CHANNEL_CTRL*)(binpro.packet());
		}
		if(result.cmd == CMD_CHAT_MSG)
		{
			ChatMsg msg;
			if(!msg.ParseFromArray(binpro.packet(), binpro.packet_len()))
			{
				LOG(LOG_ERROR, "ChatMsg.ParseFromArray fail");
				return -1;
			}

			if(gDebugFlag)
			{
				LOG(LOG_DEBUG, "%s|chat: %s",result.userName.str(),msg.DebugString().c_str());
			}
			result.chat_info.channel = msg.channel();
			if(msg.channel() == 1)
			{
				if(msg.has_recver())
				{
					result.chat_info.recvs.push_back(msg.recver().uid());
				}
				if(msg.has_sender())
				{
					result.chat_info.recvs.push_back(msg.sender().uid());
				}
			}
			else if(msg.channel() == 2)
			{
				for(int i = 0; i < msg.recvs_size(); i++)
				{
					result.chat_info.recvs.push_back(msg.recvs(i));
				}
			}
		}
		// �鲥
		if(result.cmd == CMD_MULTICAST)
		{
			Multicast msg;
			if(!msg.ParseFromArray(binpro.packet(), binpro.packet_len()))
			{
				LOG(LOG_ERROR, "Multicast.ParseFromArray fail");
				return -1;
			}

			if(gDebugFlag)
			{
				LOG(LOG_DEBUG, "%s|chat: %s",result.userName.str(),msg.DebugString().c_str());
			}

			result.multicast_info.cmd = msg.cmd();
			for(int i = 0; i < msg.recv_list_size(); i++)
			{
				result.multicast_info.recv_list.push_back(msg.recv_list(i));
			}
			if(msg.cmd() == CMD_GROUP_UPDATE)
			{
			 	if(!msg.has_group_update())
			 	{
			 		LOG(LOG_ERROR, "GroupUpdate not has group_data");
			 		return -1;
			 	}
			 	else
			 	{
			 		result.multicast_info.group_update.CopyFrom(msg.group_update());
			 	}
			}
			else if (msg.cmd() == CMD_USER_SYNC_UPDATE)
			{
				if (!msg.has_user_sync())
				{
					LOG(LOG_ERROR, "USER_SYNC_UPDATE not has user_sync");
					return -1;
				}
				else
				{
					result.multicast_info.user_sync.CopyFrom(msg.user_sync());
				}
			}
			else
			{	
			 	// LOG(LOG_ERROR, "unknow cmd");
			 	// return -1;
			 	if(!msg.has_msg_buff())
				{
					LOG(LOG_ERROR, "multicast not has msg buff");
					return -1;
				}
				else
				{
					result.multicast_info.msg_buff = msg.msg_buff();
				}
			}

			
		}
		return 0;

	}

	int create_logout_to_logic(USER_NAME& userName, char* buff, int& buffLen)
	{
		//protobuf��һ��+������Э��ͷ
		m_logoutReq.Clear();
		m_logoutReq.set_nothing(1);
		CBinProtocol binpro(buff, buffLen);
		if(!m_logoutReq.SerializeToArray(binpro.packet(), binpro.packet_len()))
		{
			LOG(LOG_ERROR, "m_logoutReq.SerializeToArray fail");
			return -1;
		}

		buffLen = binpro.total_len(m_logoutReq.ByteSize());
		binpro.head()->format(userName,CMD_LOGOUT_REQ, buffLen);
		return 0;
	}

	int create_fail_resp(USER_NAME& userName, unsigned int cmd, char* buff, int& buffLen)
	{
		CBinProtocol binpro(buff, buffLen);
		buffLen = binpro.total_len(0);
		binpro.head()->format_fail(userName, cmd);
		return 0;
	}

	//auth �������
	int create_login_fail_to_connect(USER_NAME& userName, char* buff, int& buffLen)
	{
		//��protobuf��һ��+������Э��ͷ
		m_loginResp.Clear();
		m_loginResp.set_result(LoginResp_LoginRet_NOAUTH);
		m_loginResp.set_user_name("");
		m_loginResp.set_key("");
		m_loginResp.set_isinit(false);
		CBinProtocol binpro(buff, buffLen);
		if(!m_loginResp.SerializeToArray(binpro.packet(), binpro.packet_len()))
		{
			LOG(LOG_ERROR, "m_loginResp.SerializeToArray fail");
			return -1;
		}

		buffLen = binpro.total_len(m_loginResp.ByteSize());
		binpro.head()->format(userName,CMD_LOGIN_RESP, buffLen);
		return 0;
	}

protected:
	int get_key_from_pb(const char* pbBuff, int pbBuffLen, PARSE_REQ_PACKET_RESULT& result)
	{
		m_loginReq.Clear();
		if(!m_loginReq.ParseFromArray(pbBuff, pbBuffLen))
		{
			LOG(LOG_ERROR, "m_loginReq.ParseFromArray fail");
			return -1;
		}

		if(gDebugFlag)
		{
			LOG(LOG_DEBUG, "%s|LOGIN: %s",result.userName.str(),m_loginReq.DebugString().c_str());
		}

		result.userKey.from_str(m_loginReq.key());
		result.platform = m_loginReq.domain();
		if(m_loginReq.has_sid())
			strncpy(result.sid, m_loginReq.sid().c_str(), 5);
		else
			strncpy(result.sid, "1", 5);
		return 0;
	}

protected:
	LoginReq m_loginReq;
	LoginResp m_loginResp;
	LogoutReq m_logoutReq;


};

#endif
