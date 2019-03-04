#include "world_boss_manager.h"
#include "time/time_util.h"
#include "log/log.h"
#include "lua_global_wrap.h"

#define TIME_SEC_ADVANCE 0

bool CWorldBossMgrConfig::read_from_ini( CIniFile& oIni, const char* sector, int resetTime, int resetBoss)
{
	if(oIni.GetInt(sector, "SEASON", 1, &season) != 0 )
	{
		LOG(LOG_ERROR, "%s.SEASON not found", sector);
		//return false;
	}
	char tempBuff[256]= "";
	if(oIni.GetString(sector, "OPEN_TIME", "2015-3-16", tempBuff, sizeof(tempBuff)) != 0 )
	{
		LOG(LOG_ERROR, "%s.OPEN_TIME not found", sector);
		//return false;
	}
	openTime = CTimeUtil::FromTimeString(tempBuff);
	

	if(oIni.GetString(sector, "MMAPFILE_PATH", "worldboss.mmap", mmapFile, sizeof(mmapFile))!= 0)
	{
		LOG(LOG_ERROR, "%s.MMAPFILE_PATH not found", sector);
		//return false;
	}

	firstBossGen = luaGlobal().getGlobalInt("wboss_first_gen");
	if( firstBossGen < 1 )
	{
		firstBossGen = 1;
	}

	LOG(LOG_ERROR, "season:%d firstBossGen:%d openTime:%ld, timeStr:%s", season, firstBossGen, openTime, tempBuff);
	
	this->resetTime = resetTime;
	this->resetBoss = resetBoss;

	seasonEndHour = 23; //晚上11点
	seasonEndMin = 59;	//59分

	//Boss更变时间
	swapBossHour = 0;	//BOSS更变小时
	swapBossMin = 0;	//BOSS更变分

	//攻打BOSS结束时间
	attackStartHour = 0;//早上0点
	attackStartMin = 0;	//0分
	
	//攻打BOSS结束时间
	attackEndHour = 22;	//晚上8点
	attackEndMin = 0;	//0分

	//奖励结算时间;	
	rewardCalcHour = 22;	//晚上8点
	rewardCalcMin = 1;		//1分
	return true;
}

CWorldBossMgrConfig::CWorldBossMgrConfig()
{

}


CWorldBossManager::CWorldBossManager()
{

}

CWorldBossManager::~CWorldBossManager()
{

}

bool CWorldBossManager::init(const CWorldBossMgrConfig &config)
{
	return init(config, config.resetTime, config.resetBoss);
}

bool CWorldBossManager::init(const CWorldBossMgrConfig &config, int resetTime, int resetBoss)
{
	mConfig = config;
	time_t nowTime = time(NULL) + TIME_SEC_ADVANCE;
	if( nowTime < mConfig.openTime )
	{
		return true;
	}
	srand(nowTime);

	calcSeasonTime(nowTime, mSeasonTime);
	if( mSeasonTime.mCurSeason < 0 )
	{
		LOG(LOG_ERROR, "invalid mCurSeason nowTime:%s, SeasonTime:%s", CTimeUtil::TimeString(nowTime).c_str(), mSeasonTime.debugStr().c_str());
		return false;
	}
	LOG(LOG_ERROR, "calcSeasonTime nowTime:%s, SeasonTime:%s", CTimeUtil::TimeString(nowTime).c_str(), mSeasonTime.debugStr().c_str());
	if( !mRealTime.init(mSeasonTime, mConfig.mmapFile, resetTime, resetBoss) )
	{
		LOG(LOG_ERROR, "mRealTime.init failed");
		return false;
	}
	
	mSeasonTime = mRealTime.seasonTime();
	LOG(LOG_ERROR, "init RealTimeBegin:%s SeasonTime:%s", 
		CTimeUtil::TimeString(mRealTime.getBeginTime()).c_str(), mSeasonTime.debugStr().c_str());
	LOG(LOG_ERROR, "init Boss:%s", mRealTime.boss().debugStr().c_str());
	if( mRankMgr.init(resetBoss, mSeasonTime.mCurSeason) != 0 )
	{
		LOG(LOG_ERROR, "mRankMgr.init failed");
		return false;
	}

	mInit = true;

	return true;
}

//获取当前BOSS信息
int CWorldBossManager::getCurBossInfo(WorldBossInfo &bossInfo)
{
	WBossHeadInfo &headInfo = *bossInfo.mutable_head_info();
	WBossAttrInfo &attrInfo = *bossInfo.mutable_attr_info();
	const WORLD_BOSS_UNIT &boss = mRealTime.boss();
	headInfo.set_boss_id(boss.mBossID);
	headInfo.set_boss_season(boss.mSeason);
	headInfo.set_boss_generations(boss.mGenerations);
	headInfo.set_boss_index(boss.mIndex);

	attrInfo.set_cur_hp(boss.mAttr.hp);
	attrInfo.set_max_hp(boss.mAttr.hpmax);

	bossInfo.set_is_alive(boss.mIsAlive?1:0);
	bossInfo.set_reward_calc_time(mSeasonTime.mRewardCalcTime);
	bossInfo.set_attack_start_time(mSeasonTime.mAttackStartTime);
	bossInfo.set_attack_end_time(mSeasonTime.mAttackEndTime);
	bossInfo.set_next_boss_time(mSeasonTime.mNextBossTime);
	
	return 0;
}

//获取排行榜
int CWorldBossManager::getCurBossRank(RankItemList &rankList)
{
	const WORLD_BOSS_UNIT &boss = mRealTime.boss();
	if( !mRankMgr.getWBossRankList(boss.mSeason, boss.mIndex, rankList) )
	{
		LOG(LOG_ERROR, "getWBossRankList failed, boss.mSeason:%d, boss.mIndex:%d", boss.mSeason, boss.mIndex);
		return -1;
	}
	return 0;
}

int CWorldBossManager::getBossRank(const WBossHeadInfo &bossHead, RankItemList &rankList)
{
	if( !mRankMgr.isWBossRankExists(bossHead.boss_season()) )
	{
		return 1;
	}
	if( !mRankMgr.getWBossRankList(bossHead.boss_season(), bossHead.boss_index(), rankList) )
	{
		LOG(LOG_ERROR, "getWBossRankList failed, boss_season:%d, boss_index:%d", bossHead.boss_season(), bossHead.boss_index());
		return -1;
	}
	return 0;
}

//攻打BOSS
long long CWorldBossManager::attackBoss(WBossAttackInfo &atkInfo, bool& isTeminated)
{
	time_t atkTime = atkInfo.time();
	int damage = atkInfo.damage();
	int totalDamage = atkInfo.total_damage();
	WORLD_BOSS_UNIT &boss = mRealTime.boss();
	if( totalDamage < 0 ) //伤害无效
	{
		return -4;
	}
	if( boss.mBossID == 0 ) //BOSS不存在
	{
		return -1;
	}
	if( !boss.mIsAlive  )  //BOSS已经死亡
	{
		return -2;
	}
	if( atkTime > mSeasonTime.mAttackEndTime || atkTime <= mSeasonTime.mAttackStartTime ) //不在挑战时间内
	{
		//测试时 无视时间段
		return -3;
	}
	long long curHp = boss.mAttr.hp;
	isTeminated = curHp > 0 && curHp <= damage;
	curHp -= damage;
	if( curHp <= 0 )
	{
		curHp = 0;
		boss.mIsAlive = false;
	}
	boss.mAttr.hp = curHp;
	boss.mAttr.totalhurt += damage;

	//排名

	RankItem rankItem;
	rankItem.set_user(atkInfo.user_name());
	rankItem.set_rankid(boss.mIndex);
	rankItem.set_ranktype(boss.mSeason);
	rankItem.set_key(totalDamage);

	RankExtData &extData =*rankItem.mutable_extdata();
	RankPlayerInfo &playerInfo = *extData.mutable_playerinfo();
	playerInfo.set_nickname(atkInfo.nick_name());
	playerInfo.set_rolelevel(atkInfo.level());
	playerInfo.set_viplevel(atkInfo.viplv());
	playerInfo.set_power(atkInfo.power());

	mRankMgr.addWBossRankItem(boss.mSeason, rankItem);
	return curHp;
}

bool CWorldBossManager::updateSeason(time_t nowTime)
{
	if( nowTime < mConfig.openTime )
	{
		return true;
	}
	int season = calcCurSeason(nowTime);
	//更变赛季
	if( season != mSeasonTime.mCurSeason )
	{
		if( !swapToSeason(nowTime, season) )
		{
			return false;
		}
	}
	//更变BOSS
	if( mSeasonTime.mSwapBossTime > 0 && nowTime > mSeasonTime.mSwapBossTime )
	{
		if( !swapBoss(nowTime) )
		{
			return false;
		}
		mSeasonTime.mSwapBossTime = 0;
		mRealTime.seasonTime().mSwapBossTime = 0;
	}
	//赛季结束了
	if( mSeasonTime.mSeasonEndTime > 0 && nowTime > mSeasonTime.mSeasonEndTime )
	{
		//赛季结束
		onSeasonEnd(nowTime);
		mSeasonTime.mSeasonEndTime = 0;
		mRealTime.seasonTime().mSeasonEndTime = 0;
	}
	return true;
}



bool CWorldBossManager::update(time_t nowTime)
{
	nowTime = nowTime + TIME_SEC_ADVANCE;
	updateSeason(nowTime);
	return true;
}


bool CWorldBossManager::swapToSeason(time_t nowTime, int season)
{
	if( mSeasonTime.mCurSeason == season )
	{
		return true;
	}
	LOG(LOG_INFO, "curSeason:%d, swapToSeason:%d", mSeasonTime.mCurSeason, season);
	//clear

	//init
	if( !init(mConfig, 1) )
	{
		return false;
	}

	onSeasonStart(nowTime);

	return true;
}

//更变排行榜
bool CWorldBossManager::swapRank(time_t nowTime)
{
	return true;
}

//更变BOSS
bool CWorldBossManager::swapBoss(time_t nowTime, int idx)
{
	//清除排行
	swapRank(nowTime);
	
	WORLD_BOSS_UNIT &boss = mRealTime.boss();
	int generations = boss.mGenerations; //初始世代
	int bossID = 0;
	const char *swapType = "New";
	GBoss_data data;
	const int first_boss_gen = mConfig.firstBossGen; //初始BOSS代
	
	if( boss.mBossID == 0 || !boss.mIsAlive) //没有BOSS或者BOSS已经死掉，生成新的BOSS
	{
		boss.mBornTime = nowTime;
		if( boss.mBossID != 0 )
		{
			swapType = "Swap";
			//找下一代
			if( !data.get_data_by_idx(generations + 1) && !data.get_data_by_idx(generations) )
			{
				LOG(LOG_ERROR, "get_data_by_idx failed, generations:%d", generations);
				return false;
			}
		}
		else if( !data.get_data_by_idx(first_boss_gen) ) //初代
		{
			LOG(LOG_ERROR, "get_data_by_idx failed, generations:%d", first_boss_gen);
			return false;
		}
	}
	else //BOSS没被击杀
	{
		boss.mUpdateTime = nowTime;
		if( !data.get_data_by_idx(generations) )
		{
			LOG(LOG_ERROR, "get_data_by_idx failed, generations:%d", generations);
			return false;
		}
		swapType = "Update";
	}

	generations = data.Index;
	bossID = data.Stage_ID;

	if( bossID == 0 )
	{
		LOG(LOG_ERROR, "generations:%d bossID == 0", generations);
		return false;
	}

	//更新属性
	boss.mGenerations = generations;
	boss.mBossID = bossID;
	boss.mSeason = mSeasonTime.mCurSeason;
	boss.mIndex = idx;

	long long maxHp = data.Boss_Life;

	boss.mAttr.hpmax = maxHp;
	boss.mAttr.hp = boss.mAttr.hpmax;
	boss.mAttr.totalhurt = 0;
	boss.mIsAlive = true;

	LOG(LOG_ERROR, "BOSS SWAP Type:%s Generations:%d BossID:%d, TotalHP:%lld", swapType, generations, bossID, maxHp);
	LOG(LOG_ERROR, "SWAP Boss:%s", boss.debugStr().c_str());
	return true;
}

//结算奖励
bool CWorldBossManager::calcReward(time_t nowTime)
{
	return true;
}

void CWorldBossManager::onSeasonStart(time_t nowTime)
{
	//清除排行榜
	LOG(LOG_INFO, "PVP|SEASON|%d|START SUCCESS", mSeasonTime.mCurSeason);
}

void CWorldBossManager::onSeasonEnd(time_t nowTime)
{
	//赛季结束
	LOG(LOG_INFO, "PVP|SEASON|%d|END SUCCESS", mSeasonTime.mCurSeason);
}

void CWorldBossManager::calcSeasonTime(time_t nowTime, SEASON_TIME_INFO &seasonTime)
{
#define SEC_OF_MIN 60
#define SEC_OF_HOUR 60 * SEC_OF_MIN
#define SEC_OF_DAY 24 * SEC_OF_HOUR

	int season = calcCurSeason(nowTime);
	time_t dayBeginTime = CTimeUtil::NextDayTime(nowTime) - SEC_OF_DAY;

	seasonTime.mCurSeason = season;
	seasonTime.mSeasonStartTime = dayBeginTime;
	seasonTime.mSwapBossTime = dayBeginTime + mConfig.swapBossHour * SEC_OF_HOUR + mConfig.swapBossMin * SEC_OF_MIN;
	seasonTime.mNextBossTime = seasonTime.mSwapBossTime + SEC_OF_DAY;

	seasonTime.mAttackStartTime = dayBeginTime + mConfig.attackStartHour * SEC_OF_HOUR + mConfig.attackStartMin * SEC_OF_MIN;
	seasonTime.mAttackEndTime = dayBeginTime + mConfig.attackEndHour * SEC_OF_HOUR + mConfig.attackEndMin * SEC_OF_MIN;
	seasonTime.mRewardCalcTime = dayBeginTime + mConfig.rewardCalcHour * SEC_OF_HOUR + mConfig.rewardCalcMin * SEC_OF_MIN;
	seasonTime.mSeasonEndTime = dayBeginTime + mConfig.seasonEndHour * SEC_OF_HOUR + mConfig.seasonEndMin * SEC_OF_MIN;

}

int CWorldBossManager::calcCurSeason(time_t nowTime)
{
	return mConfig.season + CTimeUtil::DayDiff(mConfig.openTime, nowTime);
}

