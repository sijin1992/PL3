#ifndef __MAIN_LOGIC_DB_H__
#define __MAIN_LOGIC_DB_H__

#include "logic/driver.h"
#include "proto/logoutReq.pb.h"
#include "login_lock.h"

#include "proto/gm_cmd.pb.h"
#include "proto/UserInfo.pb.h"
#include "proto/AirShip.pb.h"
#include "proto/Item.pb.h"
#include "proto/Mail.pb.h"
#include "proto/inner_cmd.pb.h"


extern CDataCache gDataCache;
extern unsigned int MSG_QUEUE_ID_TO_MYSQL;
extern unsigned int MSG_QUEUE_ID_FROM_LOGIC;
extern int gMysqlTimeout;
extern int gDebug;
extern CLoginLock gLoginLock;
extern unsigned int MSG_QUEUE_ID_TO_TC;
extern lua_State * g_general_state;
class CLogicDB:public CLogicProcessor
{
protected:

public:
	CLogicDB()
	{
	}
	
	virtual void on_init()
	{
		m_timerID = 0;
		m_specialCmd = 0;
		m_dumpMsgBuff = NULL;
		m_theSet.get_clear_obj();
	}
	
	//有msg到达的时候激活对象
	virtual int on_active(CLogicMsg& msg)
	{
		//验证包是否完整
		unsigned int cmd = m_ptoolkit->get_cmd(msg);
		if(gDebug)
		{
			LOG(LOG_DEBUG, "active cmd=0x%x", cmd);
		}

		if(cmd == CMD_DBCACHE_GET_REQ)
		{
			return on_get_req(msg);
		}
		else if(cmd == CMD_DBCACHE_GET_RESP)
		{
			if(m_dumpMsgBuff == NULL)
			{
				//shit
				LOG(LOG_ERROR, "m_dumpMsgBuff=NULL");
				return RET_DONE;
			}
			CLogicMsg reqMsg(m_dumpMsgBuff, m_dumpMsgLen);
			if(m_specialCmd != 0)
			{
				int ret = do_inner_getok(msg, reqMsg);
				send_gm_resp(reqMsg, ret);

				return RET_DONE;
			}
			else
				return on_get_resp(reqMsg, msg);
		}
		else if(cmd == CMD_DBCACHE_TIMEOUT_RESP)
		{
			if(m_dumpMsgBuff == NULL)
			{
				//shit
				LOG(LOG_ERROR, "m_dumpMsgBuff=NULL");
				return RET_DONE;
			}
			CLogicMsg reqMsg(m_dumpMsgBuff, m_dumpMsgLen);

			//内部修改
			if(m_specialCmd != 0)
			{
				LOG(LOG_ERROR, "%s|specialCmd=%d|timeout", m_saveName.str(), m_specialCmd);
				do_inner_fail_resp(reqMsg);
				return RET_DONE;
			}
			
			//get 超时
			unsigned int flag = m_ptoolkit->get_timer_flag(msg);
			if(flag == CMD_DBCACHE_LOGIN_GET_REQ)
			{
				LOG(LOG_ERROR, "%s|LOGIN_GET|timeout", m_saveName.str());
				return on_logout_fail(reqMsg);
			}
			else if(flag == CMD_DBCACHE_CREATE_REQ)
			{
				LOG(LOG_ERROR, "%s|CREATE|timeout", m_saveName.str());
				return on_create_timeout(reqMsg);
			}
			else if(flag == CMD_CDKEY_INNER_REQ)
			{
				LOG(LOG_ERROR, "%s|check cdk|timeout", m_saveName.str());
				if(m_dumpMsgBuff == NULL)
				{
					LOG(LOG_ERROR, "m_dumpMsgBuff=NULL");
					return RET_DONE;
				}
				CLogicMsg reqMsg(m_dumpMsgBuff, m_dumpMsgLen);
				
				InnerCDKEYResp resp;
				resp.set_ret(-1);
				if(m_ptoolkit->send_protobuf_msg(gDebug, resp,
					CMD_CDKEY_INNER_RESP, m_saveName, 
					m_ptoolkit->get_queue_id(reqMsg), 
					m_ptoolkit->get_src_server(reqMsg), m_ptoolkit->get_src_handle(reqMsg)) != 0)
				{
					LOG(LOG_ERROR, "%s|send_to_queue(CMD_CDKEY_INNER_RESP, %u) fail", m_saveName.str(),m_ptoolkit->get_queue_id(msg));
				}
				return RET_DONE;
			}
			else if(flag == CMD_QUERY_BEFORE_REGIST_REQ)
			{
				LOG(LOG_ERROR, "%s|check active|timeout", m_saveName.str());
				if(m_dumpMsgBuff == NULL)
				{
					LOG(LOG_ERROR, "m_dumpMsgBuff=NULL");
					return RET_DONE;
				}
				CLogicMsg reqMsg(m_dumpMsgBuff, m_dumpMsgLen);
				
				InnerQueryBeforeReqResp resp;
				resp.set_result(-1);
				if(m_ptoolkit->send_protobuf_msg(gDebug, resp,
					CMD_QUERY_BEFORE_REGIST_RESP, m_saveName, 
					m_ptoolkit->get_queue_id(reqMsg), 
					m_ptoolkit->get_src_server(reqMsg), m_ptoolkit->get_src_handle(reqMsg)) != 0)
				{
					LOG(LOG_ERROR, "%s|send_to_queue(CMD_QUERY_BEFORE_REGIST_RESP, %u) fail", m_saveName.str(),m_ptoolkit->get_queue_id(msg));
				}
				return RET_DONE;
			}
			else
			{
				//等待get
				LOG(LOG_ERROR, "%s|GET|timeout", m_saveName.str());
				return on_get_timeout(reqMsg);
			}
		}
		else if(cmd == CMD_DBCACHE_SET_REQ)
		{
			return on_set_req(msg);
		}
		else if(cmd == CMD_DBCACHE_LOGIN_GET_REQ)
		{
			return on_login(msg);
		}
		else if(cmd == CMD_DBCACHE_LOGOUT_REQ)
		{
			return on_logout(msg);
		}
		else if(cmd == CMD_DBCACHE_LOGOUT_RESP)
		{
			//这个是前端被动logout的回包
			//恢复下请求
			//这个REQ是在用户替换登录时发出的
			if(m_dumpMsgBuff == NULL)
			{
				//shit
				LOG(LOG_ERROR, "m_dumpMsgBuff=NULL");
				return RET_DONE;
			}
			CLogicMsg reqMsg(m_dumpMsgBuff, m_dumpMsgLen);

			return on_logout_resp(reqMsg, msg);
		}
		else if(cmd == CMD_DBCACHE_CREATE_REQ)
		{
			//新建记录由db insert保证
			return on_create_req(msg);
		}
		else if(cmd == CMD_DBCACHE_CREATE_RESP)
		{
			if(m_dumpMsgBuff == NULL)
			{
				//shit
				LOG(LOG_ERROR, "m_dumpMsgBuff=NULL");
				return RET_DONE;
			}
			CLogicMsg reqMsg(m_dumpMsgBuff, m_dumpMsgLen);
			return on_create_resp(reqMsg, msg);
		}
		//在db完成修改的流程
		else if(cmd == CMD_DBCACHE_SEND_MAIL_REQ)
		{
			//需要特殊处理的逻辑
			m_specialCmd = cmd;
			int ret = -1;
			if(m_specialCmd == CMD_DBCACHE_SEND_MAIL_REQ)
			{
			 	ret = do_inner_get(msg, DATA_BLOCK_FLAG_MAIN|DATA_BLOCK_FLAG_MAIL);
			}
				
			if(ret == 1)
			{
				return RET_YIELD;
			}
			else
			{
				send_gm_resp(msg, ret);
				return RET_DONE;
			}
		}
		else if(cmd == CMD_CDKEY_INNER_REQ)
		{
			USER_NAME user;
			InnerCDKEYReq req;
			if(m_ptoolkit->parse_protobuf_msg(gDebug, msg, user, req)!=0)
			{
				LOG(LOG_ERROR, "parse_protobuf_msg err");
				return RET_DONE;
			}

			m_saveName = user;
			if(m_ptoolkit->set_timer_s(m_timerID, gMysqlTimeout, m_id, CMD_DBCACHE_TIMEOUT_RESP, CMD_CDKEY_INNER_REQ)!=0)
			{
				LOG(LOG_ERROR, "%s|CMD_CDKEY_INNER_REQ set_timer fail", user.str());
				InnerCDKEYResp resp;
				resp.set_ret(-1);
				if(m_ptoolkit->send_protobuf_msg(gDebug, resp,
					CMD_CDKEY_INNER_RESP, user, 
					m_ptoolkit->get_queue_id(msg), 
					m_ptoolkit->get_src_server(msg), m_ptoolkit->get_src_handle(msg)) != 0)
				{
					LOG(LOG_ERROR, "%s|send_to_queue(CMD_CDKEY_INNER_RESP, %u) fail", user.str(),m_ptoolkit->get_queue_id(msg));
				}
				return RET_DONE;
			}
			else
			{
				//保存原始msg，返回时从中获取消息源信息
				dump_req_msg(msg);
				if(m_ptoolkit->send_protobuf_msg(gDebug, req,
					CMD_CDKEY_INNER_REQ, user, 
					MSG_QUEUE_ID_TO_MYSQL) != 0)
				{
					LOG(LOG_ERROR, "%s|send_to_queue(CMD_CDKEY_INNER_REQ, MSG_QUEUE_ID_TO_MYSQL) fail", user.str());
						m_ptoolkit->del_timer(m_timerID);
					InnerCDKEYResp resp;
					resp.set_ret(-1);
					if(m_ptoolkit->send_protobuf_msg(gDebug, resp,
						CMD_CDKEY_INNER_RESP, user, 
						m_ptoolkit->get_queue_id(msg), 
						m_ptoolkit->get_src_server(msg), m_ptoolkit->get_src_handle(msg)) != 0)
					{
						LOG(LOG_ERROR, "%s|send_to_queue(CMD_CDKEY_INNER_RESP, %u) fail", user.str(),m_ptoolkit->get_queue_id(msg));
					}
					m_ptoolkit->del_timer(m_timerID);
					m_timerID = 0;
					return RET_DONE;
				}
				return RET_YIELD;
			}
		}
		else if(cmd == CMD_CDKEY_INNER_RESP)
		{
			m_ptoolkit->del_timer(m_timerID);
			m_timerID = 0;
			if(m_dumpMsgBuff == NULL)
			{
				LOG(LOG_ERROR, "m_dumpMsgBuff=NULL");
				return RET_DONE;
			}
			CLogicMsg reqMsg(m_dumpMsgBuff, m_dumpMsgLen);
			USER_NAME user;
			InnerCDKEYResp resp;
			if(m_ptoolkit->parse_protobuf_msg(gDebug, msg, user, resp)!=0)
			{
				LOG(LOG_ERROR, "%s|parse_protobuf_msg(CMD_CDKEY_INNER_RESP) fail",
					user.str());
				return RET_DONE;
			}
			if(m_ptoolkit->send_protobuf_msg(gDebug, resp,
				CMD_CDKEY_INNER_RESP, user, 
				m_ptoolkit->get_queue_id(reqMsg), 
				m_ptoolkit->get_src_server(reqMsg), m_ptoolkit->get_src_handle(reqMsg)) != 0)
			{
				LOG(LOG_ERROR, "%s|send_to_queue(CMD_CDKEY_INNER_RESP, %u) fail", user.str(),m_ptoolkit->get_queue_id(reqMsg));
			}
			return RET_DONE;
		}
		else if(cmd == CMD_QUERY_BEFORE_REGIST_REQ)
		{
			USER_NAME user;
			InnerQueryBeforeRegReq req;
			if(m_ptoolkit->parse_protobuf_msg(gDebug, msg, user, req)!=0)
			{
				LOG(LOG_ERROR, "parse_protobuf_msg err");
				return RET_DONE;
			}

			m_saveName = user;
			if(m_ptoolkit->set_timer_s(m_timerID, gMysqlTimeout, m_id, CMD_DBCACHE_TIMEOUT_RESP, CMD_QUERY_BEFORE_REGIST_REQ)!=0)
			{
				LOG(LOG_ERROR, "%s|CMD_QUERY_BEFORE_REGIST_REQ set_timer fail", user.str());
				InnerQueryBeforeReqResp resp;
				resp.set_result(-1);
				if(m_ptoolkit->send_protobuf_msg(gDebug, resp,
					CMD_QUERY_BEFORE_REGIST_RESP, user, 
					m_ptoolkit->get_queue_id(msg), 
					m_ptoolkit->get_src_server(msg), m_ptoolkit->get_src_handle(msg)) != 0)
				{
					LOG(LOG_ERROR, "%s|send_to_queue(CMD_QUERY_BEFORE_REGIST_RESP, %u) fail", user.str(),m_ptoolkit->get_queue_id(msg));
				}
				return RET_DONE;
			}
			else
			{
				//保存原始msg，返回时从中获取消息源信息
				dump_req_msg(msg);
				if(m_ptoolkit->send_protobuf_msg(gDebug, req,
					CMD_QUERY_BEFORE_REGIST_REQ, user, 
					MSG_QUEUE_ID_TO_MYSQL) != 0)
				{
					LOG(LOG_ERROR, "%s|send_to_queue(CMD_QUERY_BEFORE_REGIST_REQ, MSG_QUEUE_ID_TO_MYSQL) fail", user.str());
						m_ptoolkit->del_timer(m_timerID);
					InnerQueryBeforeReqResp resp;
					resp.set_result(-1);
					if(m_ptoolkit->send_protobuf_msg(gDebug, resp,
						CMD_QUERY_BEFORE_REGIST_RESP, user, 
						m_ptoolkit->get_queue_id(msg), 
						m_ptoolkit->get_src_server(msg), m_ptoolkit->get_src_handle(msg)) != 0)
					{
						LOG(LOG_ERROR, "%s|send_to_queue(CMD_QUERY_BEFORE_REGIST_RESP, %u) fail", user.str(),m_ptoolkit->get_queue_id(msg));
					}
					m_ptoolkit->del_timer(m_timerID);
					m_timerID = 0;
					return RET_DONE;
				}
				return RET_YIELD;
			}
		}
		else if(cmd == CMD_QUERY_BEFORE_REGIST_RESP)
		{
			m_ptoolkit->del_timer(m_timerID);
			m_timerID = 0;
			if(m_dumpMsgBuff == NULL)
			{
				LOG(LOG_ERROR, "m_dumpMsgBuff=NULL");
				return RET_DONE;
			}
			CLogicMsg reqMsg(m_dumpMsgBuff, m_dumpMsgLen);
			USER_NAME user;
			InnerQueryBeforeReqResp resp;
			if(m_ptoolkit->parse_protobuf_msg(gDebug, msg, user, resp)!=0)
			{
				LOG(LOG_ERROR, "%s|parse_protobuf_msg(CMD_QUERY_BEFORE_REGIST_RESP) fail",
					user.str());
				return RET_DONE;
			}
			if(m_ptoolkit->send_protobuf_msg(gDebug, resp,
				CMD_QUERY_BEFORE_REGIST_RESP, user, 
				m_ptoolkit->get_queue_id(reqMsg), 
				m_ptoolkit->get_src_server(reqMsg), m_ptoolkit->get_src_handle(reqMsg)) != 0)
			{
				LOG(LOG_ERROR, "%s|send_to_queue(CMD_QUERY_BEFORE_REGIST_RESP, %u) fail", user.str(),m_ptoolkit->get_queue_id(reqMsg));
			}
			return RET_DONE;
		}
		
		else
			LOG(LOG_ERROR, "unexpect cmd=0x%x" , m_ptoolkit->get_cmd(msg));

		return RET_DONE;
	}
	
	//对象销毁前调用一次
	virtual void on_finish()
	{
		if(m_dumpMsgBuff != NULL)
		{
			delete[] m_dumpMsgBuff;
			m_dumpMsgBuff = NULL;
		}
	}
	
	virtual CLogicProcessor* create()
	{
		return new CLogicDB;
	}

protected:

	inline void dump_req_msg(CLogicMsg& msg)
	{
		char* delmem = m_dumpMsgBuff;
		m_dumpMsgLen = msg.dump(m_dumpMsgBuff);
		if(delmem)
		{
			delete[] delmem;
		}
	}

	int send_logout(USER_NAME& user, unsigned int lastSvrID)
	{
		//发送
		LogoutReq theReq; 
		theReq.set_nothing(2);

		if(!theReq.SerializeToArray(m_ptoolkit->send_binbody_buff(), m_ptoolkit->send_binbody_buff_len()))
		{
			LOG(LOG_ERROR, "LogoutReq.SerializeToArray fail");
			return RET_DONE;
		}
		
		m_saveName = user;
		int ret = m_ptoolkit->set_timer_s(m_timerID, 1,
			m_id, CMD_DBCACHE_TIMEOUT_RESP, CMD_DBCACHE_LOGIN_GET_REQ);
		if(ret < 0)
		{
			return RET_DONE;
		}

		//queue只有一个
		if(m_ptoolkit->send_bin_msg_to_queue(CMD_LOGOUT_REQ, user, MSG_QUEUE_ID_FROM_LOGIC, theReq.GetCachedSize(),
			lastSvrID) != 0)
		{
			LOG(LOG_ERROR, "send_bin_msg_to_queue(CMD_LOGOUT_RESP, MSG_QUEUE_ID_FROM_LOGIC) fail");
			m_ptoolkit->del_timer(m_timerID);
			return RET_DONE;
		}
	
		return RET_YIELD;
	}

    // TODO: booljin 后续修改具体逻辑
	inline void do_inner_fail_resp(CLogicMsg& msg)
	{
//		if(m_specialCmd == CMD_DBCACHE_FEEDS_GET_REQ)
//		{
//			CBinProtocol bin;
//			if(m_ptoolkit->parse_bin_msg(msg,bin)!=0)
//			{
//				LOG(LOG_ERROR, "do_inner_fail_resp parse msg fail");
//			}

//			FeedsGetResp getfeedsresp;
//			getfeedsresp.set_result(getfeedsresp.FAIL);
//			USER_NAME user = bin.head()->parse_name();
//			int ret = m_ptoolkit->send_protobuf_msg(gDebug,getfeedsresp,CMD_DBCACHE_FEEDS_GET_RESP,
//					user, MSG_QUEUE_ID_FROM_LOGIC, 
//					m_ptoolkit->get_src_server(msg),m_ptoolkit->get_src_handle(msg));
//			if(ret !=0)
//			{
//				LOG(LOG_ERROR, "send_protobuf_msg CMD_DBCACHE_FEEDS_GET_RESP fail");
//			}
//		}
	}

	inline void send_gm_resp(CLogicMsg &msg, int ret)
	{
		DBGMResp resp;
		resp.set_result(ret);
		CBinProtocol bin;
		if(m_ptoolkit->parse_bin_msg(msg,bin)!=0)
		{
			LOG(LOG_ERROR, "send_gm_resp parse msg fail");
		}

		USER_NAME user = bin.head()->parse_name();
		if(m_ptoolkit->send_protobuf_msg(gDebug,resp,CMD_DBCACHE_GM_RESP,
				user, MSG_QUEUE_ID_FROM_LOGIC, 
				m_ptoolkit->get_src_server(msg),m_ptoolkit->get_src_handle(msg)) != 0)
		{
			LOG(LOG_ERROR, "send_protobuf_msg CMD_DBCACHE_GM_RESP fail");
		}
	
	}

	//0=ok, -1=fail, 1=wait
	inline int do_inner_get(CLogicMsg& msg, int flags)
	{
		m_special_flag = flags;
		CBinProtocol binpro;
		if(m_ptoolkit->parse_bin_msg(msg, binpro) !=0)
		{
			return -1;
		}
		USER_NAME user = binpro.head()->parse_name();

		int ret = m_dbcache.init(&gDataCache);
		if(ret != m_dbcache.OK)
			return RET_DONE;

		//组get请求
		m_theSet.get_clear_obj();
		for(int i=0; i<DATA_BLOCK_ARRAY_MAX; ++i)
		{
			if(flags & (1<<i))
			{
				m_theSet.add_lock_get_and_set_req(i);
			}
		}

		//看本地是否有
		CDataBlockSet theMissSet;
		ret = m_dbcache.get(user, m_theSet, theMissSet);
		if(ret == m_dbcache.WOULD_BLOCK)
		{
			//把missSet送给mysql_helper查询
			//定时
			m_saveName = user;
			if(m_ptoolkit->set_timer_s(m_timerID, gMysqlTimeout, m_id, CMD_DBCACHE_TIMEOUT_RESP, 
				m_specialCmd)!=0)
			{
				return -1;
			}
			
			//保存
			dump_req_msg(msg);
			if(m_ptoolkit->send_protobuf_msg(gDebug, theMissSet.get_obj(),
				CMD_DBCACHE_GET_REQ, user, 
				MSG_QUEUE_ID_TO_MYSQL) != 0)
			{
				LOG(LOG_ERROR, "send_to_queue(CMD_DBCACHE_GET_REQ, MSG_QUEUE_ID_TO_MYSQL) fail");
				m_ptoolkit->del_timer(m_timerID);
				return -1;
			}
			
			return 1;
		}
		else if(ret == m_dbcache.OK)
		{
			//直接set
			return do_inner_set(binpro, msg);
		}
		else
		{
			return -1;
		}
	}

	inline int do_inner_getok(CLogicMsg& msg, CLogicMsg& reqMsg)
	{
		m_ptoolkit->del_timer(m_timerID);
		m_timerID = 0;
		int ret = 0;

		USER_NAME user;
		CDataBlockSet theMissResp;
		if(m_ptoolkit->parse_protobuf_msg(gDebug, msg, user, theMissResp.get_obj())!=0)
			return -1;

		ret = m_dbcache.init(&gDataCache);
		if(ret != m_dbcache.OK)
			return -1;

		int result = theMissResp.result();
		if(result == DataBlockSet::OK)
		{
			ret = m_dbcache.on_get(user, theMissResp);
			if(ret != m_dbcache.OK)
			{
				return -1;
			}
			
			ret = m_dbcache.merge(m_theSet, theMissResp);
			if(ret != m_dbcache.OK)
				return -1;
		}
		else if(result == DataBlockSet::NO_DATA)
		{
	
			LOG(LOG_ERROR, "%s|no data", user.str());
			return -2;
		}
		else
		{
			return -1;
		}

		
		CBinProtocol binpro;
		if(m_ptoolkit->parse_bin_msg( reqMsg, binpro)!=0)
			return -1;
		return do_inner_set(binpro, reqMsg);
	}

	inline int get_block_buf(int flag, USER_NAME & user, string &buf)
	{
		DataBlock* pBlock = NULL;
		for(int i = 0; i<DATA_BLOCK_ARRAY_MAX; ++i)
		{
			if(flag & (1<<i))
			{
				if(m_theSet.get_block(i, pBlock)!=0)
					return -1;
				break;
			}
		}

		if(pBlock == NULL)
		{
			LOG(LOG_ERROR, "%s|do_inner_set should have block %d", user.str(), flag);
			return -1;
		}
		
		if(pBlock->has_buff() && pBlock->buff().length() != 0)
		{
			buf.assign(pBlock->buff());
		}
		else if(flag != DATA_BLOCK_FLAG_MAIN && pBlock->buff().length() == 0)
		{
			pBlock->mutable_buff()->assign("");
			buf.assign("");
		}
		else
		{
			LOG(LOG_ERROR, "%s|block buf err(flag = %d)", user.str(), flag);
			return -1;
		}
		return 0;
	}

	#define GET_DATA(stack_id, TYPE, FLAG) \
	{\
		TYPE pb;\
		if(lua_isstring(l, stack_id))\
		{\
			size_t ll = 0;\
			const char *s;\
			s = lua_tolstring(l, stack_id, &ll);\
			if(!pb.ParseFromArray(s, ll))\
			{\
				LOG(LOG_ERROR, "%s|parse data err(stack id = %d)", user.str(), -(stack_id));\
				some_err = true;\
			}\
		}\
		else\
		{\
			LOG(LOG_ERROR, "%s|lua return data err(stack id = %d)", user.str(), -(stack_id));\
			some_err = true;\
		}\
		for(int i = 0; i<DATA_BLOCK_ARRAY_MAX; ++i)\
		{\
			if(FLAG & (1<<i))\
			{\
				DataBlock* pBlock = NULL;\
				if(m_theSet.get_block(i, pBlock)!=0)\
					some_err = true;\
				if(!pb.SerializeToString(pBlock->mutable_buff()))\
				{\
					LOG(LOG_ERROR, "%s|SerializeToString fail", user.str());\
					some_err = true;\
				}\
				break;\
			}\
		}\
	}
		

	inline int do_inner_set(CBinProtocol& binpro, CLogicMsg& msg)
	{

		USER_NAME user = binpro.head()->parse_name();
		const char *name = user.str();
		lua_State *l = g_general_state;
		if(lua_gettop(l) != 0)
		{
			LOG(LOG_ERROR, "lua err: stack top is %u", lua_gettop(l));
			return -1;
		}
		if(m_specialCmd == CMD_DBCACHE_SEND_MAIL_REQ)
		{
			string req;
			req.assign(binpro.packet(), binpro.packet_len());
			string ui;
			string ml;
			if(get_block_buf(DATA_BLOCK_FLAG_MAIN, user, ui) != 0
				|| get_block_buf(DATA_BLOCK_FLAG_MAIL, user, ml) != 0)
			{
				LOG(LOG_ERROR, "get block buf err:%s", user.str());
				return -1;
			}
			lua_getglobal(l, "do_send_mail");
			lua_pushlstring(l, name, strlen(name));
			lua_pushlstring(l, req.c_str(), req.size());
			lua_pushlstring(l, ui.c_str(), ui.size());
			lua_pushlstring(l, ml.c_str(), ml.size());
			if(lua_pcall(l, 4, 2, 0) != 0)//LUA_OK)
			{
				LOG(LOG_ERROR, "%s|SEND MAIL, lua error %s",user.str(), lua_tostring(l, -1));
				lua_pop(l, 1);
				return -1;
			}
			bool some_err = false;
			GET_DATA(-2, UserInfo, DATA_BLOCK_FLAG_MAIN);
			GET_DATA(-1, MailList, DATA_BLOCK_FLAG_MAIL);
			lua_pop(l, 2);
			if(some_err)
				return -1;
		}
		else
			return -1;
		if(m_dbcache.set(user, m_theSet) != m_dbcache.OK)
			return -1;
		return 0;
	}

	int on_login(CLogicMsg& msg)
	{
		CBinProtocol probin;
		if(m_ptoolkit->parse_bin_msg(msg, probin) != 0)
		{
			return RET_DONE;
		}
		USER_NAME user = probin.head()->parse_name();
		
		//先搞login
		unsigned int lastSvrID = 0;
		int ret = gLoginLock.on_login(user, m_ptoolkit->get_src_server(msg), lastSvrID);
		if(ret == gLoginLock.RET_OK)
		{
			LOG(LOG_INFO, "%s|on_login no server change", user.str());
			return on_get_req(msg);
		}
		else if(ret == gLoginLock.RET_LOGOUT)
		{
			//发送一条logout协议
			dump_req_msg(msg);
			LOG(LOG_INFO, "%s|on_login send_logout to %d", user.str(), lastSvrID);
			return send_logout(user, lastSvrID);
		}
		else
		{
			//错误了不做回应
		}
		
		return RET_DONE;
	}

	int on_logout(CLogicMsg& msg)
	{
		CBinProtocol probin;
		if(m_ptoolkit->parse_bin_msg(msg, probin) != 0)
		{
			return RET_DONE;
		}
		USER_NAME user = probin.head()->parse_name();
		//前端主动logout
		//错误会记下日志
		int ret = gLoginLock.on_logout(user, m_ptoolkit->get_src_server(msg));
		LOG(LOG_INFO, "%s|on_logout=%d", user.str(), ret);
		//logout不操作数据，不回包

		//do_fangchenmi(user);
		
		return RET_DONE;
	}


	//login get -> other logout->fail
	//制作一个失败包
	int on_logout_fail(CLogicMsg& theReqMsg)
	{
		USER_NAME user;
		if(m_ptoolkit->parse_protobuf_msg(gDebug, theReqMsg, user, m_theSet.get_obj()) != 0)
		{
			return RET_DONE;
		}

		m_theSet.save_only_result(true);

		LOG(LOG_INFO, "%s|on_logout_fail", user.str());
		if(m_ptoolkit->send_protobuf_msg(gDebug, m_theSet.get_obj(),
			CMD_DBCACHE_GET_RESP, user,
			m_ptoolkit->get_queue_id(theReqMsg), 
			m_ptoolkit->get_src_server(theReqMsg), m_ptoolkit->get_src_handle(theReqMsg)) != 0)
		{
			LOG(LOG_ERROR, "send_to_queue(%u) fail", m_ptoolkit->get_queue_id(theReqMsg));
		}

		return RET_DONE;
	}

	int on_logout_resp(CLogicMsg& reqMsg, CLogicMsg& msg)
	{
		//删除定时器
		m_ptoolkit->del_timer(m_timerID);
		m_timerID = 0;
		CBinProtocol probin;
		if(m_ptoolkit->parse_bin_msg(msg, probin) != 0)
		{
			return RET_DONE;
		}
		USER_NAME user = probin.head()->parse_name();

		//do_fangchenmi(user);

		LOG(LOG_INFO, "%s|on_logout_resp", user.str());
		
		//尝试解锁
		if(gLoginLock.on_replace(user, m_ptoolkit->get_src_server(reqMsg), m_ptoolkit->get_src_server(msg)) != gLoginLock.RET_OK)
		{
			//失败回个错误包
			return on_logout_fail(reqMsg);
		}

		//开始处理login的请求
		return on_get_req(reqMsg);
	}
	
	int on_get_req(CLogicMsg& msg)
	{
		USER_NAME user;
		if(m_ptoolkit->parse_protobuf_msg(gDebug, msg, user, m_theSet.get_obj())!=0)
		{
			return RET_DONE;
		}

		int ret = m_dbcache.init(&gDataCache);
		if(ret != m_dbcache.OK)
		{
			LOG(LOG_ERROR, "%s|m_dbcache init fail", user.str());
			return RET_DONE;
		}

		CDataBlockSet theMissSet;
		ret = m_dbcache.get(user, m_theSet, theMissSet);
		if(ret == m_dbcache.WOULD_BLOCK)
		{
			//把missSet送给mysql_helper查询
			//定时
			m_saveName = user;
			if(m_ptoolkit->set_timer_s(m_timerID, gMysqlTimeout, m_id, CMD_DBCACHE_TIMEOUT_RESP)!=0)
			{
				LOG(LOG_ERROR, "%s|on_get set_timer fail", user.str());
				m_theSet.save_only_result(true);
			}
			else
			{
				//保存原始msg，返回时从中获取消息源信息
				dump_req_msg(msg);
				if(m_ptoolkit->send_protobuf_msg(gDebug, theMissSet.get_obj(),
					CMD_DBCACHE_GET_REQ, user, 
					MSG_QUEUE_ID_TO_MYSQL) != 0)
				{
					LOG(LOG_ERROR, "%s|send_to_queue(CMD_DBCACHE_GET_REQ, MSG_QUEUE_ID_TO_MYSQL) fail", user.str());
					m_ptoolkit->del_timer(m_timerID);
					return RET_DONE;
				}
				
				return RET_YIELD;
			}
		}
		else if(ret == m_dbcache.OK)
		{
		}
		else
		{
			LOG(LOG_ERROR, "%s|on_get cacheget fail", user.str());
			m_theSet.save_only_result(true);
		}

		//回包
		if(m_ptoolkit->send_protobuf_msg(gDebug, m_theSet.get_obj(),
			CMD_DBCACHE_GET_RESP, user, 
			m_ptoolkit->get_queue_id(msg), 
			m_ptoolkit->get_src_server(msg), m_ptoolkit->get_src_handle(msg)) != 0)
		{
			LOG(LOG_ERROR, "%s|send_to_queue(CMD_DBCACHE_GET_RESP, %u) fail",  user.str(), m_ptoolkit->get_queue_id(msg));
		}

		//LOG(LOG_INFO, "%s|GET|CACHE|result=%d", user.str(), m_theSet.get_obj().result());

		return RET_DONE;
	}

	int on_get_resp(CLogicMsg& reqMsg, CLogicMsg& msg)
	{
		m_ptoolkit->del_timer(m_timerID);
		m_timerID = 0;
		int ret = 0;

		USER_NAME user;
		CDataBlockSet theMissResp;
		if(m_ptoolkit->parse_protobuf_msg(gDebug, msg, user, theMissResp.get_obj())!=0)
			return RET_DONE;

		CBinProtocol probinReq;
		if(m_ptoolkit->parse_bin_msg(reqMsg, probinReq) != 0)
		{
			return RET_DONE;
		}
		USER_NAME userReq = probinReq.head()->parse_name();

		ret = m_dbcache.init(&gDataCache);
		if(ret != m_dbcache.OK)
		{
			LOG(LOG_ERROR, "%s|m_dbcache init fail", user.str());
			return RET_DONE;
		}

		if(userReq != user)
		{
			//不能吧
			LOG(LOG_ERROR, "%s|m_user(%s)  != user", user.str(), userReq.str());
			m_theSet.save_only_result(true);
		}
		else
		{
			int result = theMissResp.result();
			if(result == DataBlockSet::OK)
			{
				ret = m_dbcache.on_get(user, theMissResp);
				if(ret != m_dbcache.OK)
				{
					LOG(LOG_ERROR, "%s|m_dbcache onget fail", user.str());
					m_theSet.save_only_result(true);
				}
				else
				{
					if(m_theSet.result() == DataBlockSet::MISS)
					{
						//直接用miss回包
						if(m_ptoolkit->send_protobuf_msg(gDebug, theMissResp.get_obj(),
							CMD_DBCACHE_GET_RESP, user, 
							m_ptoolkit->get_queue_id(reqMsg), 
							m_ptoolkit->get_src_server(reqMsg), m_ptoolkit->get_src_handle(reqMsg)) != 0)
						{
							LOG(LOG_ERROR, "%s|send_to_queue(CMD_DBCACHE_GET_RESP, %u) fail", user.str(),m_ptoolkit->get_queue_id(reqMsg));
						}
						
						//LOG(LOG_INFO, "%s|GET|DB|result=%d", user.str(), DataBlockSet::MISS);
						
						return RET_DONE;
					}
					else 	//merge将传递result
					{
						ret = m_dbcache.merge(m_theSet, theMissResp);
						if(ret != m_dbcache.OK)
						{
							LOG(LOG_ERROR, "%s|m_dbcache merge fail", user.str());
							m_theSet.save_only_result(true);
						}
					}
				}
			}
			else if(result == DataBlockSet::NO_DATA)
			{
				m_theSet.set_result( DataBlockSet::NO_DATA);
				m_theSet.save_only_result();
			}
			else
			{
				LOG(LOG_ERROR, "%s|unexpect result %d", user.str(), result);
				m_theSet.save_only_result(true);
			}
		}
		
		//回包
		if(m_ptoolkit->send_protobuf_msg(gDebug, m_theSet.get_obj(),
			CMD_DBCACHE_GET_RESP, user, 
			m_ptoolkit->get_queue_id(reqMsg), 
			m_ptoolkit->get_src_server(reqMsg), m_ptoolkit->get_src_handle(reqMsg)) != 0)
		{
			LOG(LOG_ERROR, "%s|send_to_queue(CMD_DBCACHE_GET_RESP, %u) fail", user.str(), m_ptoolkit->get_queue_id(reqMsg));
		}

		//LOG(LOG_INFO, "%s|GET|DB|result=%d", user.str(), m_theSet.get_obj().result());

		return RET_DONE;
	}

	int on_get_timeout(CLogicMsg& msg)
	{
		CBinProtocol binpro;
		if(m_ptoolkit->parse_bin_msg(msg, binpro)!=0)
			return RET_DONE;

		USER_NAME user = binpro.head()->parse_name();
		m_theSet.save_only_result(true);
		
		if(m_ptoolkit->send_bin_msg_to_queue(CMD_DBCACHE_GET_RESP, user, 
			m_ptoolkit->get_queue_id(msg), 0,
			m_ptoolkit->get_src_server(msg), m_ptoolkit->get_src_handle(msg)) != 0)
		{
			LOG(LOG_ERROR, "%s|send_to_queue(CMD_DBCACHE_GET_RESP, %u) fail", user.str(), m_ptoolkit->get_queue_id(msg));
		}

		
		return RET_DONE;
	}

	int on_set_req(CLogicMsg& msg)
	{
		int ret = 0;
		USER_NAME user; 
		if(m_ptoolkit->parse_protobuf_msg(gDebug, msg, user, m_theSet.get_obj())!=0)
			return RET_DONE;

		ret = m_dbcache.init(&gDataCache);
		if(ret != m_dbcache.OK)
		{
			LOG(LOG_ERROR, "%s|m_dbcache init fail", user.str());
			return RET_DONE;
		}

		ret = m_dbcache.set(user, m_theSet);
		if(ret != m_dbcache.OK)
		{
			LOG(LOG_ERROR, "%s|m_dbcache set fail", user.str());
			return RET_DONE;
		}

		//不要返回值的就不管了
		if(m_theSet.get_obj().has_noresp() && m_theSet.get_obj().noresp() != 0)
		{
			//LOG(LOG_INFO, "%s|SET|CACHE|result=%d|noresp", user.str(), m_theSet.get_obj().result());
			return RET_DONE;
		}
		
		//stamp需要回传
		m_theSet.save_without_blockbuff();

		if(m_ptoolkit->send_protobuf_msg(gDebug, m_theSet.get_obj(),	
			CMD_DBCACHE_SET_RESP, user, 
			m_ptoolkit->get_queue_id(msg), 
			m_ptoolkit->get_src_server(msg), m_ptoolkit->get_src_handle(msg)) != 0)
		{
			LOG(LOG_ERROR, "%s|send_to_queue(CMD_DBCACHE_SET_RESP, %u) fail", user.str(), m_ptoolkit->get_queue_id(msg));
		}
		
		//LOG(LOG_INFO, "%s|SET|CACHE|result=%d", user.str(), m_theSet.get_obj().result());
		return RET_DONE;
	}

	
	int on_create_req(CLogicMsg& msg)
	{
		CBinProtocol binpro;
		if(m_ptoolkit->parse_bin_msg(msg, binpro)!=0)
			return RET_DONE;
		USER_NAME user = binpro.head()->parse_name();

		//保存下
		dump_req_msg(msg);

		//flag=2
		m_saveName = user;
		if(m_ptoolkit->set_timer_s(m_timerID, gMysqlTimeout, m_id, CMD_DBCACHE_TIMEOUT_RESP, CMD_DBCACHE_CREATE_REQ)!=0)
		{
			LOG(LOG_ERROR, "%s|on_create set_timer fail", user.str());
			m_theSet.save_only_result(true);
		}
		else
		{
			//透传给db
			memcpy(m_ptoolkit->send_buff(), binpro.buff(), binpro.buff_len());
		
			if(m_ptoolkit->send_to_queue(CMD_DBCACHE_CREATE_REQ,  
				MSG_QUEUE_ID_TO_MYSQL, binpro.buff_len()) != 0)
			{
				LOG(LOG_ERROR, "%s|send_to_queue(CMD_DBCACHE_CREATE_REQ, MSG_QUEUE_ID_TO_MYSQL) fail", user.str());
			}
			return RET_YIELD;
		}

		if(m_ptoolkit->send_protobuf_msg(gDebug, m_theSet.get_obj(),
			CMD_DBCACHE_CREATE_RESP, user, 
			m_ptoolkit->get_queue_id(msg),
			m_ptoolkit->get_src_server(msg), m_ptoolkit->get_src_handle(msg)) != 0)
		{
			LOG(LOG_ERROR, "%s|send_to_queue(CMD_DBCACHE_CREATE_RESP, %u) fail", user.str(), m_ptoolkit->get_queue_id(msg));
		}
		//LOG(LOG_INFO, "%s|CREATE|result=%d", user.str(), m_theSet.get_obj().result());
		return RET_DONE;
	}

	int on_create_timeout(CLogicMsg& msg)
	{
		CBinProtocol binpro;
		if(m_ptoolkit->parse_bin_msg(msg, binpro)!=0)
			return RET_DONE;

		USER_NAME user = binpro.head()->parse_name();
		m_theSet.save_only_result(true);
		
		if(m_ptoolkit->send_protobuf_msg(gDebug, m_theSet.get_obj(),
			CMD_DBCACHE_CREATE_RESP, user, 
			m_ptoolkit->get_queue_id(msg),
			m_ptoolkit->get_src_server(msg), m_ptoolkit->get_src_handle(msg)) != 0)
		{
			LOG(LOG_ERROR, "%s|send_to_queue(CMD_DBCACHE_CREATE_RESP, %u) fail", user.str(), m_ptoolkit->get_queue_id(msg));
		}

		//LOG(LOG_INFO, "%s|CREATE|timeout", user.str());
		
		return RET_DONE;
	}

	int on_create_resp(CLogicMsg& reqMsg, CLogicMsg& msg)
	{
		m_ptoolkit->del_timer(m_timerID);
		m_timerID = 0;
		int ret = 0;
		
		CDataBlockSet mysqlset;
		USER_NAME user;
		if(m_ptoolkit->parse_protobuf_msg(gDebug, msg, user,mysqlset.get_obj()) != 0)
		{
			return RET_DONE;
		}

		USER_NAME userReq;
		if(m_ptoolkit->parse_protobuf_msg(gDebug, reqMsg, userReq,m_theSet.get_obj()) != 0)
		{
			return RET_DONE;
		}

		ret = m_dbcache.init(&gDataCache);
		if(ret != m_dbcache.OK)
			return RET_DONE;

		if(userReq != user)
		{
			//不能吧
			LOG(LOG_ERROR, "%s|m_user(%s) != user", user.str(), userReq.str());
			m_theSet.save_only_result(true);
		}
		else if(mysqlset.result() != DataBlockSet::OK)
		{
			//insert出错
			LOG(LOG_ERROR, "%s|create_resp mysql fail", user.str());
			m_theSet.save_only_result(true);
		}
		else
		{
			//可以更新buff
			ret = m_dbcache.on_get(user, m_theSet);
			if(ret != m_dbcache.OK)
			{
				LOG(LOG_ERROR, "%s|m_dbcache on_get fail", user.str());
				m_theSet.save_only_result(true);
			}
			else
			{
				//带新的时间戳的回包
				m_theSet.save_without_blockbuff();
			}
		}
		
		//回包
		if(m_ptoolkit->send_protobuf_msg(gDebug, m_theSet.get_obj(),
			CMD_DBCACHE_CREATE_RESP, user, 
			m_ptoolkit->get_queue_id(reqMsg), 
			m_ptoolkit->get_src_server(reqMsg), m_ptoolkit->get_src_handle(reqMsg)) != 0)
		{
			LOG(LOG_ERROR, "%s|send_to_queue(CMD_DBCACHE_CREATE_RESP, %u) fail", user.str(), m_ptoolkit->get_queue_id(reqMsg));
		}

		//LOG(LOG_INFO, "%s|CREATE|result=%d", user.str(),m_theSet.get_obj().result());
		return RET_DONE;
	}

protected:

	inline void get_now_day_hour(time_t nowtime, int& day, int& hour)
	{
		struct tm tm;
		localtime_r(&nowtime, &tm);
		//2011年了
		day = (tm.tm_year-110)*1000 + tm.tm_yday;
		hour = tm.tm_hour;
	}

protected:

	//timer id
	unsigned int m_timerID;
	//前端过来的请求副本
	char* m_dumpMsgBuff;
	int m_dumpMsgLen;
	//cache 操作
	CDataCacheDB m_dbcache;
	//缓存的set
	CDataBlockSet m_theSet;
	//特殊命令
	unsigned int m_specialCmd;
	unsigned int m_special_flag;	// 这个gm命令需要用到哪些数据
	//保存用户id
	USER_NAME m_saveName;
};

#endif
