#ifndef __SERVERGLOBAL_DEFINE_H__
#define __SERVERGLOBAL_DEFINE_H__

#include "common/shm_hash_map.h"

#pragma pack(push)
#pragma pack(1)

struct USER_INFO_UNIT
{
	int roleLevel;			//角色等级
	int homeLevel;			//城堡等级
	int vipLevel;			//VIP等级
	int vipScore;			//VIP积分
	time_t createTime;		//创建时间
	time_t lastLoginTime;	//上次上线时间
	time_t lastLogoutTime;	//上次离线时间
	time_t lastActiveTime;	//上次活跃时间

	int regionID;			//所在大区ID
	int serverID;			//所在服务器ID

	char reserved[64];

	USER_INFO_UNIT()
	{
		memset(this, 0, sizeof(USER_INFO_UNIT));
	}
};

#pragma pack(pop)

#endif

