#ifndef __LOGIC_AUTH_TASK_H__
#define __LOGIC_AUTH_TASK_H__

#include "logic/driver.h"
#include "proto/gateway.pb.h"
#include "http_helper.h"
#include "select_server.h"
#include <sstream>

extern int gDebug;
extern unsigned int MSG_QUEUE_ID_AUTH;
extern CServerSelector gServerSelector;
extern unsigned short PORTAL_SERVER_PORT;

//��ʱ����ȫ����֤ͨ����
class CLogicAuth:public CLogicProcessor
{
public:
	virtual void on_init()
	{
	}
	
	//��msg�����ʱ�򼤻����
	virtual int on_active(CLogicMsg& msg)
	{
		//������
		int cmd = m_ptoolkit->get_cmd(msg);
		if(gDebug)
			LOG(LOG_DEBUG,"recv cmd(0x%x) ", cmd);
		
		if(cmd == CMD_AUTH_REQ)
		{
			AuthReq req;
			AuthResp resp;
			USER_NAME user ;
			if(m_ptoolkit->parse_protobuf_msg(gDebug, msg,  user, req) !=0)
			{
				LOG(LOG_ERROR, "%s|parse_protobuf_msg AuthReq fail", user.str());
				return RET_DONE;
			}

			//������

			//������һ��
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
					return send_msg(msg, resp, user);
				}
				
				thehelper.init(serverIP, PORTAL_SERVER_PORT, theUrl);
				if(thehelper.do_getuserinfo(req.key().c_str(),user.str()) != 0)
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
			
			if(!ok)
			{
				return send_msg(msg, resp, user);
			}
			
			if(gDebug)
			{
				LOG(LOG_DEBUG,"%u auth(%s,%s) getuserinfo=%d", 
					m_id, user.str(), req.key().c_str(), 0);
			}

			if(ok)
			{
				return send_msg(msg, resp, user, false); //�ɹ�
			}
			else
			{
				LOG(LOG_ERROR, "%s|theUserInfo.ret(%d)!=0", user.str(), 1);
				return send_msg(msg, resp, user);
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
	
	//��������ǰ����һ��
	virtual void on_finish()
	{
	}
	
	virtual CLogicProcessor* create()
	{
		return new CLogicAuth;
	}
};

#endif

