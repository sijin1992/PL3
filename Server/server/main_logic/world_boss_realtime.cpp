#include "world_boss_realtime.h"
#include "time/time_util.h"
#include "log/log.h"
#include <sstream>

std::string SEASON_TIME_INFO::debugStr()
{
	std::stringstream sstr;
	sstr << "mCurSeason=" << mCurSeason << "|";
	sstr << "mSeasonStartTime:" << CTimeUtil::TimeString(mSeasonStartTime) << "|";
	sstr << "mSeasonEndTime:" << CTimeUtil::TimeString(mSeasonEndTime) << "|";
	sstr << "mSwapBossTime:" << CTimeUtil::TimeString(mSwapBossTime) << "|";
	sstr << "mNextBossTime:" << CTimeUtil::TimeString(mNextBossTime) << "|";
	sstr << "mAttackStartTime:" << CTimeUtil::TimeString(mAttackStartTime) << "|";
	sstr << "mAttackEndTime:" << CTimeUtil::TimeString(mAttackEndTime) << "|";
	sstr << "mRewardCalcTime:" << CTimeUtil::TimeString(mRewardCalcTime);
	
	return sstr.str();
}

std::string BOSS_ATTRIBUTE::debugStr()
{
	std::stringstream sstr;
	sstr << "hp=" << hp<< "|";
	sstr << "hpmax=" << hpmax << "|";
	sstr << "totalhurt=" << totalhurt;
	return sstr.str();
}

void WORLD_BOSS_UNIT::reset()
{
	memset(this, 0, sizeof(WORLD_BOSS_UNIT));
}

std::string WORLD_BOSS_UNIT::debugStr()
{
	std::stringstream sstr;
	sstr << "mIndex=" << mIndex<< "|";
	sstr << "mSeason=" << mSeason << "|";
	sstr << "mBornTime:" << CTimeUtil::TimeString(mBornTime) << "|";
	sstr << "mUpdateTime:" << CTimeUtil::TimeString(mUpdateTime) << "|";
	sstr << "mBossID=" << mBossID << "|";
	sstr << "mGenerations=" << mGenerations << "|";
	sstr << "mAttr:" << mAttr.debugStr() << "|";
	sstr << "mIsAlive=" << mIsAlive;
	return sstr.str();
}

CWorldBossRealTime::CWorldBossRealTime()
{
	mInited = false;
}

bool CWorldBossRealTime::init(const SEASON_TIME_INFO &tInfo, const char* mapfile, int resetTime, int resetBoss)
{
	mMapFilePath = mapfile;
	int isnew = 0;
	bool format = false;
	size_t memSize = sizeof(WORLD_BOSS_RT_INFO);
	int ret = mMmap.map(mMapFilePath.c_str(), memSize, isnew);
	if(ret != 0)
	{
		LOG(LOG_ERROR, "m_mmap(file=%s) %s", mMapFilePath.c_str(), mMmap.errmsg());
		return false;
	}

	if(isnew == 1)
		format = true;
	char* memStart = mMmap.get_mem();

	mWBRTInfo = (WORLD_BOSS_RT_INFO*)memStart;

	if( format )
	{
		mWBRTInfo->format(tInfo);
	}
	else
	{
		if( resetTime )
		{
			mWBRTInfo->resetTime(tInfo);
		}
		if( resetBoss )
		{
			mWBRTInfo->resetBoss();
		}
	}

	mInited = true;

	return true;
}

SEASON_TIME_INFO &CWorldBossRealTime::seasonTime()
{
	return mWBRTInfo->seasonTime;
}

WORLD_BOSS_UNIT &CWorldBossRealTime::boss()
{
	return mWBRTInfo->boss;
}

time_t CWorldBossRealTime::getBeginTime()
{
	return mWBRTInfo->beginTime;
}