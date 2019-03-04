#ifndef __WBOSS_RANK_MANAGER_H__
#define __WBOSS_RANK_MANAGER_H__
#include "rank_wrapper_manager.h"

class CWBossRankManager: public CRankWrapperManager
{
public:
	int init(int format, int curSeason);
	bool clearRankList(int season, int bossIdx);
	bool isWBossRankExists(int season);
	bool getWBossRankList(int season, int bossIdx, RankItemList &rankList);
	bool setWBossRankList(int season, int bossIdx, const RankItemList &rankList);
	bool addWBossRankItem(int season, const RankItem &rankItem);
};


#endif

