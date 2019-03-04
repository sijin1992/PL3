#include "rank_wboss.h"
#include <sstream>
CRankWBoss::CRankWBoss( int season )
{
	mUseExtMode = true;
	mSeason = season;
	mRankOrder = RO_DES;
}

int CRankWBoss::init()
{
	mRankType = mSeason;
	std::stringstream ss;
	ss << "RankBossSeason_";
	ss << mSeason;
	mRankName = ss.str();
	mRankMaxSize = 500;
	return 0;
}





