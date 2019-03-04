#ifndef __RANK_WRAPPER_MANAGER_H__
#define __RANK_WRAPPER_MANAGER_H__
#include "flag_svr_def.h"
#include "rank_wrapper.h"
#include <map>

typedef std::map<int, CRankWrapper *> RankWrapperMap;

class CRankWrapperManager
{
public:
	virtual ~CRankWrapperManager();
	void deleteRankWrappers();
	virtual int init(int fomat);
	int update(time_t time);
	int addRankItem(const RankItem &rankItem);
	int getRankItem(int rankType, int rankID, int index, RankItem &rankItem);
	int getRankItemList(int rankType, int rankID, RankItemList &rankList); 

	int addRankWrapper(CRankWrapper *rankWrapper);
	CRankWrapper *getRankWrapper(int rankType);
protected:
	
	RankWrapperMap mRankWrapperMap;

};


#endif

