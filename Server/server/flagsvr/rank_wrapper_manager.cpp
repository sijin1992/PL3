#include "rank_wrapper_manager.h"

CRankWrapperManager::~CRankWrapperManager()
{
	deleteRankWrappers();
}

void CRankWrapperManager::deleteRankWrappers()
{
	RankWrapperMap::iterator it = mRankWrapperMap.begin();
	RankWrapperMap::iterator itEnd = mRankWrapperMap.end();
	while( it != itEnd )
	{
		delete it->second;
		it++;
	}
	mRankWrapperMap.clear();
}

int CRankWrapperManager::init(int format)
{
	return 0;
}

int CRankWrapperManager::update(time_t time)
{
	RankWrapperMap::iterator it = mRankWrapperMap.begin();
	RankWrapperMap::iterator itEnd = mRankWrapperMap.end();
	while( it != itEnd )
	{
		if( it->second->update(time) != 0 )
		{
			return -1;
		}
		it++;
	}
	return 0;
}

int CRankWrapperManager::addRankItem(const RankItem &rankItem)
{
	int rankType = rankItem.ranktype();
	CRankWrapper *pRankWrapper = getRankWrapper(rankType);
	if( NULL == pRankWrapper )
	{
		return -1;
	}
	return pRankWrapper->addRankItem(rankItem);
}

int CRankWrapperManager::getRankItem(int rankType, int rankID, int index, RankItem &rankItem)
{
	CRankWrapper *pRankWrapper = getRankWrapper(rankType);
	if( NULL == pRankWrapper )
	{
		return -1;
	}
	return pRankWrapper->getRankItem(rankID, index, rankItem);
}

int CRankWrapperManager::getRankItemList(int rankType, int rankID, RankItemList &rankList)
{
	CRankWrapper *pRankWrapper = getRankWrapper(rankType);
	if( NULL == pRankWrapper )
	{
		LOG(LOG_ERROR, "getRankWrapper(rankType:%d) failed", rankType);
		return -1;
	}
	int size = pRankWrapper->getRankListSize(rankID);
	int rankStart = 0;
	int rankEnd = size;
	//LOG(LOG_ERROR, "rankID:%d, size:%d", rankID, size);
	rankList.set_totalranksize(size);
	if( rankList.has_rankstart() || rankList.has_rankcount() )
	{
		rankStart = rankList.rankstart();
		if( rankStart >= size )
		{
			//LOG(LOG_ERROR, "start:%d >= size:%d ", rankStart, size);
			return 0;
		}
		rankEnd = rankStart + rankList.rankcount();
		if( rankEnd > size )
		{
			rankEnd = size;
		}
	}
	int begin = 0;
	USER_NAME tarName;
	bool needTarUser = rankList.has_taruser() && !rankList.taruser().empty();
	if( needTarUser )
	{	
		tarName.from_str(rankList.taruser());
		begin = 0;
	}
	else if( size > rankEnd )
	{
		size = rankEnd;
	}
	//LOG(LOG_ERROR, "begin:%d, size:%d, rankStart:%d, rankEnd:%d ", begin, size, rankStart, rankEnd);
	bool found = false;
	for( int i = begin; i < size; i++ )
	{
		RankItem rankItem;
		pRankWrapper->getRankItem(rankID, i, rankItem);
		if( needTarUser && !found )
		{
			USER_NAME name;
			name.from_str(rankItem.user());
			//LOG(LOG_ERROR, "name:%s, tarname:%s", name.to_str().c_str(), tarName.to_str().c_str());
			if( name == tarName )
			{
				rankList.set_taruserrank(i+1);
				found = true;
			}
		}
		if( i >= rankStart && i < rankEnd )
		{
			RankItem *pRankItem = rankList.add_items();
			pRankItem->CopyFrom(rankItem);
		}
	}
	if( needTarUser && !found )
	{
		rankList.set_taruserrank(-size);
	}
	
	return 0;
}


int CRankWrapperManager::addRankWrapper(CRankWrapper *rankWrapper)
{
	if( rankWrapper->init() != 0 )
	{
		LOG(LOG_ERROR, "rankWrapper init failed rankType:%d", rankWrapper->getRankType());
		return -1;
	}
	std::pair<RankWrapperMap::iterator, bool> ret = mRankWrapperMap.insert(std::make_pair(rankWrapper->getRankType(), rankWrapper));
	if( !ret.second )
	{
		LOG(LOG_ERROR, "insert failed, rank type:%d", rankWrapper->getRankType());
		return -1;
	}
	return 0;
}

CRankWrapper *CRankWrapperManager::getRankWrapper(int rankType)
{
	RankWrapperMap::iterator it = mRankWrapperMap.find(rankType);
	if( it == mRankWrapperMap.end() )
	{
		return NULL;
	}
	return it->second;
}
