#ifndef __RANK_WRAPPER_H__
#define __RANK_WRAPPER_H__
#include "rank_pool_wrapper.h"
#include "../common/msg_define.h"

class CRankWrapper
{
public:
	CRankWrapper();
	virtual ~CRankWrapper();
	virtual int init() = 0;
	virtual int update(time_t time) = 0;
	virtual int addRankItem(const RankItem &rankItem);
	virtual int getRankItem(int rankID, int index, RankItem &rankItem);
	virtual int getRankItem(CRankPoolWrapper &rankPoolWrapper, int index, RankItem &rankItem);
	virtual int getRankItem(int rankID, const USER_NAME &user, RankItem &rankItem);
	virtual int getRankListSize(int rankID);
	inline int getRankType(){ return mRankType; }
	CRankPoolWrapper *getCreateRankPool(int rankID, bool format = false);
	CRankPoolWrapper *getRankPool(int rankID);
	virtual void addRankPool(CRankPoolWrapper *pool);
	void clearAllPools(bool clearData = false);
	void clearPoolsData();

protected:
	int mRankType;
	int mRankMaxSize;
	RankPoolMap mRankPools;
	std::string mRankName;
	bool mUseExtMode;
	bool mStable;
	RankOrder mRankOrder;

};


#endif

