#ifndef __MAIN_LOGIC_GM_USER_SNAP_H__
#define __MAIN_LOGIC_GM_USER_SNAP_H__

#include "logic/driver.h"
#include "user_data_base.h"
#include "proto/gm_cmd.pb.h"
#include <vector>

using namespace std;

class CLogicGMUserSnap:public CUserDataBase
{
public:
	virtual void on_init();
	
	virtual int on_active_sub(CLogicMsg& msg);

	
	//对象销毁前调用一次
	virtual void on_finish();
	
	virtual CLogicProcessor* create();

	int on_get_data_sub(USER_NAME & user, CDataControlSlot* dataControl);
	int on_set_data_sub(USER_NAME & user,CDataControlSlot * dataControl);

protected:
	int check_gm(const char* gmuser, string gmkey);
	int send_general_resp(CLogicMsg& msg, int code = -1);
protected:
	char* m_dumpMsgBuff;
	int m_dumpMsgLen;

	uint32_t m_fd;
	uint64_t m_session;
	GMGetUserSnapResp m_userSnapResp;
};


#endif 

