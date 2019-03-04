#ifndef __LOGIC_USERINFO_REPORT_H__
#define __LOGIC_USERINFO_REPORT_H__

#include "logic/driver.h"
#include "proto/gateway.pb.h"
#include "http_helper.h"
#include "select_server.h"
#include <sstream>

extern int gDebug;
extern unsigned int MSG_QUEUE_ID_AUTH;
extern CServerSelector gServerSelector;
extern unsigned short PORTAL_SERVER_PORT;

class CLogicUserInfoReport:public CLogicProcessor
{
public:
	virtual void on_init()
	{
	}
	
	//有msg到达的时候激活对象
	virtual int on_active(CLogicMsg& msg)
	{
		//解析包
		int cmd = m_ptoolkit->get_cmd(msg);
		if(gDebug)
			LOG(LOG_DEBUG,"recv cmd(0x%x) ", cmd);
		
		if(cmd == CMD_GATEWAY_USERINFO_REPORT_REQ)
		{
			UserInfoReportReq req;
			USER_NAME user;
			if(m_ptoolkit->parse_protobuf_msg(gDebug, msg,  user, req) !=0)
			{
				LOG(LOG_ERROR, "%s|parse_protobuf_msg UserInfoReportReq fail", user.str());
				return RET_DONE;
			}

			vector<string> keys;
			vector<string> values;

#define PICK_PARAM_INT(param) \
	if( req.has_##param() ) \
	{\
		keys.push_back(#param);\
		stringstream ss;\
		ss << req.param();\
		values.push_back(ss.str());\
	}

#define PICK_PARAM(param) \
	if( req.has_##param() ) \
	{\
		keys.push_back(#param);\
		values.push_back(req.param());\
	}

			PICK_PARAM_INT(act_type);
			PICK_PARAM(user_id);
			PICK_PARAM(nick_name);
			PICK_PARAM_INT(sex);
			PICK_PARAM_INT(time);

			//走网络

			//可重试一次
			bool ok = false;
			int idx = 0;//req.domain();
			idx = 0;
			for(int i=0; i<2; ++i)
			{
				CHttpHelper thehelper;
				string serverIP;
				string theUrl;
				if(!gServerSelector.get_server(idx, serverIP, theUrl))
				{
					LOG(LOG_ERROR, "%s|plat(%d) no server available", user.str(), idx);
					break;
				}
				
				thehelper.init(serverIP, PORTAL_SERVER_PORT, theUrl);
				if(thehelper.do_reportuserinfo(user.str(), keys, values) != 0)
				{
					LOG(LOG_ERROR, "%s|do_getuserinfo fail i=%d", user.str(), i);
					gServerSelector.disable_server(idx, serverIP);
				}
				else
				{
					ok = true;
					break;
				}
					
			}

			if(ok)
			{
				LOG(LOG_ERROR, "%s|report user info success:%s", user.str(), req.DebugString().c_str());
			}
			else
			{
				LOG(LOG_ERROR, "%s|report user info failed:%s", user.str(), req.DebugString().c_str());
			}
		}
		else
			LOG(LOG_ERROR, "unexpect cmd=%u" ,m_ptoolkit->get_cmd(msg) );

		return RET_DONE;
	}

	int  send_msg(CLogicMsg& msg, AuthResp& resp, USER_NAME& user, bool fail=true)
	{
		if(fail)
			resp.set_result(resp.FAIL);
		else
			resp.set_result(resp.OK);
		
		if(m_ptoolkit->send_protobuf_msg(gDebug, resp, CMD_AUTH_RESP, user, MSG_QUEUE_ID_AUTH, m_ptoolkit->get_src_server(msg), m_ptoolkit->get_src_handle(msg)) != 0)
		{
			LOG(LOG_ERROR, "send_to_queue(CMD_AUTH_RESP,MSG_QUEUE_ID_AUTH) fail");
		}
		return RET_DONE;
	}
	
	//对象销毁前调用一次
	virtual void on_finish()
	{
	}
	
	virtual CLogicProcessor* create()
	{
		return new CLogicAuth;
	}
};

#endif

