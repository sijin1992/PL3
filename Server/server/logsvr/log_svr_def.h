#ifndef __SERVERGLOBAL_DEFINE_H__
#define __SERVERGLOBAL_DEFINE_H__

#include "common/shm_hash_map.h"

#pragma pack(push)
#pragma pack(1)

struct USER_INFO_UNIT
{
	int roleLevel;			//��ɫ�ȼ�
	int homeLevel;			//�Ǳ��ȼ�
	int vipLevel;			//VIP�ȼ�
	int vipScore;			//VIP����
	time_t createTime;		//����ʱ��
	time_t lastLoginTime;	//�ϴ�����ʱ��
	time_t lastLogoutTime;	//�ϴ�����ʱ��
	time_t lastActiveTime;	//�ϴλ�Ծʱ��

	int regionID;			//���ڴ���ID
	int serverID;			//���ڷ�����ID

	char reserved[64];

	USER_INFO_UNIT()
	{
		memset(this, 0, sizeof(USER_INFO_UNIT));
	}
};

#pragma pack(pop)

#endif

