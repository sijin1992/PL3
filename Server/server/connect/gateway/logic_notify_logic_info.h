#ifndef __LOGIC_NOTIFY_LOGIC_INFO_H__
#define __LOGIC_NOTIFY_LOGIC_INFO_H__

#include "logic/driver.h"
#include "proto/gateway.pb.h"
#include "http_helper.h"
#include "select_server.h"
#include "proto/inner_cmd.pb.h"

extern int gDebug;

//暂时做成全部验证通过的
class CLogicNotifyLogicInfo:public CLogicProcessor
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
		
		if(cmd == CMD_NOTIFY_LOGIC_INFO_REQ)
		{
			RsyncLogicStatus req;
			USER_NAME user ;
			if(m_ptoolkit->parse_protobuf_msg(gDebug, msg,  user, req) !=0)
			{
				LOG(LOG_ERROR, "%s|parse_protobuf_msg RsyncLogicStatus fail", user.str());
				return RET_DONE;
			}

			for(int i = 0; i < req.centre_list_size(); i++)
            {
				const RsyncLogicStatus_CentreInfo t = req.centre_list(i);
                string cip = t.centre_ip();
                int cport = t.centre_port();
				int sid = 0;
				for(int j = 0; j < req.idx_size(); j++)
				{
					sid = req.idx(j);				
					//可重试一次
					bool ok = false;
					string url = cip + ":inn";
					for(int i=0; i<2; ++i)
					{
						CHttpHelper thehelper;

						thehelper.init(cip, cport, url);
						if(thehelper.do_send_logic_info(
							req.ip(),req.port(),sid,req.max_client(),req.cur_client(),
							req.version(), cip, req.max_reg(), req.cur_reg()) != 0)
						{
							LOG(LOG_ERROR, "send logic info|do_send_logic_info fail i=%d", i);
						}
						else
						{
							ok = true;
							break;
						}
							
					}
				}
			}
		}
		else if(cmd == CMD_NOTIFY_GLOBALCB_REQ)
		{
			Rsync2GlobalCB req;
			USER_NAME user ;
			if(m_ptoolkit->parse_protobuf_msg(gDebug, msg,  user, req) !=0)
			{
				LOG(LOG_ERROR, "%s|parse_protobuf_msg RsyncLogicStatus fail", user.str());
				return RET_DONE;
			}

			//走网络

			//可重试一次
			bool ok = false;
			string url = req.globalcb_ip() + ":inn";
			int sid = 0;
			for(int j = 0; j < req.idx_size(); j++)
			{
				sid = req.idx(j);
				for(int i=0; i<2; ++i)
				{
					CHttpHelper thehelper;

					thehelper.init(req.globalcb_ip(), req.globalcb_port(), url);
					if(thehelper.do_send2globalcb(
						req.port(),sid, req.globalcb_ip()) != 0)
					{
						LOG(LOG_ERROR, "send to ghttpcb|do_send_ghttpcb_info fail i=%d", i);
					}
					else
					{
						ok = true;
						break;
					}	
				}

				if( req.has_globalcb_ip_2() )
				{
					for(int i=0; i<2; ++i)
					{
						CHttpHelper thehelper;

						thehelper.init(req.globalcb_ip_2(), req.globalcb_port_2(), req.globalcb_ip_2() + ":inn");
						if(thehelper.do_send2globalcb(
							req.port(),sid, req.globalcb_ip_2()) != 0)
						{
							LOG(LOG_ERROR, "send to ghttpcb2|do_send_ghttpcb_info fail i=%d", i);
						}
						else
						{
							break;
						}	
					}
				}
			}
		}
		else
			LOG(LOG_ERROR, "unexpect cmd=%u" ,m_ptoolkit->get_cmd(msg) );

		return RET_DONE;
	}
	
	//对象销毁前调用一次
	virtual void on_finish()
	{
	}
	
	virtual CLogicProcessor* create()
	{
		return new CLogicNotifyLogicInfo;
	}
};

#endif

