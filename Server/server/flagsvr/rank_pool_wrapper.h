#ifndef __RANK_POOL_WRAPPER_H__
#define __RANK_POOL_WRAPPER_H__
#include "rank_pool.h"
#include <string>
#include <map>

enum RankOrder
{
	RO_DES = 0,
	RO_ASC = 1,
};

enum RankOperator
{
	RO_DEL = 1,
};

class CRankPoolWrapper
{
public:
	CRankPoolWrapper(const std::string &preName, int rankID, int poolSize, bool extMode = false);
	virtual ~CRankPoolWrapper(){ }
	virtual int init();
	void setOrder(RankOrder order);
	void setFormat(bool format);
	void setStable(bool stable);
	int getRankID(){ return mRankID; }
	bool isInited(){return mIsInited;}
	void addUnit(USER_NAME& user, int key, RankExtData *pExtData = NULL);
	int getUnitSize();
	void *getUnit(int index);
	int removeUnit(USER_NAME& user);
	std::string getFileName(){ return mFileName; }
	bool isExtMode(){ return mExtMode; }
	void clearPool();
protected:
	std::string mFileName;
	std::string mPreName;
	int mRankID;
	bool mIsInited;
	int mPoolSize;
	CRankPool mPool;
	bool mExtMode;
	RankOrder mOrder;
	bool mFormat;
};

typedef std::map<int, CRankPoolWrapper*> RankPoolMap;

#endif

