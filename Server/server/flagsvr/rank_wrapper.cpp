#include "rank_wrapper.h"
#include "flag_svr_def.h"

CRankWrapper::CRankWrapper()
{
	mUseExtMode = false;
	mStable = true;
	mRankOrder = RO_DES;
}

CRankWrapper::~CRankWrapper()
{
	clearAllPools();
}

int CRankWrapper::addRankItem(const RankItem &rankItem)
{
	int rankID = rankItem.rankid();
	CRankPoolWrapper *pWrapper = getCreateRankPool(rankID);
	if( NULL == pWrapper || !pWrapper->isInited() )
	{
		LOG(LOG_ERROR, "NULL == pWrapper || !pWrapper->isInited(), rankID:%d, pWrapper:%p", rankID, pWrapper);
		return -1;
	}
	USER_NAME userName;
	userName.from_str(rankItem.user());
	int rankOp = rankItem.rankop();
	if( rankOp == RO_DEL )
	{
		pWrapper->removeUnit(userName);
	}
	else
	{
		RankExtData extData;
		extData.CopyFrom(rankItem.extdata());
		pWrapper->addUnit(userName, rankItem.key(), &extData);
	}
	return 0;
}

int CRankWrapper::getRankItem(int rankID, int index, RankItem &rankItem)
{
	CRankPoolWrapper *pWrapper = getCreateRankPool(rankID);
	if( NULL == pWrapper || !pWrapper->isInited() )
	{
		LOG(LOG_ERROR, "NULL == pWrapper || !pWrapper->isInited(), pWrapper:%p", pWrapper);
		return -1;
	}
	
	return getRankItem(*pWrapper, index, rankItem);
}

int CRankWrapper::getRankItem(CRankPoolWrapper &rankPoolWrapper, int index, RankItem &rankItem)
{
	void *pUnit = rankPoolWrapper.getUnit(index);
	if( NULL == pUnit )
	{
		LOG(LOG_ERROR, "pWrapper->getUnit(index:%d) failed", index);
		return -1;
	}
	rankItem.set_rankid(rankPoolWrapper.getRankID());
	rankItem.set_ranktype(mRankType);
	if( rankPoolWrapper.isExtMode() )
	{
		EXT_RANK_UNIT *pExtUnit = static_cast<EXT_RANK_UNIT*>(pUnit);
		rankItem.set_user(pExtUnit->user.to_str());
		rankItem.set_key(pExtUnit->key);
		rankItem.mutable_extdata()->ParseFromArray(pExtUnit->extdata, pExtUnit->extlen);
	}
	else
	{
		RANK_UNIT *pNomUnit = static_cast<RANK_UNIT*>(pUnit);
		rankItem.set_user(pNomUnit->user.to_str());
		rankItem.set_key(pNomUnit->key);
	}

	return 0;
}

int CRankWrapper::getRankItem(int rankID, const USER_NAME &user, RankItem &rankItem)
{
	CRankPoolWrapper *pWrapper = getCreateRankPool(rankID);
	if( NULL == pWrapper || !pWrapper->isInited() )
	{
		LOG(LOG_ERROR, "NULL == pWrapper || !pWrapper->isInited(), pWrapper:%p", pWrapper);
		return -1;
	}
	
	int unitSize = pWrapper->getUnitSize();
	RankItem tempRank;
	USER_NAME tempUser;
	for( int i = 0; i < unitSize; i++ )
	{
		if( getRankItem(*pWrapper, i, tempRank) != 0 )
		{
			LOG(LOG_ERROR, "getRankItem failed, index:%d", i);
			return -1;
		}
		tempUser.from_str(tempRank.user());
		if( user == tempUser )
		{
			rankItem.CopyFrom(tempRank);
			return 0;
		}
	}

	//LOG(LOG_ERROR, "user:%s not found in rankName:%s rankID:%d", user.str(), mRankName.c_str(), rankID);
	return -1;
}

CRankPoolWrapper *CRankWrapper::getRankPool(int rankID)
{
	RankPoolMap::iterator it = mRankPools.find(rankID);
	if( it == mRankPools.end() )
	{
		return NULL;
	}
	return it->second;
}
void CRankWrapper::addRankPool(CRankPoolWrapper *pool)
{
	if( NULL == pool )
	{
		return;
	}
	mRankPools.insert(std::make_pair(pool->getRankID(), pool));
}

int CRankWrapper::getRankListSize(int rankID)
{
	CRankPoolWrapper *pWrapper = getCreateRankPool(rankID);
	if( NULL == pWrapper )
	{
		return 0;
	}
	return pWrapper->getUnitSize();
}

CRankPoolWrapper *CRankWrapper::getCreateRankPool(int rankID, bool format)
{
	CRankPoolWrapper *pWrapper = getRankPool(rankID);
	if( NULL == pWrapper )
	{
		pWrapper = new CRankPoolWrapper(mRankName, rankID, mRankMaxSize, mUseExtMode);
		pWrapper->setOrder(mRankOrder);
		pWrapper->setStable(mStable);
		pWrapper->setFormat(format);
		pWrapper->init();
		addRankPool(pWrapper);
	}
	else if(format)
	{
		pWrapper->clearPool();
	}
	if( !pWrapper->isInited() )
	{
		return NULL;
	}
	
	return pWrapper;
}

void CRankWrapper::clearAllPools(bool clearData)
{
	RankPoolMap::iterator it = mRankPools.begin();
	RankPoolMap::iterator itEnd = mRankPools.end();
	while( it != itEnd )
	{
		CRankPoolWrapper *pPool = it->second;
		it++;
		if( clearData )
		{
			pPool->clearPool();
		}
		delete pPool;
	}
	mRankPools.clear();
}
