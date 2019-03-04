//to-do: �滻__MAIN_LOGIC_TEMPLATE_H__Ϊ�Լ��ĺ�
//to-do: �滻TemplateProtocolΪ�Լ���proto�ļ���
//to-do: �滻CLogicTemplateΪ�Լ���������
//to-do: �滻ProtoTemplateRespΪӦ���proto����


#ifndef __MAIN_LOGIC_TEMPLATE_H__
#define __MAIN_LOGIC_TEMPLATE_H__

#include "logic/driver.h"
#include "user_data_base.h"
#include "proto/TemplateProtocol.pb.h"

class CLogicTemplate:public CUserDataBase
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
	int send_resp(CLogicMsg& msg, bool fail = true);

protected:
	USER_NAME m_saveUser;
	int m_saveCmd;
	char* m_dumpMsgBuff;
	int m_dumpMsgLen;
	UserData m_theUserProto;
	ProtoTemplateResp m_resp;
	bool m_locked;
};


#endif 

