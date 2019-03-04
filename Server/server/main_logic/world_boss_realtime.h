#ifndef __PVP_REALTIME_MANAGER_H__
#define __PVP_REALTIME_MANAGER_H__
/*
* ����BOSSʵʱ��Ϣ��mmapfile����
*/
#include "ini/ini_file.h"
#include "shm/shm_wrap.h"
#include "shm/mmap_wrap.h"
#include <memory.h>

//����ʱ����Ϣ
struct SEASON_TIME_INFO
{
	//��ǰ����
	int mCurSeason;
	//����ʼʱ��
	time_t mSeasonStartTime;
	//������ʱ��
	time_t mSeasonEndTime;
	//BOSS����ʱ��
	time_t mSwapBossTime;
	//�¸�Bossʱ��
	time_t mNextBossTime;
	//����BOSS��ʼʱ��
	time_t mAttackStartTime;
	//����BOSS����ʱ��
	time_t mAttackEndTime;
	//��������ʱ��
	time_t mRewardCalcTime;

	char reserved[128];
	std::string debugStr();
};

//BOSS����
struct BOSS_ATTRIBUTE
{
	long long hp;			//����ֵ
	long long hpmax;		//�������ֵ
	long long totalhurt;	//�ܵ����˺�

	char reserved[128];
	std::string debugStr();
};

//BOSS��λ
struct WORLD_BOSS_UNIT
{
	//BOSS����
	int mIndex;
	//������һ��
	int mSeason;
	//BOSS����ʱ��
	time_t mBornTime;
	//����ʱ��
	time_t mUpdateTime;
	//BOSS ID
	int mBossID;
	//����
	int mGenerations;
	//����
	BOSS_ATTRIBUTE mAttr;
	//�Ƿ����
	bool mIsAlive;

	char reserved[256];
	WORLD_BOSS_UNIT()
	{
		reset();
	}
	void reset();
	std::string debugStr();
};

//����BOSSʵʱ��Ϣ
struct WORLD_BOSS_RT_INFO
{
	//format��ʼʱ��
	time_t beginTime;
	time_t endTime;
	SEASON_TIME_INFO seasonTime;
	WORLD_BOSS_UNIT boss;
	char reserved[128];
	
	void format(const SEASON_TIME_INFO &st)
	{
		memset(reserved, 0, sizeof(reserved));
		beginTime = time(NULL);
		seasonTime = st;
		boss.reset();
	}
	void resetTime(const SEASON_TIME_INFO &st)
	{
		memset(reserved, 0, sizeof(reserved));
		beginTime = time(NULL);
		seasonTime = st;
	}
	void resetBoss()
	{
		boss.reset();
	}
};

//����BOSSʵʱ��Ϣ
class CWorldBossRealTime
{
public:
	CWorldBossRealTime();
	bool init(const SEASON_TIME_INFO &tInfo, const char* mapfile, int resetTime=0, int resetBoss=0);
	
	SEASON_TIME_INFO &seasonTime();
	WORLD_BOSS_UNIT &boss();

	time_t getBeginTime();

protected:
	bool mInited;
	std::string	mMapFilePath;
	CMmapWrap mMmap;
	WORLD_BOSS_RT_INFO *mWBRTInfo;
};

#endif 

