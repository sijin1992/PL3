#include "data_cache_api.h"

void CDataBlockSet::add_get_req(int id,  unsigned int lock, unsigned long long stamp)
{
	DataBlock* pnewBlock =m_theSet.add_blocks();
	pnewBlock->set_id(id);
	if(stamp)
		pnewBlock->set_stamp(stamp);
	if(lock)
		pnewBlock->set_lock(lock);
}

void CDataBlockSet::add_set_req(int id, bool unlock, string* pbuff)
{
	DataBlock* pnewBlock = m_theSet.add_blocks();
	pnewBlock->set_id(id);
	if(unlock)
		pnewBlock->set_unlock(1);
	if(pbuff)
		*(pnewBlock->mutable_buff()) = *pbuff;
}


void CDataBlockSet::add_set_req(int id, bool unlock, char* buff, int len)
{
	DataBlock* pnewBlock = m_theSet.add_blocks();
	pnewBlock->set_id(id);
	if(unlock)
		pnewBlock->set_unlock(1);
	if(buff!=NULL)
		pnewBlock->mutable_buff()->assign(buff, len);
}

int CDataBlockSet::get_block(int blockId, DataBlock*& pBlock)
{
	for(int i=0; i<m_theSet.blocks_size(); ++i)
	{
		DataBlock* ptheBlock = m_theSet.mutable_blocks(i);
		if(ptheBlock->has_id() && ptheBlock->id() == blockId)
		{
			pBlock = ptheBlock;
			return 0;
		}
	}
	LOG(LOG_ERROR, "blockId=%d not found", blockId);
	return -1;
}

int CDataBlockSet::get_block(int it, int& blockId, DataBlock*& pBlock)
{
	if(it < 0 || it>=m_theSet.blocks_size())
	{
		LOG(LOG_ERROR, "it=%d not valid", it);
		return -1;
	}

	DataBlock* ptheBlock = m_theSet.mutable_blocks(it);
	if(ptheBlock->has_id())
		blockId = ptheBlock->id();
	else
	{
		LOG(LOG_ERROR, "block[%d] has no id", it);
		return -1;
	}
		
	pBlock = ptheBlock;
	return 0;
}

int CDataCacheDB::init(CDataCache* pLocalCache)
{
	if(!pLocalCache || pLocalCache->isTmp())
	{
		LOG(LOG_ERROR, "CDataCacheDB but cache is tmp");
		return FAIL;
	}

	m_pCache = pLocalCache;

	return OK;
}


int CDataCacheDB::merge(CDataBlockSet& reqAndResp, CDataBlockSet& theMissResp)
{
	DataBlockSet& theSet = reqAndResp.get_obj();
	DataBlockSet& theMissSet = theMissResp.get_obj();
	theSet.set_result(theMissSet.result());
	if(theSet.result() == theSet.OK)
	{
		int i;
		for(i=0; i<theSet.blocks_size(); ++i)
		{
			DataBlock* ptheBlock = theSet.mutable_blocks(i);
			if(ptheBlock->retcode() == ptheBlock->MISS)
			{
				int j;
				for(j=0; j<theMissSet.blocks_size(); ++j)
				{
					const DataBlock& theMissBlock = theMissSet.blocks(j);
					if(ptheBlock->id() == theMissBlock.id())
					{
						//匹配上了
						*ptheBlock = theMissBlock;
						break;
					}
				}

				if(j==theMissSet.blocks_size())
				{
					//没有找到匹配,shit
					LOG(LOG_ERROR, "miss id=%d", ptheBlock->id());
					break;
				}
			}
		}

		if(i!=theSet.blocks_size())
		{
			//有miss没有匹配上
			theSet.set_result(theSet.FAIL);
			return FAIL;
		}		
	}

	return OK;
}


int CDataCacheTmp::init(CDataCache* pLocalCache)
{
	if(!pLocalCache || !pLocalCache->isTmp())
	{
		LOG(LOG_ERROR, "CDataCacheTmp but cache is not tmp");
		return FAIL;
	}

	m_pCache = pLocalCache;

	return OK;
}

int CDataCacheTmp::update_stamp(CDataBlockSet& des, CDataBlockSet& src)
{
	DataBlockSet& theDes = des.get_obj();
	DataBlockSet& theSrc = src.get_obj();

	int i;
	for(i=0; i<theDes.blocks_size(); ++i)
	{
		DataBlock* pDesBlock = theDes.mutable_blocks(i);
		int j;
		for(j=0; j<theSrc.blocks_size(); ++j)
		{
			const DataBlock& theSrcBlock = theSrc.blocks(j);
			if(pDesBlock->id() == theSrcBlock.id())
			{
				//匹配上了
				if(theSrcBlock.has_stamp())
					pDesBlock->set_stamp(theSrcBlock.stamp());
				else
				{
					LOG(LOG_ERROR, "blockId(%d) no stamp find", theSrcBlock.id());
					return FAIL;
				}
				break;
			}
		}

		if(j==theSrc.blocks_size())
		{
			//没有找到匹配,shit
			LOG(LOG_ERROR, "miss id=%d", pDesBlock->id());
			return FAIL;
		}
	}

	return OK;
}

void CDataCacheTmp::copy_unlock(CDataBlockSet& des, CDataBlockSet& src)
{
	DataBlockSet& theDes = des.get_obj();
	DataBlockSet& theSrc = src.get_obj();
	for(int i=0; i<theSrc.blocks_size(); ++i)
	{
		DataBlock* pnew = theDes.add_blocks();
		const DataBlock& block = theSrc.blocks(i);
		pnew->set_id(block.id());
		if(block.has_unlock())
			pnew->set_unlock(block.unlock());
	}
}


