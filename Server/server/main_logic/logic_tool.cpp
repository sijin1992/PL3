//to-do: 替换CLogicTool为自己的类名字
//to-do: 替换logic_tool.h为自己的头文件
//to-do: 替换ModifyDataResp为应答的proto对象
//to-do: 替换ProtoTemplateReq为请求的proto对象
//to-do: 替换CMD_TEMPLATE_REQ为请求的命令字
//to-do: 替换CMD_LOGIC_TOOL_MODIFY_RESP为应答的命令字



#include "logic_tool.h"
#include "online_cache.h"
#include <unistd.h>

extern int gDebugFlag;
extern COnlineCache gOnlineCache;

int CLogicTool::check_password(const string& password)
{
	/*const char* keypre = "^_^wukan!@#";
	char skey[32];
	const char* salt = "$1$overlord$"; //overlord不要超过8字节
	time_t nowtime = time(NULL);
	struct tm * ptm = localtime(&nowtime);
	snprintf(skey, sizeof(skey), "%s%04d%02d%02d", keypre,ptm->tm_year+1900, ptm->tm_mon+1, ptm->tm_mday);
	char* result = crypt(skey, salt);
	result += strlen(salt);
	if(password != result)
	{
		LOG(LOG_ERROR, "cryptkey=[%s] not right", password.c_str());
		return -1;
	}*/

	return 0;
}

void CLogicTool::on_init()
{
	m_dumpMsgBuff = NULL;
	m_dumpMsgLen = 0;
	//m_theUserProto.Clear();
	//m_theBagProto.Clear();
	//m_resp.Clear();
}

int CLogicTool::send_fail_resp(CLogicMsg& msg)
{
	//ModifyDataResp resp;
	//resp.set_result(resp.FAIL);
	
	//if(m_ptoolkit->send_protobuf_msg(gDebugFlag, resp, CMD_LOGIC_TOOL_MODIFY_RESP, m_saveUser, 
		//m_ptoolkit->get_queue_id(msg)) != 0)
		//LOG(LOG_ERROR, "send CMD_LOGIC_TOOL_MODIFY_RESP fail");
		
	return RET_DONE;
}

int CLogicTool::on_active_sub(CLogicMsg& msg)
{
	if(gDebugFlag)
	{
		LOG(LOG_DEBUG, "CLogicTool[%u] recv cmd[0x%x]", m_id, m_ptoolkit->get_cmd(msg));

	}

	m_saveCmd = m_ptoolkit->get_cmd(msg);
	CBinProtocol binpro;
	if(m_ptoolkit->parse_bin_msg(msg, binpro) != 0)
	{
		return RET_DONE;
	}

	m_saveUser = binpro.head()->parse_name();

/* 不检查登录
	ONLINE_CACHE_UNIT* punit;
	if(gOnlineCache.getOnlineUnit(m_saveUser, punit)!= 0)
	{
		return RET_DONE;
	}
	else if(punit == NULL)
	{
		//不在线
		LOG(LOG_ERROR, "%s not online", m_saveUser.str());
		return send_fail_resp(msg);
	}
*/
	//dump包
	m_dumpMsgLen = msg.dump(m_dumpMsgBuff);

	//解析包
	/*if(m_saveCmd == CMD_LOGIC_TOOL_MODIFY_ROLEINFO_REQ
		|| m_saveCmd == CMD_LOGIC_TOOL_MODIFY_PLANTPERM_REQ
		|| m_saveCmd == CMD_LOGIC_TOOL_MODIFY_ITEMS_REQ
		|| m_saveCmd == CMD_LOGIC_TOOL_VIEW_USERDATA_REQ
		|| m_saveCmd == CMD_LOGIC_TOOL_MODIFY_TECH_REQ
		|| m_saveCmd == CMD_LOGIC_TOOL_CLEAR_FANGCHENGMI
		|| m_saveCmd == CMD_LOGIC_TOOL_CALCULATE_BUILDBONUS
	)
	{
		return lockget_user_data(m_saveUser, DATA_BLOCK_FLAG_CARDS|DATA_BLOCK_FLAG_MAIN);
	}
	else if(m_saveCmd == CMD_LOGIC_TOOL_ADD_FEED_REQ)
	{
		DBAddFeedsReq theReq;
		USER_NAME theUser;
		if(m_ptoolkit->parse_protobuf_msg(gDebugFlag, msg, theUser, *(theReq.mutable_newfeeds())) !=0)
			return send_fail_resp(msg);

		theReq.set_feedstab(7); //随便搞
		if(add_feeds(theUser, theReq) != 0)
			return send_fail_resp(msg);

		m_resp.set_result(m_resp.OK);
		if(m_ptoolkit->send_protobuf_msg(gDebugFlag, m_resp, CMD_LOGIC_TOOL_MODIFY_RESP,
				theUser, m_ptoolkit->get_queue_id(msg)) != 0)
			LOG(LOG_ERROR, "send CMD_LOGIC_TOOL_MODIFY_RESP fail");
		return RET_DONE;
	}
	else if(m_saveCmd == CMD_LOGIC_TOOL_OUTPUTDATA_REQ 
		|| m_saveCmd == CMD_LOGIC_TOOL_INPUTDATA_REQ
		|| m_saveCmd == CMD_LOGIC_TOOL_CLEARDATA_REQ)
	{
		return lockget_user_data(m_saveUser, DATA_BLOCK_FLAG_CARDS|DATA_BLOCK_FLAG_MAIN
			|DATA_BLOCK_FLAG_USERLIST|DATA_BLOCK_FLAG_FEEDS|DATA_BLOCK_FLAG_MAIL);
	}
	else if(m_saveCmd == CMD_LOGIC_TOOL_LEITAI_CLEAR_REQ)
	{
		return lockget_user_data(m_saveUser, DATA_BLOCK_FLAG_MAIN);
	}
	else*/
		LOG(LOG_ERROR, "unexpect cmd=0x%x" , m_ptoolkit->get_cmd(msg) );

	return RET_DONE;
}

//对象销毁前调用一次
void CLogicTool::on_finish()
{
	if(m_dumpMsgBuff != NULL)
	{
		delete[] m_dumpMsgBuff;
		m_dumpMsgBuff = NULL;
		m_dumpMsgLen = 0;
	}
}

CLogicProcessor* CLogicTool::create()
{
	return new CLogicTool;
}

/*
int CLogicTool::caculate_allbuidingbonus()
{
	int mainhp = 0;
	int mainatk = 0;
	int solhp = 0;
	int soldef = 0;
	int solatk = 0;
	for(int i=0; i<m_theUserProto.building_size(); ++i)
	{
		const Building& thebd = m_theUserProto.building(i);
		int id = thebd.buildingid();
		while(id != 0)
		{
			CConfItembuild* pconf = gAllConf.confBuild.get_conf(id);
			if(pconf == NULL)
			{
				return -1;
			}

			mainhp += pconf->BloodPercent;
			mainatk += pconf->AtkPercent;
			solhp += pconf->SHP;
			soldef += pconf->Sdef;
			solatk += pconf->Satk;

			id = pconf->PreviousJZId;
		}
	}

	RoleInfo* prole = m_theUserProto.mutable_roleinfo();
	prole->set_wonderatkbonus(mainatk);
	prole->set_wonderhpbonus(mainhp);
	prole->set_solatkbonus(solatk);
	prole->set_soldefbonus(soldef);
	prole->set_solhpbonus(solhp);
	return 0;
}

*/
int CLogicTool::on_get_data_sub(USER_NAME& user, CDataControlSlot* dataControl)
{
	CLogicMsg msg(m_dumpMsgBuff, m_dumpMsgLen);
	if(!dataControl)
	{
		return send_fail_resp(msg);
	}
	
	int result = dataControl->theSet.result();
	if(result != DataBlockSet::OK)
	{
		return send_fail_resp(msg);
	}
/*
	if(m_saveCmd == CMD_LOGIC_TOOL_MODIFY_ROLEINFO_REQ)
	{
		if(dataControl->get_main_data(m_theUserProto) != 0)
			return send_fail_resp(msg);
			
		if(dataControl->get_bag_data(m_theBagProto) != 0)
			return send_fail_resp(msg);
		
		ModifyRoleInfoReq req;
		USER_NAME tmp;
		if(m_ptoolkit->parse_protobuf_msg(gDebugFlag, msg, tmp, req) != 0)
			return send_fail_resp(msg);

		if(check_password(req.password())!=0)
			return send_fail_resp(msg);

		RoleInfo* prole = m_theUserProto.mutable_roleinfo();
		if(req.has_gold())
		{
			dataControl->modify_gold(*prole, req.gold());
		}

		if(req.has_money())
		{
			dataControl->modify_money(*prole, req.money());
		}

		if(req.has_ticket())
		{
			dataControl->modify_ticket(*prole, req.ticket());
		}

		if(req.has_labor())
		{
			dataControl->modify_labor(*prole, req.labor());
		}

		if(req.has_expr())
		{
			dataControl->modify_expr(m_theUserProto, m_theBagProto, req.expr());
		}

		if(req.has_usedlabor())
		{
			int labor = req.usedlabor();
			if(labor < 0)
				dataControl->free_labor(m_theUserProto, 0-labor);
			else
				dataControl->use_labor(m_theUserProto, labor);
		}

		if(req.has_gladiator())
		{
			PVEinfo* p =m_theUserProto.mutable_pveinfo();
			p->set_donelevel(req.gladiator());
		}
			
		if( dataControl->set_main_data(m_theUserProto)!=0 )
			return send_fail_resp(msg);

		if(dataControl->set_bag_data(m_theBagProto) != 0)
			return send_fail_resp(msg);

	}
	else if(m_saveCmd == CMD_LOGIC_TOOL_MODIFY_ITEMS_REQ)
	{
		if(dataControl->get_bag_data(m_theBagProto) != 0)
			return send_fail_resp(msg);
		ModifyItemsReq req;
		USER_NAME tmp;
		if(m_ptoolkit->parse_protobuf_msg(gDebugFlag, msg, tmp, req) != 0)
			return send_fail_resp(msg);

		if(check_password(req.password())!=0)
			return send_fail_resp(msg);

		int type = req.type();

		if(type == SHOP_ITEM_STYLE_NORMAL || type == SHOP_ITEM_STYLE_RANDBOX)
		{
			dataControl->modify_bag_items(m_theBagProto.mutable_normal(), req.item().itemid(), req.item().itemnum(), true);
		}
		if(type == SHOP_ITEM_STYLE_GEM)
		{
			dataControl->modify_bag_items(m_theBagProto.mutable_gems(), req.item().itemid(), req.item().itemnum(), true);
		}
		else if(type == SHOP_ITEM_STYLE_EQUIP)
		{
			dataControl->modify_bag_items(m_theBagProto.mutable_equip(), req.item().itemid(), req.item().itemnum(), true);
		}
		else if(type == SHOP_ITEM_STYLE_TASK)
		{
			dataControl->modify_bag_items(m_theBagProto.mutable_task(), req.item().itemid(), req.item().itemnum(), true);
		}
		else if(type == SHOP_ITEM_STYLE_BACKGROUD)
		{
			if(req.item().itemnum() > 0)
				dataControl->add_items_endtime(m_theBagProto.mutable_background(), req.item().itemid(), req.item().itemnum());
			else //扣时间很麻烦直接删掉
				dataControl->remove_bagitem(m_theBagProto.mutable_background(), req.item().itemid());
		}
	
		if(dataControl->set_bag_data(m_theBagProto) != 0)
			return send_fail_resp(msg);
	}
	else if(m_saveCmd == CMD_LOGIC_TOOL_MODIFY_PLANTPERM_REQ)
	{
		if(dataControl->get_main_data(m_theUserProto) != 0)
			return send_fail_resp(msg);
		
		ModifyPlantPermReq req;
		USER_NAME tmp;
		if(m_ptoolkit->parse_protobuf_msg(gDebugFlag, msg, tmp, req) != 0)
			return send_fail_resp(msg);

		if(check_password(req.password())!=0)
			return send_fail_resp(msg);
			
		dataControl->set_plant_permit(m_theUserProto, req.plantid());
			
		if( dataControl->set_main_data(m_theUserProto)!=0 )
			return send_fail_resp(msg);
	}
	else if(m_saveCmd == CMD_LOGIC_TOOL_VIEW_USERDATA_REQ)
	{
		if(dataControl->get_main_data(m_theUserProto) != 0)
			return send_fail_resp(msg);
			
		if(m_ptoolkit->send_protobuf_msg(gDebugFlag, m_theUserProto, CMD_LOGIC_TOOL_VIEW_USERDATA_RESP,
				user, m_ptoolkit->get_queue_id(msg)) != 0)
			LOG(LOG_ERROR, "send CMD_LOGIC_TOOL_VIEW_USERDATA_RESP fail");
		return unlock_user_data(user, false, true);
	}
	else if(m_saveCmd == CMD_LOGIC_TOOL_MODIFY_TECH_REQ)
	{
		if(dataControl->get_main_data(m_theUserProto) != 0)
			return send_fail_resp(msg);

		ModifyTechReq req;
		USER_NAME tmp;
		if(m_ptoolkit->parse_protobuf_msg(gDebugFlag, msg, tmp, req) != 0)
			return send_fail_resp(msg);

		if(check_password(req.password())!=0)
			return send_fail_resp(msg);

		int techclass = req.techclass();
		int idx = req.techtype();
		Technology* ptech = NULL;
		if(techclass == TECH_CLASS_BUILD)
		{
			ptech = dataControl->get_buildtech(m_theUserProto, idx);
		}
		else
		{
			LOG(LOG_ERROR, "techclass=%d, not support", techclass);
			return send_fail_resp(msg);
		}

		if(!ptech)
		{
			return send_fail_resp(msg);
		}

		ptech->Clear();
		ptech->CopyFrom(req.thetech());
			
		if( dataControl->set_main_data(m_theUserProto)!=0 )
			return send_fail_resp(msg);
	}
	else if(m_saveCmd == CMD_LOGIC_TOOL_CLEAR_FANGCHENGMI)
	{
		if(dataControl->get_main_data(m_theUserProto) != 0)
			return send_fail_resp(msg);

		Fangchenmi* pfang = m_theUserProto.mutable_fang();
		if(pfang->has_isadult())
		{
			pfang->clear_isadult();
			pfang->clear_limittime();
			pfang->clear_lastlogouttime();
			pfang->set_offlinetime(0);
			pfang->set_starttime(time(NULL));
		}
		else
		{
			pfang->set_isadult(1);
		}
		
		if( dataControl->set_main_data(m_theUserProto)!=0 )
			return send_fail_resp(msg);
	}
	else if(m_saveCmd == CMD_LOGIC_TOOL_CALCULATE_BUILDBONUS)
	{
		if(dataControl->get_main_data(m_theUserProto) != 0)
			return send_fail_resp(msg);
		if(caculate_allbuidingbonus() !=0)
			return send_fail_resp(msg);
		if( dataControl->set_main_data(m_theUserProto)!=0 )
			return send_fail_resp(msg);
	}
	else if(m_saveCmd == CMD_LOGIC_TOOL_CLEARDATA_REQ)
	{
		DailyUserList userlist;
		FeedsList feedslist;
		MailList maillist;
			
		ToolClearDataReq req;
		USER_NAME tmp;
		if(m_ptoolkit->parse_protobuf_msg(gDebugFlag, msg, tmp, req) != 0)
			return send_fail_resp(msg);
		string block = req.block();

		if(check_password(req.password())!=0)
			return send_fail_resp(msg);

		if(block != "task")
		{
			m_theUserProto.Clear();
		}
		else
		{
			if(dataControl->get_main_data(m_theUserProto) != 0)
				return send_fail_resp(msg);
			m_theUserProto.clear_tasklist();
		}
		
		m_theBagProto.Clear();
		if(block == "all")
		{
			//TODO: booljin
			//dataControl->create_new_data_inner(m_theUserProto, m_theBagProto, req.mutable_reg());
		}
		

		if(block == "all" || block=="task")
		{
			if(dataControl->set_main_data(m_theUserProto) != 0)
				return send_fail_resp(msg);
		}
			
		if(block == "bag" || block == "all")
		{
			if(dataControl->set_bag_data(m_theBagProto) != 0)
				return send_fail_resp(msg);
		}
		
		if(block == "userlist" || block == "all")
		{
			if(dataControl->set_userlist_data(userlist) !=0)
				return send_fail_resp(msg);
		}

		if(block == "maillist" || block == "all")
		{
			if(dataControl->set_mail_data(maillist) !=0)
				return send_fail_resp(msg);
		}

		if(block == "feeds" || block == "all")
		{
			if(dataControl->set_feeds_data(feedslist) !=0)
				return send_fail_resp(msg);
		}
	}
	else if(m_saveCmd == CMD_LOGIC_TOOL_INPUTDATA_REQ)
	{
		ToolInputUserReq req;
		USER_NAME tmp;
		if(m_ptoolkit->parse_protobuf_msg(gDebugFlag, msg, tmp, req) != 0)
			return send_fail_resp(msg);

		if(check_password(req.password())!=0)
			return send_fail_resp(msg);

		ToolUserDataTotal* pdata = req.mutable_databak();

		if(dataControl->set_main_data(*(pdata->mutable_userdata())) != 0)
			return send_fail_resp(msg);
			
		if(dataControl->set_bag_data(*(pdata->mutable_bag())) != 0)
			return send_fail_resp(msg);
			
		if(dataControl->set_userlist_data(*(pdata->mutable_userlist())) !=0)
			return send_fail_resp(msg);
		
		if(dataControl->set_mail_data(*(pdata->mutable_maillist())) !=0)
			return send_fail_resp(msg);
		
		if(dataControl->set_feeds_data(*(pdata->mutable_feeds())) !=0)
			return send_fail_resp(msg);
		
	}
	else if(m_saveCmd == CMD_LOGIC_TOOL_OUTPUTDATA_REQ)
	{
		ToolOutputUserReq req;
		ToolOutputUserResp resp;
		USER_NAME tmp;
		if(m_ptoolkit->parse_protobuf_msg(gDebugFlag, msg, tmp, req) != 0)
			return send_fail_resp(msg);

		if(check_password(req.password())!=0)
			return send_fail_resp(msg);

		DailyUserList userlist;
		MailList maillist;
		FeedsList feedslist;

		if(dataControl->get_main_data(m_theUserProto) != 0)
			return send_fail_resp(msg);
			
		if(dataControl->get_bag_data(m_theBagProto) != 0)
			return send_fail_resp(msg);
			
		if(dataControl->get_userlist_data(userlist) !=0)
			return send_fail_resp(msg);

		if(dataControl->get_mail_data(maillist) !=0)
			return send_fail_resp(msg);

		if(dataControl->get_feeds_data(feedslist) !=0)
			return send_fail_resp(msg);

		ToolUserDataTotal* pdata = resp.mutable_databak();
		pdata->mutable_feeds()->CopyFrom(feedslist);
		pdata->mutable_maillist()->CopyFrom(maillist);
		pdata->mutable_userlist()->CopyFrom(userlist);
		pdata->mutable_userdata()->CopyFrom(m_theUserProto);
		pdata->mutable_bag()->CopyFrom(m_theBagProto);

		resp.set_result(resp.OK);
		if(m_ptoolkit->send_protobuf_msg(gDebugFlag, resp, CMD_LOGIC_TOOL_OUTPUTDATA_RESP,
			 	user, m_ptoolkit->get_queue_id(msg)) != 0)
			LOG(LOG_ERROR, "send CMD_LOGIC_TOOL_OUTPUTDATA_RESP fail");
		return unlock_user_data(user, false, true);;
	}
	else if(m_saveCmd == CMD_LOGIC_TOOL_LEITAI_CLEAR_REQ)
	{
		if(dataControl->get_main_data(m_theUserProto) != 0)
			return send_fail_resp(msg);

		m_theUserProto.clear_leitai();
			
		if(dataControl->set_main_data(m_theUserProto) != 0)
			return send_fail_resp(msg);
	}*/

	return unlockset_user_data(user, false, false);
}

int CLogicTool::on_set_data_sub(USER_NAME & user, CDataControlSlot * dataControl)
{
	CLogicMsg msg(m_dumpMsgBuff, m_dumpMsgLen);
	if(dataControl == NULL || dataControl->theSet.result() != DataBlockSet::OK)
	{
		return send_fail_resp(msg);
	}

	//m_resp.set_result(m_resp.OK);
	//if(m_ptoolkit->send_protobuf_msg(gDebugFlag, m_resp, CMD_LOGIC_TOOL_MODIFY_RESP,
		// 	user, m_ptoolkit->get_queue_id(msg)) != 0)
		//LOG(LOG_ERROR, "send CMD_LOGIC_TOOL_MODIFY_RESP fail");
	return RET_DONE;
}


