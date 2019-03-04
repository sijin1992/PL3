#ifndef __WORLD_BOSS_MANAGER_H__
#define __WORLD_BOSS_MANAGER_H__

#include "ini/ini_file.h"
#include "proto/rank.pb.h"
#include "proto/worldboss.pb.h"
#include "world_boss_realtime.h"
#include "wboss_rank_manager.h"
#include "xml2lua/GBoss_conf.h"

//Generations����
//����BOSS�ܹ���������
class CWorldBossMgrConfig
{
public:
	bool read_from_ini(CIniFile& oIni, const char* sector, int resetTime = 0, int resetBoss = 0);
	CWorldBossMgrConfig();
public:
	int season;
	time_t openTime;
	char mmapFile[256];
	int resetTime; //��ʽ���ӵ�һ����ʼ
	int resetBoss;	//����BOSS

	int seasonEndHour;	//��������Сʱ
	int seasonEndMin;	//����������
	int swapBossHour;	//BOSS����Сʱ
	int swapBossMin;	//BOSS�����
	int attackStartHour;	//������ʼСʱ
	int attackStartMin;		//������ʼ��
	int attackEndHour;		//��������Сʱ
	int attackEndMin;		//����������
	int rewardCalcHour;		//��������Сʱ
	int rewardCalcMin;		//���������
	int firstBossGen;		//����BOSS����
};

//����BOSS�ܹ�������
class CWorldBossManager
{
public:
	CWorldBossManager();
	~CWorldBossManager();
	bool init(const CWorldBossMgrConfig &config);
	bool init(const CWorldBossMgrConfig &config, int resetTime, int resetBoss = 0);

	//��ȡ��ǰBOSS��Ϣ
	int getCurBossInfo(WorldBossInfo &bossInfo);
	//��ȡ��ǰ���а�
	int getCurBossRank(RankItemList &rankList);
	//��ȡ��һBOSS���а�
	int getBossRank(const WBossHeadInfo &bossHead, RankItemList &rankList);
	//����BOSS,isTerminate�Ƿ��ս�,����>=0��ʾʣ��Ѫ��,<0��ʾ����
	long long attackBoss(WBossAttackInfo &atkInfo, bool &isTerminate);
	//��ȡ����
	bool update(time_t nowTime);
	
public:
	//����BOSS��
	bool updateSeason(time_t nowTime);
	//����BOSS��
	bool swapToSeason(time_t nowTime, int season);
	//�������а�
	bool swapRank(time_t nowTime);
	//����BOSS
	bool swapBoss(time_t nowTime, int idx = 1);
	//���㽱��
	bool calcReward(time_t nowTime);

	void onSeasonStart(time_t nowTime);

	void onSeasonEnd(time_t nowTime);

	void calcSeasonTime(time_t nowTime, SEASON_TIME_INFO &seasonTime);
	//���㵱ǰ��
	int calcCurSeason(time_t nowTime);
public:
	bool mInit;
	SEASON_TIME_INFO mSeasonTime;
	CWorldBossMgrConfig mConfig;
	CWorldBossRealTime mRealTime;
	CWBossRankManager mRankMgr;
};


#endif 

