//to-do: �滻__MAIN_LOGIC_TOOL_H__Ϊ�Լ��ĺ�
//to-do: �滻toolprotocolΪ�Լ���proto�ļ���
//to-do: �滻CLogicHttpcbΪ�Լ���������
//to-do: �滻ModifyDataRespΪӦ���proto����


#ifndef __MAIN_LOGIC_HTTPCB_H__
#define __MAIN_LOGIC_HTTPCB_H__

#include "logic/driver.h"
#include "user_data_base.h"
#include "proto/httpcb.pb.h"
#include "lua_manager.h"


class CLogicHttpcb:public CUserDataBase
{
public:
	virtual void on_init();
	
	virtual int on_active_sub(CLogicMsg& msg);

	
	//��������ǰ����һ��
	virtual void on_finish();
	
	virtual CLogicProcessor* create();

	int on_get_data_sub(USER_NAME & user, CDataControlSlot* dataControl);
	int on_set_data_sub(USER_NAME & user,CDataControlSlot * dataControl);

protected:
	int send_resp(CLogicMsg& msg, int code);
	//int on_buy_item(CLogicMsg& msg, int buyid, int buynum, CDataControlSlot* dataControl, int price);

protected:
	char* m_dumpMsgBuff;
	int m_dumpMsgLen;

	HttpAddMondyResp m_addMoneyResp;
	UserInfo m_main_data;

	CDataControlSlot* m_dataControl;
	CDataControlSlot* m_paydataControl;
	int m_yuekaflag;
	int m_itemid;
	int m_new_itemid;
	string m_ext_items;
	bool m_userlocked;
};


#endif 

