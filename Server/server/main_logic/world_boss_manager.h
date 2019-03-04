#ifndef __WORLD_BOSS_MANAGER_H__
#define __WORLD_BOSS_MANAGER_H__

#include "ini/ini_file.h"
#include "proto/rank.pb.h"
#include "proto/worldboss.pb.h"
#include "world_boss_realtime.h"
#include "wboss_rank_manager.h"
#include "xml2lua/GBoss_conf.h"

//Generations世代
//世界BOSS总管理器配置
class CWorldBossMgrConfig
{
public:
	bool read_from_ini(CIniFile& oIni, const char* sector, int resetTime = 0, int resetBoss = 0);
	CWorldBossMgrConfig();
public:
	int season;
	time_t openTime;
	char mmapFile[256];
	int resetTime; //格式化从第一代开始
	int resetBoss;	//重置BOSS

	int seasonEndHour;	//赛季结束小时
	int seasonEndMin;	//赛季结束分
	int swapBossHour;	//BOSS更变小时
	int swapBossMin;	//BOSS更变分
	int attackStartHour;	//进攻开始小时
	int attackStartMin;		//进攻开始分
	int attackEndHour;		//进攻结束小时
	int attackEndMin;		//进攻结束分
	int rewardCalcHour;		//奖励结算小时
	int rewardCalcMin;		//奖励结算分
	int firstBossGen;		//初代BOSS代数
};

//世界BOSS总管理器配
class CWorldBossManager
{
public:
	CWorldBossManager();
	~CWorldBossManager();
	bool init(const CWorldBossMgrConfig &config);
	bool init(const CWorldBossMgrConfig &config, int resetTime, int resetBoss = 0);

	//获取当前BOSS信息
	int getCurBossInfo(WorldBossInfo &bossInfo);
	//获取当前排行榜
	int getCurBossRank(RankItemList &rankList);
	//获取任一BOSS排行榜
	int getBossRank(const WBossHeadInfo &bossHead, RankItemList &rankList);
	//攻打BOSS,isTerminate是否终结,返回>=0表示剩余血量,<0表示出错
	long long attackBoss(WBossAttackInfo &atkInfo, bool &isTerminate);
	//获取奖励
	bool update(time_t nowTime);
	
public:
	//更新BOSS季
	bool updateSeason(time_t nowTime);
	//更变BOSS季
	bool swapToSeason(time_t nowTime, int season);
	//更变排行榜
	bool swapRank(time_t nowTime);
	//更变BOSS
	bool swapBoss(time_t nowTime, int idx = 1);
	//结算奖励
	bool calcReward(time_t nowTime);

	void onSeasonStart(time_t nowTime);

	void onSeasonEnd(time_t nowTime);

	void calcSeasonTime(time_t nowTime, SEASON_TIME_INFO &seasonTime);
	//计算当前季
	int calcCurSeason(time_t nowTime);
public:
	bool mInit;
	SEASON_TIME_INFO mSeasonTime;
	CWorldBossMgrConfig mConfig;
	CWorldBossRealTime mRealTime;
	CWBossRankManager mRankMgr;
};


#endif 

