#ifndef __LOGIC_TOOLKIT_H__
#define __LOGIC_TOOLKIT_H__

#include "msg.h"
#include "msg_queue.h"
#include "struct/timer.h"
#include "log/log.h"
#include "../common/msg_define.h"
#include "../common/bin_protocol.h"
#include <map>
#include <iostream>
#include <sstream>
#include <google/protobuf/message.h>
#include "string/strutil.h" //libsrc/string

using namespace std;
using namespace google::protobuf;

struct DRIVER_TIMER_DATA
{
	unsigned int handleID;
	unsigned int msgCmd;
	unsigned int userFlag;
};

typedef map<unsigned int, CMsgQueue*> MSG_QUEUE_MAP;
typedef CTimerPool<DRIVER_TIMER_DATA> DRIVER_TIMER;

class CToolkit
{
public:
	CToolkit():m_msg(writeBuff, sizeof(writeBuff))
	{
		m_serverID = 0;
		m_ptimer = NULL;
		m_pqueuemap = NULL;
		m_processorID = 0;
	}

	inline void init(DRIVER_TIMER* ptimer, MSG_QUEUE_MAP* pmap, unsigned int thisSeverID)
	{
		m_ptimer = ptimer;
		m_pqueuemap = pmap;
		m_serverID = thisSeverID;
	}

	inline void set_processorID(unsigned int processorID)
	{
		m_processorID = processorID;
	}

	//发送msg, tool_kit内置一个消息，不用再创建了
	inline char* send_buff()
	{
		return m_msg.body();
	}

	inline unsigned int send_buff_len()
	{
		return m_msg.body_buff_len();
	}

	inline CLogicMsg& make_send_msg(unsigned int cmd, unsigned int bodySize,unsigned int desSeverID = 0, unsigned int desHandleID = 0)
	{
		m_msg.head()->cmdID = cmd;
		m_msg.head()->srcHandleID = m_processorID;
		m_msg.head()->srcServerID = m_serverID;
		m_msg.head()->desHandleID = desHandleID;
		m_msg.head()->desServerID = desSeverID;
		m_msg.head()->queueID = 1; 
		m_msg.head()->bodySize = bodySize;
		return m_msg;
	}

	inline int pass_msg(CLogicMsg& msg, unsigned int queueID)
	{
		MSG_QUEUE_MAP::iterator it = m_pqueuemap->find(queueID);
		if(it == m_pqueuemap->end())
		{
			LOG(LOG_ERROR, "queueID=%u not exsit", queueID);
			return -1;
		}

		CMsgQueue* pqueue = it->second;

		return pqueue->send_msg(msg);
	}
	
	inline int send_to_queue(unsigned int cmd, unsigned int queueID, unsigned int bodySize,unsigned int desSeverID = 0, unsigned int desHandleID = 0)
	{
		m_msg.head()->cmdID = cmd;
		m_msg.head()->srcHandleID = m_processorID;
		m_msg.head()->srcServerID = m_serverID;
		m_msg.head()->desHandleID = desHandleID;
		m_msg.head()->desServerID = desSeverID;
		m_msg.head()->queueID = queueID; //其实是没有用的，要看接受方的定义
		m_msg.head()->bodySize = bodySize;

		if(m_pqueuemap == NULL)
		{
			LOG(LOG_ERROR, "m_pqueuemap=NULL");
			return -1;
		}

		MSG_QUEUE_MAP::iterator it = m_pqueuemap->find(queueID);
		if(it == m_pqueuemap->end())
		{
			LOG(LOG_ERROR, "queueID=%u not exsit", queueID);
			return -1;
		}

		CMsgQueue* pqueue = it->second;

		return pqueue->send_msg(m_msg);
	}

	//未注册的queue中发送消息，queueID没用了
	inline int send_to_queue(unsigned int cmd, CMsgQueue* pqueue, unsigned int bodySize,unsigned int desSeverID = 0, unsigned int desHandleID = 0)
	{
		m_msg.head()->cmdID = cmd;
		m_msg.head()->srcHandleID = m_processorID;
		m_msg.head()->srcServerID = m_serverID;
		m_msg.head()->desHandleID = desHandleID;
		m_msg.head()->desServerID = desSeverID;
		m_msg.head()->queueID = 1;
		m_msg.head()->bodySize = bodySize;
		return pqueue->send_msg(m_msg);		
	}

	//设置timer
	inline int set_timer_ms(unsigned int& timerID, unsigned int interval, unsigned int desHandleID, unsigned int invokeCmd, unsigned int userFlag=0)
	{
		if(m_ptimer)
		{
			DRIVER_TIMER_DATA data;
			data.handleID = desHandleID;
			data.msgCmd = invokeCmd;
			data.userFlag = userFlag;
			return m_ptimer->set_timer_ms(timerID, data, interval);
		}

		return -1;
	}

	inline int set_timer_s(unsigned int& timerID, unsigned int interval, unsigned int desHandleID, unsigned int invokeCmd, unsigned int userFlag=0)
	{
		if(m_ptimer)
		{
			DRIVER_TIMER_DATA data;
			data.handleID = desHandleID;
			data.msgCmd = invokeCmd;
			data.userFlag = userFlag;
			if(m_ptimer->set_timer_s(timerID, data, interval) !=0)
			{
				LOG(LOG_ERROR, "timer set %ds fail: %d %s", interval, m_ptimer->m_err.errcode, m_ptimer->m_err.errstrmsg);
				return -1;
			}
			return 0;
		}

		LOG(LOG_ERROR, "no timer support");
		return -1;
	}

	inline int del_timer(unsigned int timerID)
	{
		if(m_ptimer)
		{
			return m_ptimer->del_timer(timerID);
		}

		return -1;
	}

	inline unsigned int get_timeout_flag(CLogicMsg& msg)
	{
		char* p = msg.body();
		return *((unsigned int*)p);
	}

	inline void debug_timer()
	{
		ostringstream outs;
		m_ptimer->debug(outs);
		LOG(LOG_DEBUG, "%s", outs.str().c_str());
	}

	//读msg操作,其实不用多封装了
	inline unsigned int get_cmd( CLogicMsg& msg)
	{
		return msg.head()->cmdID;
	}

	inline unsigned int get_queue_id( CLogicMsg& msg)
	{
		return msg.head()->queueID;
	}

	inline unsigned int get_src_handle( CLogicMsg& msg)
	{
		return msg.head()->srcHandleID;
	}

	inline unsigned int get_src_server( CLogicMsg& msg)
	{
		return msg.head()->srcServerID;
	}

	inline unsigned int get_des_server( CLogicMsg& msg)
	{
		return msg.head()->desServerID;
	}

	inline unsigned int get_des_handle( CLogicMsg& msg)
	{
		return msg.head()->desHandleID;
	}

	inline char* get_body( CLogicMsg& msg)
	{
		return msg.body();
	}

	inline unsigned int get_body_len( CLogicMsg& msg)
	{
		return msg.head()->bodySize;
	}
	

	//timer msg操作函数
	inline int is_timer_msg( CLogicMsg& msg)
	{
		return msg.head()->queueID == CLogicMsg::QUEUE_ID_FOR_TIMER;
	}

	inline unsigned int get_timer_id( CLogicMsg& msg)
	{
		return msg.head()->srcHandleID;
	}
	
	inline unsigned int get_timer_flag( CLogicMsg& msg)
	{
		return *((unsigned int *)(msg.body()));
	}



	//server id
	inline unsigned int get_sever_id()
	{
		return m_serverID;
	}

	inline CLogicMsg& msg_ref()
	{
		return m_msg;
	}

	//对bin_protocol的支持
	inline int parse_bin_msg(CLogicMsg& msg, CBinProtocol& binProtocol)
	{
		binProtocol.bind(msg.body(), msg.head()->bodySize);
		if(!binProtocol.valid())
		{
			LOG(LOG_ERROR, "binProtocol not valid");
			return -1;
		}

		return 0;
	}

	inline int parse_protobuf_bin(int debug, CBinProtocol& binpro, Message& theProtoObj)
	{
		if(!theProtoObj.ParseFromArray(binpro.packet(), binpro.packet_len()))
		{	
			LOG(LOG_ERROR, "theProtoObj.ParseFromArray fail");
			return -1;
		}

		if(debug)
		{
			LOG(LOG_DEBUG, "%s|parse proto: %s", binpro.head()->userName.str(), theProtoObj.DebugString().c_str());
		}
		
		return 0;
	}

	//更加方便
	inline int parse_protobuf_msg(int debug, CLogicMsg& msg, USER_NAME& user, Message& theProtoObj)
	{
		CBinProtocol binpro;
		if(parse_bin_msg(msg, binpro) != 0)
			return -1;

		user = binpro.head()->parse_name();

		if(!theProtoObj.ParseFromArray(binpro.packet(), binpro.packet_len()))
		{	
			LOG(LOG_ERROR, "theProtoObj.ParseFromArray fail");
			return -1;
		}

		if(debug)
		{
			LOG(LOG_DEBUG, "%s|parse proto: %s", user.str(), theProtoObj.DebugString().c_str());
		}
		
		return 0;
	}

	inline char* send_binbody_buff()
	{
		CBinProtocol binpro(send_buff(), send_buff_len());
		return binpro.packet();
	}

	inline int send_binbody_buff_len()
	{
		CBinProtocol binpro(send_buff(), send_buff_len());
		return binpro.packet_len();
	}

	inline int send_bin_msg_to_queue(unsigned int cmd, USER_NAME& userName, unsigned int queueID, int binbodyLen,unsigned int desSeverID = 0, unsigned int desHandleID = 0)
	{
		CBinProtocol binpro(send_buff(), send_buff_len());
		if(binpro.packet_len() < binbodyLen)
		{
			LOG(LOG_ERROR, "bindbodyLen=%d too large", binbodyLen);
			return -1;
		}

		int sendLen = binpro.total_len(binbodyLen);
		binpro.head()->format(userName, cmd, sendLen);

		return send_to_queue(cmd, queueID, sendLen, desSeverID, desHandleID);
	}

	inline int send_protobuf_msg(int debug, Message& theProtoObj, unsigned int cmd, USER_NAME& userName, unsigned int queueID, unsigned int desSeverID = 0, unsigned int desHandleID = 0)
	{
		if(!theProtoObj.SerializeToArray(send_binbody_buff() , send_binbody_buff_len()))
		{
			LOG(LOG_ERROR, "%d, %d", send_binbody_buff_len(), theProtoObj.GetCachedSize());
			LOG(LOG_ERROR, "%s", theProtoObj.DebugString().c_str());
			LOG(LOG_ERROR, "SerializeToArray fail");
			return -1;
		}

		return send_bin_msg_to_queue(cmd, userName, queueID, theProtoObj.GetCachedSize(), desSeverID, desHandleID);
	}

	inline int send_bin_msg_to_queue(unsigned int cmd, USER_NAME& userName, CMsgQueue* pqueue, int binbodyLen,unsigned int desSeverID = 0, unsigned int desHandleID = 0)
	{
		CBinProtocol binpro(send_buff(), send_buff_len());
		if(binpro.packet_len() < binbodyLen)
		{
			LOG(LOG_ERROR, "bindbodyLen=%d too large", binbodyLen);
			return -1;
		}

		int sendLen = binpro.total_len(binbodyLen);
		binpro.head()->format(userName, cmd, sendLen);

		return send_to_queue(cmd, pqueue, sendLen, desSeverID, desHandleID);
	}

	inline int send_protobuf_msg(int debug, Message& theProtoObj, unsigned int cmd, USER_NAME& userName, CMsgQueue* pqueue, unsigned int desSeverID = 0, unsigned int desHandleID = 0)
	{
		if(!theProtoObj.SerializeToArray(send_binbody_buff() , send_binbody_buff_len()))
		{
			LOG(LOG_ERROR, "SerializeToArray fail");
			return -1;
		}
		return send_bin_msg_to_queue(cmd, userName, pqueue, theProtoObj.GetCachedSize(), desSeverID, desHandleID);
	}

	inline int send_protobuf_s_msg(int debug, string &proto_str, unsigned int cmd, USER_NAME& userName, CMsgQueue* pqueue, unsigned int desSeverID = 0, unsigned int desHandleID = 0)
	{
		if(proto_str.size() > (size_t)send_binbody_buff_len())
		{
			LOG(LOG_ERROR, "SerializeToArray fail");
			return -1;
		}
		memcpy(send_binbody_buff(), proto_str.data(), proto_str.size());

		if(debug)
		{
			LOG(LOG_DEBUG, "%s|send %x proto_str: %s, %lu", userName.str(), cmd, proto_str.c_str(), proto_str.size());
		}

		return send_bin_msg_to_queue(cmd, userName, pqueue, proto_str.size(), desSeverID, desHandleID);
	}

	inline int send_protobuf_s_msg(int debug, string &proto_str, unsigned int cmd, USER_NAME& userName, unsigned int queueID, unsigned int desSeverID = 0, unsigned int desHandleID = 0)
	{
		if(proto_str.size() > (size_t)send_binbody_buff_len())
		{
			LOG(LOG_ERROR, "SerializeToArray fail");
			return -1;
		}
		memcpy(send_binbody_buff(), proto_str.data(), proto_str.size());

		if(debug)
		{
			LOG(LOG_DEBUG, "%s|send %x proto_str: %s, %lu", userName.str(), cmd, proto_str.c_str(), proto_str.size());
		}

		return send_bin_msg_to_queue(cmd, userName, queueID, proto_str.size(), desSeverID, desHandleID);
	}

	inline void parse_config_string(vector<int>& container, const string& str)
	{
		strutil::Tokenizer thetoken(str, ",");
		while(thetoken.nextToken())
		{
			container.push_back(atoi(thetoken.getToken().c_str()));
		}
	}
	
public:
	static const unsigned int BUFFLEN = MSG_BUFF_LIMIT;
	char readBuff[BUFFLEN];
	char writeBuff[BUFFLEN];
	
protected:
	DRIVER_TIMER* m_ptimer;
	MSG_QUEUE_MAP *m_pqueuemap;
	unsigned int m_serverID;
	CLogicMsg m_msg;
	unsigned int m_processorID;
};

#endif
