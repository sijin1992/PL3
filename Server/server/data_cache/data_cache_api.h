#ifndef __DATA_CACHE_API_H__
#define __DATA_CACHE_API_H__

#include "data_cache.h"
#include "logic/msg.h"
#include "logic/toolkit.h"
#include "log/log.h"

class CDataBlockSet
{
public:
	inline void make_get_req(int id, unsigned long long stamp=0, unsigned int lock=0)
	{
		m_theSet.Clear();
		add_get_req(id, stamp, lock);
	}
	
	inline void make_set_req(int id, bool unlock, char* buff, int len)
	{
		m_theSet.Clear();
		add_set_req(id, unlock, buff, len);
	}

	inline void make_set_req(int id, bool unlock, string* pbuff)
	{
		m_theSet.Clear();
		add_set_req(id, unlock, pbuff);
	}

	void add_get_req(int id,  unsigned int lock=0, unsigned long long stamp=0);
 	void add_set_req(int id, bool unlock, char* buff, int len);
	void add_set_req(int id, bool unlock, string* pbuff);
	inline void add_lock_get_and_set_req(int id)
	{
		DataBlock* pnewBlock =m_theSet.add_blocks();
		pnewBlock->set_id(id);
		pnewBlock->set_stamp(0);
		pnewBlock->set_lock(1);
		pnewBlock->set_unlock(1);
	}

	inline void save_only_result(bool fillFailResult=false)
	{
		m_theSet.clear_blocks();
		if(fillFailResult)
			m_theSet.set_result(m_theSet.FAIL);
	}

	inline void save_without_blockbuff()
	{
		for(int i=0; i<m_theSet.blocks_size(); ++i)
		{
			DataBlock* ptheBlock = m_theSet.mutable_blocks(i);
			ptheBlock->clear_buff();
		}
	}

	inline DataBlockSet& get_clear_obj()
	{
		m_theSet.Clear();
		return m_theSet;
	}
	
	inline DataBlockSet& get_obj()
	{
		return m_theSet;
	}

	inline void set_result(DataBlockSet::Result theResult)
	{
		m_theSet.set_result(theResult);
	}

	inline DataBlockSet::Result result()
	{
		if(m_theSet.has_result())
			return m_theSet.result();
		else
			return m_theSet.FAIL;
	}

	int get_block(int blockId, DataBlock*& pBlock);

	inline int begin()
	{
		return 0;
	}

	inline int end()
	{
		return m_theSet.blocks_size();
	}

	//false=end true=has more
	//pBlock=NULL，表示有错误
	inline bool fetch_block(int& theIt, int& blockId, DataBlock*& pBlock)
	{
		if(theIt < 0 || theIt >=m_theSet.blocks_size())
		{
			return false;
		}
		
		if( get_block(theIt++, blockId, pBlock) != 0)
		{
			pBlock = NULL;
		}

		return true;
	}

	int get_block(int it, int& blockId, DataBlock*& pBlock);
	
protected:
	DataBlockSet m_theSet;
};

class CDataCacheBase
{
	public:
		static const int OK = 0;
		static const int WOULD_BLOCK = 1; //需要走网络
		static const int FAIL = -1;

	CDataCacheBase()
	{
		m_pCache = NULL;
	}

	virtual ~CDataCacheBase()
	{
	}

	virtual int init(CDataCache* pLocalCache) = 0;
	
	protected:
		CDataCache* m_pCache;
		int m_state;
		CDataCacheLockPool m_lockpool;
};

class CDataCacheTmp:public CDataCacheBase
{
public:
	virtual int init(CDataCache* pLocalCache);

	virtual ~CDataCacheTmp()
	{
	}

	inline void del(USER_NAME& user)
	{
		if(!m_pCache)
		{
			LOG(LOG_ERROR, "not inited" );
		}
		m_pCache->del(user, NULL);
		//int ret = m_pCache->del(user, NULL);
//		LOG(LOG_INFO, "%s|DATA_CACHE_TMP|del|%d", user.str(), ret);
	}

	inline int get(USER_NAME& user, CDataBlockSet& theGetReq)
	{
		if(!m_pCache)
		{
			LOG(LOG_ERROR, "not inited" );
			return FAIL;
		}

		if( m_pCache->get_stamp(user, theGetReq.get_obj()) != m_pCache->RET_OK)
			return FAIL;
		return OK;
	}

	inline int on_set(USER_NAME& user, CDataBlockSet& theSetReq)
	{
		if(!m_pCache)
		{
			LOG(LOG_ERROR, "not inited" );
			return FAIL;
		}

		//去掉没有buff的请求
		DataBlockSet& theset = theSetReq.get_obj();
		for(int i=0; i<theset.blocks_size(); ++i)
		{
			if(!theset.blocks(i).has_buff())
			{
				if(i != theset.blocks_size()-1)
				{
					theset.mutable_blocks()->SwapElements(i, theset.blocks_size()-1);
				}

				theset.mutable_blocks()->RemoveLast();
				--i;
			}
		}
		
		if(m_pCache->update(user, theSetReq.get_obj(), m_lockpool) != m_pCache->RET_OK)
		{
//			LOG(LOG_INFO, "%s|DATA_CACHE_TMP|update|set|%d",user.str(),  -1);
			return FAIL;
		}
//		LOG(LOG_INFO, "%s|DATA_CACHE_TMP|update|set|%d", user.str(), 0);
		m_lockpool.clear();
		return OK;
	}

	inline int on_get(USER_NAME& user, CDataBlockSet& theGetResp)
	{
		if(!m_pCache)
		{
			LOG(LOG_ERROR, "not inited" );
			return FAIL;
		}
		if( m_pCache->update(user, theGetResp.get_obj(), m_lockpool) != m_pCache->RET_OK)
		{
//			LOG(LOG_INFO, "%s|DATA_CACHE_TMP|update|get|%d", user.str(), -1);
			return FAIL;
		}
//		LOG(LOG_INFO, "%s|DATA_CACHE_TMP|update|get|%d", user.str(), 0);
		m_lockpool.clear();
		return OK;
	}

	static int update_stamp(CDataBlockSet& des,  CDataBlockSet& src);
	static void copy_unlock(CDataBlockSet& des, CDataBlockSet& src);
};

class CDataCacheDB:public CDataCacheBase
{
public:
	//重复使用时，一定记得要调用哦
	virtual int init(CDataCache* pLocalCache);

	virtual ~CDataCacheDB()
	{
		clear_lock();
	}
	
	inline void clear_lock()
	{
		m_lockpool.rollback();
	}
	
	//get请求
	//return FAIL OK WOULD_BLOCK
	//if return = WOULD_BLOCK; 往后请求theMissReq
	inline int get(USER_NAME& user, CDataBlockSet& theReq, CDataBlockSet& theMissReq)
	{
		if(!m_pCache)
		{
			LOG(LOG_ERROR, "not inited" );
			return FAIL;
		}

		if( m_pCache->get(user, theReq.get_obj(), theMissReq.get_obj(), m_lockpool)!=m_pCache->RET_OK)
			return FAIL;

		if(theMissReq.get_obj().blocks_size() != 0)
			return WOULD_BLOCK;

		
		m_lockpool.clear();
		return OK;
	}
	

	//当后端返回的数据需要update到cache
	inline int on_get(USER_NAME& user, CDataBlockSet& theResp)
	{
		if(!m_pCache)
		{
			LOG(LOG_ERROR, "not inited" );
			return FAIL;
		}
		if( m_pCache->update(user, theResp.get_obj(), m_lockpool)!=m_pCache->RET_OK)
			return FAIL;

		m_lockpool.clear();
		return OK;
	}

	inline int set(USER_NAME& user, CDataBlockSet& theReq)
	{
		if(!m_pCache)
		{
			LOG(LOG_ERROR, "not inited" );
			return FAIL;
		}

		if( m_pCache->set(user, theReq.get_obj())!=m_pCache->RET_OK)
			return FAIL;

		return OK;
	}

	int merge(CDataBlockSet& reqAndResp, CDataBlockSet& theMissResp);
};

#endif

