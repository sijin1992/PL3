//to-do: 替换CLogicTemplate为自己的类名字
//to-do: 替换logic_template.h为自己的头文件
//to-do: 替换ProtoTemplateResp为应答的proto对象
//to-do: 替换ProtoTemplateReq为请求的proto对象
//to-do: 替换CMD_TEMPLATE_REQ为请求的命令字
//to-do: 替换CMD_TEMPLATE_RESP为应答的命令字



#include "logic_template.h"
#include "online_cache.h"

extern int gDebugFlag;
extern COnlineCache gOnlineCache;

void CLogicTemplate::on_init()
{
	m_dumpMsgBuff = NULL;
	m_dumpMsgLen = 0;
	m_theUserProto.Clear();
	m_resp.Clear();
	m_locked = false;
}

int CLogicTemplate::send_resp(CLogicMsg& msg, bool fail)
{
	if(fail)
		m_resp.set_result(m_resp.FAIL);
	else
		m_resp.set_result(m_resp.OK);
	
	if(m_ptoolkit->send_protobuf_msg(gDebugFlag, m_resp, CMD_TEMPLATE_RESP, m_saveUser, 
		m_ptoolkit->get_queue_id(msg)) != 0)
		LOG_USER(LOG_ERROR, "%s", "send CMD_TEMPLATE_RESP fail");

	if(fail && m_locked)
	{
		return unlock_user_data(m_saveUser, false, true);
	}
		
	return RET_DONE;
}

int CLogicTemplate::on_active_sub(CLogicMsg& msg)
{
	unsigned int cmd = m_ptoolkit->get_cmd(msg);

	if(gDebugFlag)
	{
		LOG_USER(LOG_DEBUG, "CLogicTemplate[%u] recv cmd[0x%x]", m_id, cmd);
	}

	bool needOnline = true;
	bool isInvokeCmd = (cmd == CMD_TEMPLATE_REQ);
	if(isInvokeCmd)
	{
		m_saveCmd = m_ptoolkit->get_cmd(msg);
		CBinProtocol binpro;
		if(m_ptoolkit->parse_bin_msg(msg, binpro) != 0)
		{
			return RET_DONE;
		}
		m_saveUser = binpro.head()->parse_name();

		if(needOnline)
		{
			ONLINE_CACHE_UNIT* punit;
			if(gOnlineCache.getOnlineUnit(m_saveUser, punit)!= 0)
			{
				return RET_DONE;
			}
			else if(punit == NULL)
			{
				//不在线
				LOG_USER(LOG_ERROR, "%s not online", m_saveUser.str());
				return send_resp(msg);
			}
		}

		//dump包
		m_dumpMsgLen = msg.dump(m_dumpMsgBuff);
	}

	//下一步
	if(cmd == CMD_TEMPLATE_REQ)
	{
		return lockget_user_data(m_saveUser, DATA_BLOCK_FLAG_MAIN);
	}
	else
		LOG_USER(LOG_ERROR, "unexpect cmd=0x%x" , cmd);

	return RET_DONE;
}

//对象销毁前调用一次
void CLogicTemplate::on_finish()
{
	if(m_dumpMsgBuff != NULL)
	{
		delete[] m_dumpMsgBuff;
		m_dumpMsgBuff = NULL;
		m_dumpMsgLen = 0;
	}
}

CLogicProcessor* CLogicTemplate::create()
{
	return new CLogicTemplate;
}

int CLogicTemplate::on_get_data_sub(USER_NAME& user, CDataControlSlot* dataControl)
{
	CLogicMsg msg(m_dumpMsgBuff, m_dumpMsgLen);
	if(!dataControl)
	{
		return send_resp(msg);
	}
	
	int result = dataControl->theSet.result();
	if(result != DataBlockSet::OK)
	{
		return send_resp(msg);
	}

	if(user == m_saveUser)
	{
		m_locked = true;
		if(dataControl->get_main_data(m_theUserProto) != 0)
		{
			return send_resp(msg);
		}

		int ret = 0;

		if(m_saveCmd == CMD_TEMPLATE_REQ)
		{
			ret=on_something(msg, dataControl);
		}

		if(ret != 0)
		{
			return send_resp(msg);
		}
		
		if( dataControl->set_main_data(m_theUserProto)!=0 )
		{
			return send_resp(msg);
		}
		
		return unlockset_user_data(user, false, false);
	}
	
	LOG_USER(LOG_ERROR, "state error for get_user_data(%s)", user.to_str().c_str());
	return send_resp(msg);
}

int CLogicTemplate::on_something(CLogicMsg& msg, CDataControlSlot* dataControl)
{
	ProtoTemplateReq req;
	USER_NAME tmp;
	if(m_ptoolkit->parse_protobuf_msg(gDebugFlag, msg, tmp, req) != 0)
		return -1;

	return 0;
}

int CLogicTemplate::on_set_data_sub(USER_NAME & user, CDataControlSlot * dataControl)
{
	CLogicMsg msg(m_dumpMsgBuff, m_dumpMsgLen);
	if(dataControl == NULL || dataControl->theSet.result() != DataBlockSet::OK)
	{
		return send_resp(msg);
	}

	if(user == m_saveUser)
	{
		return send_resp(msg, false);
	}

	LOG_USER(LOG_ERROR, "state error for set_user_data(%s)", user.to_str().c_str());
	return send_resp(msg);	
}


