#include "rank_pool_wrapper.h"
#include <sstream>
CRankPoolWrapper::CRankPoolWrapper(const std::string &preName, int rankID, int poolSize, bool extMode)
{
	mPreName = preName;
	mRankID = rankID;
	mPoolSize = poolSize;
	mIsInited = false;
	mExtMode = extMode;
	mOrder = RO_DES;
	mFormat = false;
}

int CRankPoolWrapper::init()
{
	std::stringstream filestr;
	filestr << mPreName;
	filestr << "_";
	filestr << mRankID;
	filestr << ".mmap";
	mFileName = filestr.str();
	const char *file = mFileName.c_str();
	if( mExtMode )
	{
		if(mPool.ext_init2(file, mPoolSize, mFormat?1:0, (mOrder==RO_ASC)?1:0) !=0)
		{
			LOG(LOG_ERROR, "mPool.ext_init(%s, %d) fail", file, mPoolSize);
			return -1;
		}
	}
	else
	{
		if(mPool.init(file, mPoolSize, mFormat?1:0, (mOrder==RO_ASC)?1:0)!=0)
		{
			LOG(LOG_ERROR, "mPool.init(%s, %d) fail", file, mPoolSize);
			return -1;
		}
	}
	mIsInited = true;
	return 0;
}

void CRankPoolWrapper::setOrder(RankOrder order)
{
	mOrder = order;
}

void CRankPoolWrapper::setFormat(bool format)
{
	mFormat = format;
}

void CRankPoolWrapper::setStable(bool stable)
{
	mPool.set_stable(stable);
}

void CRankPoolWrapper::addUnit( USER_NAME& user, int key, RankExtData *pExtData)
{
	if( !isInited() )
	{
		return;
	}
	if( mExtMode )
	{
		mPool.add_unit_ext(user, key, pExtData);
	}
	else
	{
		mPool.add_unit(user, key);
	}
}

int CRankPoolWrapper::getUnitSize()
{
	if( !isInited() )
	{
		return 0;
	}
	return mPool.size();
}

void* CRankPoolWrapper::getUnit( int index )
{
	if( !isInited() )
	{
		return NULL;
	}
	if( mExtMode )
	{
		return mPool.val_ext(index);
	}
	else
	{
		return mPool.val(index);
	}
}

int CRankPoolWrapper::removeUnit( USER_NAME& user )
{
	if( !isInited() )
	{
		return -1;
	}
	if( mExtMode )
	{
		return mPool.remove_unit_ext(user);
	}
	else
	{
		return mPool.remove_unit(user);
	}
}

void CRankPoolWrapper::clearPool()
{
	mPool.clear();
}

