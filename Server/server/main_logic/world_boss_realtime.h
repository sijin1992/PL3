#ifndef __PVP_REALTIME_MANAGER_H__
#define __PVP_REALTIME_MANAGER_H__
/*
* 世界BOSS实时信息，mmapfile保存
*/
#include "ini/ini_file.h"
#include "shm/shm_wrap.h"
#include "shm/mmap_wrap.h"
#include <memory.h>

//赛季时间信息
struct SEASON_TIME_INFO
{
	//当前赛季
	int mCurSeason;
	//季开始时间
	time_t mSeasonStartTime;
	//季结束时间
	time_t mSeasonEndTime;
	//BOSS更变时间
	time_t mSwapBossTime;
	//下个Boss时间
	time_t mNextBossTime;
	//攻击BOSS开始时间
	time_t mAttackStartTime;
	//攻击BOSS结束时间
	time_t mAttackEndTime;
	//奖励结算时间
	time_t mRewardCalcTime;

	char reserved[128];
	std::string debugStr();
};

//BOSS属性
struct BOSS_ATTRIBUTE
{
	long long hp;			//生命值
	long long hpmax;		//最大生命值
	long long totalhurt;	//受到总伤害

	char reserved[128];
	std::string debugStr();
};

//BOSS单位
struct WORLD_BOSS_UNIT
{
	//BOSS索引
	int mIndex;
	//属于哪一季
	int mSeason;
	//BOSS出生时间
	time_t mBornTime;
	//更新时间
	time_t mUpdateTime;
	//BOSS ID
	int mBossID;
	//世代
	int mGenerations;
	//属性
	BOSS_ATTRIBUTE mAttr;
	//是否活着
	bool mIsAlive;

	char reserved[256];
	WORLD_BOSS_UNIT()
	{
		reset();
	}
	void reset();
	std::string debugStr();
};

//世界BOSS实时信息
struct WORLD_BOSS_RT_INFO
{
	//format起始时间
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

//世界BOSS实时信息
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

