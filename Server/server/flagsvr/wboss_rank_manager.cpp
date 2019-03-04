#include "wboss_rank_manager.h"
#include "rank_wboss.h"
int CWBossRankManager::init(int format, int curSeason)
{
	deleteRankWrappers();

	int i = curSeason - 5;
	if( i < 1 )
	{
		i = 1;
	}
	int bossNum = 1;
	CRankWrapper *pRankWrapper = NULL;
	for( ; i <= curSeason; i++ )
	{
		pRankWrapper = new CRankWBoss(i);
		if( NULL == pRankWrapper )
		{
			LOG(LOG_ERROR, "FATAL NULL == pRankWrapper");
			return -1;
		}
		if( addRankWrapper(pRankWrapper) != 0 )
		{
			LOG(LOG_ERROR, "addRankWrapper failed");
			return -1;
		}
		if( format != 0 )
		{
			for( int j = 1; j <= bossNum; j++ )
				pRankWrapper->getCreateRankPool(j, true);
		}
	}

	return 0;
}

bool CWBossRankManager::clearRankList(int season, int bossIdx)
{
	CRankWrapper *pRankWrapper = getRankWrapper(season);
	if( NULL == pRankWrapper )
	{
		return false;
	}
	pRankWrapper->getCreateRankPool(bossIdx, true);
	return true;
}

bool CWBossRankManager::isWBossRankExists( int season )
{
	CRankWrapper *pRankWrapper = getRankWrapper(season);
	if( NULL == pRankWrapper )
	{
		return false;
	}
	return true;
}

bool CWBossRankManager::getWBossRankList( int season, int bossIdx, RankItemList &rankList)
{
	if( getRankItemList(season, bossIdx, rankList) != 0 )
	{
		LOG(LOG_ERROR, "getRankItemList failed");
		return false;
	}
	return true;
}

bool CWBossRankManager::setWBossRankList(int season, int bossIdx, const RankItemList &rankList)
{
	CRankWrapper *pRankWrapper = getRankWrapper(season);
	if( NULL == pRankWrapper )
	{
		pRankWrapper = new CRankWBoss(season);
		if( NULL == pRankWrapper )
		{
			LOG(LOG_ERROR, "FATAL NULL == pRankWrapper");
			return false;
		}
		if( addRankWrapper(pRankWrapper) != 0 )
		{
			LOG(LOG_ERROR, "addRankWrapper failed");
			return false;
		}
	}

	CRankPoolWrapper *pPool= pRankWrapper->getCreateRankPool(bossIdx);
	if( NULL == pPool )
	{
		LOG(LOG_ERROR, "getCreateRankPool failed");
		return false;
	}
	pPool->clearPool();
	for( int i = 0; i < rankList.items_size(); i++ )
	{
		const RankItem &rankItem = rankList.items(i);
		if( pRankWrapper->addRankItem(rankItem) != 0 )
		{
			LOG(LOG_ERROR, "addRankItem failed");
			return false;
		}
	}
	return true;
}

bool CWBossRankManager::addWBossRankItem(int season, const RankItem &rankItem)
{
	CRankWrapper *pRankWrapper = getRankWrapper(season);
	if( NULL == pRankWrapper )
	{
		pRankWrapper = new CRankWBoss(season);
		if( NULL == pRankWrapper )
		{
			LOG(LOG_ERROR, "FATAL NULL == pRankWrapper");
			return false;
		}
		if( addRankWrapper(pRankWrapper) != 0 )
		{
			LOG(LOG_ERROR, "addRankWrapper failed");
			return false;
		}
	}

	if( pRankWrapper->addRankItem(rankItem) != 0 )
	{
		LOG(LOG_ERROR, "addRankItem failed");
		return false;
	}

	return true;
}

