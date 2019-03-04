#ifndef __RANK_ARENA_H__
#define __RANK_ARENA_H__
#include "rank_wrapper.h"

class CRankWBoss: public CRankWrapper
{
public:
	CRankWBoss(int season);
	int init();
	int update(time_t time){ return 0; }
protected:
	int mSeason;
};

#endif

