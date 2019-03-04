//to-do: �滻__MAIN_LOGIC_TOOL_H__Ϊ�Լ��ĺ�
//to-do: �滻toolprotocolΪ�Լ���proto�ļ���
//to-do: �滻CLogicToolΪ�Լ���������
//to-do: �滻ModifyDataRespΪӦ���proto����


#ifndef __MAIN_LOGIC_TOOL_H__
#define __MAIN_LOGIC_TOOL_H__

#include "logic/driver.h"
#include "user_data_base.h"

class CLogicTool:public CUserDataBase
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
	int send_fail_resp(CLogicMsg& msg);

	//int caculate_allbuidingbonus();

	int check_password(const string& password);

protected:
	char* m_dumpMsgBuff;
	int m_dumpMsgLen;
	//UserData m_theUserProto;
	//BagList m_theBagProto;
	//ModifyDataResp m_resp;
};


#endif 

