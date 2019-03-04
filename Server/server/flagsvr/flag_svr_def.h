#ifndef __SEVERFLAG_DEFINE_H__
#define __SEVERFLAG_DEFINE_H__

#include "common/shm_hash_map.h"

#pragma pack(push)
#pragma pack(1)

//为了做不影响现网的扩容
#define FLAG_SVR_SHM_KEY_OLD 0x20005

struct FLAG_SERVER_UNIT
{
	unsigned short level;
	char boxlevel;
	char boxexist;
	unsigned int boxendtime;
};

struct CDKEY_DATA
{
	int giftid;
	int state;
};

#pragma pack(pop)

extern CShmHashMap<FLAG_SERVER_UNIT, USER_NAME_BYTE, UserByteHashType> gFlagMap;

#endif

