#include "data_cache.h"
#include <sstream>

unsigned int CCacheBucketList::get_min_bucket_size()
{
	return sizeof(FIRST_CACHE_BUCKET_HEAD)+16;
}

CCacheBucketList::CCacheBucketList()
{
	m_palloc = NULL;
}

int CCacheBucketList::get_first_head(int firstIdx, FIRST_CACHE_BUCKET_HEAD*& ptheHead)
{
	if(!m_palloc)
	{
		LOG(LOG_ERROR, "m_palloc=NULL");
		return CDataCache::RET_ERROR;
	}

	if(firstIdx < 0)
	{
		LOG(LOG_ERROR, "firstIdx < 0");
		return CDataCache::RET_ERROR;
	}
	
	ptheHead = (FIRST_CACHE_BUCKET_HEAD*)(m_palloc->get_blockdata(firstIdx));
	return CDataCache::RET_OK;
}

int CCacheBucketList::get(int firstIdx, DataBlock& block)
{
	m_tmplock = false;//清理

	if(!m_palloc)
	{
		LOG(LOG_ERROR, "m_palloc=NULL");
		return CDataCache::RET_ERROR;
	}

	if(firstIdx < 0)
	{
		LOG(LOG_ERROR, "firstIdx < 0");
		return CDataCache::RET_ERROR;
	}

	int idx = firstIdx;
	int copyLen = 0;
	int leftBuffLen = sizeof(m_buffer);
	char* pBucket;
	CACHE_BUCKET_HEAD* pBucketHead;
	char* pBucketData;
	FIRST_CACHE_BUCKET_HEAD* p = (FIRST_CACHE_BUCKET_HEAD*)(m_palloc->get_blockdata(idx));

	block.clear_buff();//防止有数据
	if(!m_isTmp) 
	{
		//try lock
		if( block.has_lock())
		{
			if(p->set_lock(block.lock()))
			{
				m_tmplock = true;
			}
			else
			{
				block.set_retcode(block.LOCKED);
				return CDataCache::RET_OK;
			}
		}

		//try stamp
		if(block.has_stamp())
		{
			if(block.stamp() == p->stamp)
			{
				block.set_retcode(block.NOT_MODIFIED);
				return CDataCache::RET_OK;
			}
		}
	}

//ostringstream os;
//os << "bucketlist:[";
	//copy 数据
	while(idx >= 0)
	{
		if(idx == firstIdx)//第一个数据桶有多余的头信息
		{
			pBucketHead = &(p->bucketHead);
			pBucketData = (char*)p + sizeof(FIRST_CACHE_BUCKET_HEAD);
		}
		else if(idx >= m_palloc->get_nodeinfo().uiNum)
		{
			LOG(LOG_ERROR, "idx(%d) >= nodeNum(%d)", idx, m_palloc->get_nodeinfo().uiNum);
			return CDataCache::RET_ERROR;
		}
		else
		{
//os << ",";
			pBucket = m_palloc->get_blockdata(idx);
			pBucketHead  = (CACHE_BUCKET_HEAD*)pBucket;
			pBucketData = pBucket + sizeof(CACHE_BUCKET_HEAD);
		}

		if(pBucketHead->bucketDataLen > m_palloc->get_nodeinfo().uiSize)
		{
			LOG(LOG_ERROR, "pBucketHead->bucketDataLen(%d) > nodeSize(%d)", pBucketHead->bucketDataLen, m_palloc->get_nodeinfo().uiSize);
			return CDataCache::RET_ERROR;
		}
		
//os << "(" << idx << ")" << pBucketHead->bucketDataLen;	
		if(leftBuffLen < pBucketHead->bucketDataLen)
		{
			LOG(LOG_ERROR, "get buff small");
			return CDataCache::RET_BUFF_SMALL;
		}

		if(pBucketHead->bucketDataLen > 0) //空数据就别调用memcpy了
			memcpy(m_buffer + copyLen, pBucketData, pBucketHead->bucketDataLen);
		copyLen += pBucketHead->bucketDataLen;
		leftBuffLen -= pBucketHead->bucketDataLen;
		idx = pBucketHead->nextBucketIdx;
	}
//os << "] totalbytes " << copyLen;

	block.mutable_buff()->assign(m_buffer,copyLen);
	block.set_retcode(block.OK);
	block.set_stamp(p->stamp);
//LOG(LOG_INFO, "get value %s", os.str().c_str());

	return CDataCache::RET_OK;
}

int CCacheBucketList::set(int& theFirstIdx, DataBlock& block)
{
	if(!m_palloc)
	{
		LOG(LOG_ERROR, "m_palloc=NULL");
		return CDataCache::RET_ERROR;
	}

	FIRST_CACHE_BUCKET_HEAD* pold = NULL;
	FIRST_CACHE_BUCKET_HEAD* pnew = NULL;
	int oldFirstIdx = theFirstIdx; //copy老的
	int newFirstIdx;
	bool needUnlock = !m_isTmp & block.has_unlock();
	if(oldFirstIdx >= 0)
	{
		pold = (FIRST_CACHE_BUCKET_HEAD*)(m_palloc->get_blockdata(oldFirstIdx));
	}

	if(!block.has_buff())
	{
		if(!needUnlock || !pold)
		{
			block.set_retcode(block.OK);
			return CDataCache::RET_OK; //nothing be done
		}

		//只修改旧的数据即可
		pold->unset_lock();
		block.set_retcode(block.OK);
		return CDataCache::RET_OK;
	}

	//需要copy数据
	if(new_data(newFirstIdx, block) != CDataCache::RET_OK)
	{
		return CDataCache::RET_ERROR;
	}

	pnew = (FIRST_CACHE_BUCKET_HEAD*)(m_palloc->get_blockdata(newFirstIdx));

	//替换数据
	theFirstIdx = newFirstIdx;
	if(oldFirstIdx >= 0)
	{
		pnew->lock = pold->lock; //继承lock
		if(needUnlock)
			pnew->unset_lock();
		free(oldFirstIdx);
	}
	else
	{
		pnew->unset_lock(); //初始化lock
	}

	block.set_retcode(block.OK);
	return CDataCache::RET_OK ;
}

int CCacheBucketList::update(int& theFirstIdx, DataBlock& block)
{
	m_tmplock = false;
	if(!m_palloc)
	{
		LOG(LOG_ERROR, "m_palloc=NULL");
		return CDataCache::RET_ERROR;
	}

	FIRST_CACHE_BUCKET_HEAD* pold = NULL;
	FIRST_CACHE_BUCKET_HEAD* pnew = NULL;
	int oldFirstIdx = theFirstIdx; //copy老的
	int newFirstIdx;
	bool needLock = !m_isTmp & block.has_lock();
	if(oldFirstIdx >= 0)
	{
		//前置加锁
		pold = (FIRST_CACHE_BUCKET_HEAD*)(m_palloc->get_blockdata(oldFirstIdx));
		if(needLock)
		{
			if(!pold->set_lock(block.lock()))
			{
				m_tmplock =  true;
				block.set_retcode(block.LOCKED);
				return CDataCache::RET_OK;
			}
		}
	}

	//一定需要copy数据
	if(new_data(newFirstIdx, block) != CDataCache::RET_OK)
	{
		return CDataCache::RET_ERROR;
	}

	pnew = (FIRST_CACHE_BUCKET_HEAD*)(m_palloc->get_blockdata(newFirstIdx));

	//替换数据
	theFirstIdx = newFirstIdx;
	if(oldFirstIdx >= 0)
	{
		pnew->lock = pold->lock; //继承lock(需要锁的话，已经锁过了)
		free(oldFirstIdx);
	}
	else
	{
		pnew->unset_lock(); //初始化lock
		if(needLock)
		{
			m_tmplock = true;
			pnew->set_lock(block.lock()); //一定成功
		}
	}

	block.set_retcode(block.OK);
	return CDataCache::RET_OK ;
}



int CCacheBucketList::new_data(int& theFirstIdx, DataBlock& block)
{
	if(!block.has_stamp() || !block.has_buff())
	{
		// 不能没有data和stamp
		LOG(LOG_ERROR, "block no buff or no stamp");
		return CDataCache::RET_ERROR;
	}

	int ret = m_palloc->alloc(theFirstIdx);
	if(ret != m_palloc->SUCCESS)
	{
		LOG(LOG_ERROR, "alloc = %d", ret);
		return CDataCache::RET_ERROR;
	}

	FIRST_CACHE_BUCKET_HEAD* pnew = (FIRST_CACHE_BUCKET_HEAD*)(m_palloc->get_blockdata(theFirstIdx));

	pnew->stamp = block.stamp(); 
	pnew->set_modify(); //初始化
		
	CACHE_BUCKET_HEAD* pBucketHead;
	char* pBucket;
	char* pBucketData;
	int newIdx;
	int oneTimeCopyLen=0;
	int copyLen=0;
	int leftLen = block.buff().size();
	const char* data = block.buff().data();
	bool first = true;
	int bucketLen = m_palloc->get_nodeinfo().uiSize;
	int bucketBuffLen;
	int* plast = NULL;

	//保护,有可能数据长度为0
	if(leftLen <= 0)
	{
		pnew->bucketHead.bucketDataLen = 0;
		pnew->bucketHead.nextBucketIdx = -1;
	}
	else if(leftLen >= sizeof(m_buffer))
	{
		LOG(LOG_ERROR, "block buff size=%d > %d", leftLen, sizeof(m_buffer));
		free(theFirstIdx);
		return CDataCache::RET_ERROR;
	}

	while(leftLen > 0)
	{
		if(first)
		{
			first = false;
			pBucketHead = &(pnew->bucketHead);
			pBucketData = (char*)pnew + sizeof(FIRST_CACHE_BUCKET_HEAD);
			bucketBuffLen = bucketLen-sizeof(FIRST_CACHE_BUCKET_HEAD);
		}
		else
		{
			ret = m_palloc->alloc(newIdx);
			if(ret != m_palloc->SUCCESS)
			{
				LOG(LOG_ERROR, "m_alloc.alloc=%d", ret);
				break;
			}
			pBucket = m_palloc->get_blockdata(newIdx);
			pBucketHead  = (CACHE_BUCKET_HEAD*)pBucket;
			pBucketData = pBucket + sizeof(CACHE_BUCKET_HEAD);
			bucketBuffLen = bucketLen-sizeof(CACHE_BUCKET_HEAD);
		}

		if(leftLen > bucketBuffLen)
		{
			oneTimeCopyLen = bucketBuffLen;
		}
		else
		{
			oneTimeCopyLen = leftLen;
		}

		memcpy(pBucketData, data+copyLen, oneTimeCopyLen);
		copyLen += oneTimeCopyLen;
		leftLen -= oneTimeCopyLen;

		pBucketHead->bucketDataLen = oneTimeCopyLen;
		if(plast) //首次不用赋值
			*plast = newIdx;
		plast = &(pBucketHead->nextBucketIdx);
		pBucketHead->nextBucketIdx = -1;
	}

	if(leftLen > 0)
	{
		//出错break了
		free(theFirstIdx);
		return CDataCache::RET_ERROR;
	}
	
	return CDataCache::RET_OK;
}

//释放掉data部分
int CCacheBucketList::free(int firstIdx)
{
	CACHE_BUCKET_HEAD* pBucketHead;
	FIRST_CACHE_BUCKET_HEAD* pFirst;
	int delIdx = 0;
	int nextIdx = firstIdx;
	while(nextIdx >= 0)
	{
		if(nextIdx == firstIdx)
		{
			pFirst = (FIRST_CACHE_BUCKET_HEAD*)(m_palloc->get_blockdata(nextIdx));
			pBucketHead = &(pFirst->bucketHead);
		}
		else
		{
			pBucketHead  = (CACHE_BUCKET_HEAD*)(m_palloc->get_blockdata(nextIdx));
		}
		
		delIdx = nextIdx;
		nextIdx = pBucketHead->nextBucketIdx;
		m_palloc->free(delIdx);
	}
	
	return CDataCache::RET_OK;
}

int DATA_CACHE_CONFIG::read_from_ini(const char* file, const char* sectorName)
{
	CIniFile oIni(file);
	if(!oIni.IsValid())
	{
		LOG(LOG_ERROR, "read ini %s fail", file);
		return -1;
	}

	return read_from_ini(oIni, sectorName);
}

int DATA_CACHE_CONFIG::read_from_ini(CIniFile& oIni, const char* sectorName)
{
	shmKey = 0;
	userNum = 0;
	hashNum = 0;
	bucketNum = 0;
	bucketSize = 0;
	nodeNum = 0;
	timerNum = 0;
	writeBackTimeoutS = 0;

	if(oIni.GetInt(sectorName, "SHM_KEY", 0, &shmKey)!= 0)
	{
		LOG(LOG_ERROR, "%s.SHM_KEY not found", sectorName);
		return -1;
	}

	if(oIni.GetInt(sectorName, "USER_NUM", 0, &userNum)!= 0)
	{
		LOG(LOG_ERROR, "%s.USER_NUM not found", sectorName);
		return -1;
	}

	if(oIni.GetInt(sectorName, "HASH_NUM", 0, &hashNum)!= 0)
	{
		LOG(LOG_ERROR, "%s.HASH_NUM not found", sectorName);
		return -1;
	}

	if(oIni.GetInt(sectorName, "BUCKET_NUM", 0, &bucketNum)!= 0)
	{
		LOG(LOG_ERROR, "%s.BUCKET_NUM not found", sectorName);
		return -1;
	}

	if(oIni.GetInt(sectorName, "BUCKET_SIZE", 0, &bucketSize)!= 0)
	{
		LOG(LOG_ERROR, "%s.BUCKET_SIZE not found", sectorName);
		return -1;
	}
	
	nodeNum = userNum;

	if(oIni.GetInt(sectorName, "TIMER_SIZE", 0, &timerNum)!= 0)
	{
		LOG(LOG_ERROR, "%s.TIMER_SIZE not found", sectorName);
		return -1;
	}

	if(oIni.GetInt(sectorName, "WRITE_BACK_TIMEOUT_S", 0, &writeBackTimeoutS)!= 0)
	{
		LOG(LOG_ERROR, "%s.WRITE_BACK_TIMEOUT_S not found", sectorName);
		return -1;
	}

	if(oIni.GetInt(sectorName, "MIN_FREE_BUCKET", 0, &minFreeBucket)!= 0)
	{
		LOG(LOG_ERROR, "%s.MIN_FREE_BUCKET not found", sectorName);
		return -1;
	}

	if(oIni.GetInt(sectorName, "MIN_FREE_USER", 0, &minFreeUser)!= 0)
	{
		LOG(LOG_ERROR, "%s.MIN_FREE_NODE not found", sectorName);
		return -1;
	}

	if(oIni.GetInt(sectorName, "RELEASE_NUM", 0, &releaseNum)!= 0)
	{
		LOG(LOG_ERROR, "%s.RELEASE_NUM not found", sectorName);
		return -1;
	}

	int tmp = 0;
	oIni.GetInt(sectorName, "TEMPORERY", 0, &tmp);
	if(tmp)
		isTmp = true;
	else
		isTmp = false;
	
	return 0;
}

CDataCache::CDataCache()
{
	m_pmap = NULL;
	m_pfifo = NULL;
	m_ptimer = NULL;
}

CDataCache::~CDataCache()
{
	if(m_pmap)
	{
		delete m_pmap;
		m_pmap = NULL;
	}

	if(m_pfifo)
	{
		delete m_pfifo;
		m_pfifo = NULL;
	}
	
	if(m_ptimer)
	{
		delete m_ptimer;
		m_ptimer = NULL;
	}
}

int CDataCache::init(DATA_CACHE_CONFIG& config, bool forceFormat, int* pbindDebugFlag)
{
	if(config.bucketSize <= sizeof(CCacheBucketList::get_min_bucket_size()))
	{
		LOG(LOG_ERROR, "config.bucketSize=%u <= min_size(%u) fail", 
			config.bucketSize, CCacheBucketList::get_min_bucket_size());
		return -1;
	}

	m_config = config;
	
	size_t statusSize = sizeof(DATA_CACHE_STATUS);
	size_t mapSize = DATA_CACHE_MAP::mem_size(config.userNum, config.hashNum);
	CFixedsizeAllocator::CNodeInfo allocNodeInfo(config.bucketNum, config.bucketSize);
	size_t allocSize = CFixedsizeAllocator::calculate_size(allocNodeInfo);
	size_t fifoSize = DATA_CACHE_FIFO::mem_size(config.nodeNum);
	size_t timerSize;
	if(config.timerNum == 0)
		timerSize = 0;
	else
		timerSize = DATA_CACHE_TIMER::mem_size(config.timerNum);
	size_t totalSize = statusSize + mapSize + allocSize + fifoSize + timerSize;
	bool format = false;

	if(forceFormat)
	{
		if(m_shm.remove(config.shmKey)!=m_shm.SUCCESS)
		{
			LOG(LOG_ERROR, "forceFormat remove(key=0x%x) fail", config.shmKey);
			return -1;
		}
	}

	int ret = m_shm.get(config.shmKey,totalSize);
	if(ret == m_shm.SHM_EXIST)
	{
		if(m_shm.get_shm_size() != totalSize)
		{
			LOG(LOG_ERROR, "getshm(key=0x%x) size not %lu", config.shmKey, totalSize);
			return -1;
		}
	}
	else if(ret == m_shm.ERROR)
	{
		LOG(LOG_ERROR, "getshm(key=%u) %s", config.shmKey, m_shm.errmsg());
		return -1;
	}
	else
	{
		format = true;
	}

	char* start = (char*)(m_shm.get_mem());

	//status
	m_pstatus = (DATA_CACHE_STATUS*)start;
	start += statusSize;

	//map初始化
	m_pmap = new DATA_CACHE_MAP(start, mapSize,config.userNum, config.hashNum);
	if(!m_pmap) 
	{
		LOG(LOG_ERROR, "new CHashMap fail");
		return -1;
	}
	
	if(!(m_pmap->valid()))
	{
		LOG(LOG_ERROR, "CHashMap not valid %d %s", m_pmap->m_err.errcode, m_pmap->m_err.errstrmsg);
		return -1;
	}

	start += mapSize;

	//alloc
	ret = m_alloc.bind(start,allocSize, allocNodeInfo, format);
	if(ret != 0)
	{
		LOG(LOG_ERROR, "m_alloc bind fail %d", ret);
		return -1;
	}

	start += allocSize;

	//fifo
	m_pfifo = new DATA_CACHE_FIFO(start,fifoSize, config.nodeNum);
	if(!m_pfifo)
	{
		LOG(LOG_ERROR, "new CFIFOQueue fail");
		return -1;
	}

	if(!m_pfifo->valid())
	{
		LOG(LOG_ERROR, "CFIFOQueue not valid %d %s", m_pfifo->m_err.errcode, m_pfifo->m_err.errstrmsg);
		return -1;
	}

	start += fifoSize;

	//timerSize
	if(config.timerNum == 0)
	{
		if(!config.isTmp)
		{
			LOG(LOG_ERROR, "timerNum=0 but not read only");
			return -1;
		}
		
		m_ptimer = NULL;
	}
	else
	{
		m_ptimer = new DATA_CACHE_TIMER(start, timerSize, config.timerNum);
		if(!m_ptimer)
		{
			LOG(LOG_ERROR, "new CTimerPool fail");
			return -1;
		}

		if(!m_ptimer->valid())
		{
			LOG(LOG_ERROR, "CTimerPool not valid %d %s", m_ptimer->m_err.errcode, m_ptimer->m_err.errstrmsg);
			return -1;
		}
	}

	//bucket绑定
	m_bucketlist.attach(&m_alloc, config.isTmp);

	//状态
	if(format)
	{
		memset(m_pstatus, 0x0, sizeof(*m_pstatus));
		m_pstatus->isFormatStart = 1;
	}
	else
	{
		m_pstatus->isFormatStart = 0;
	}

	m_pstatus->startTime = time(NULL);
	m_pstatus->shmID = m_shm.get_shm_id();

	//debug
	m_pDebug = pbindDebugFlag;

	//inited ok
	m_inited = true;
	return 0;

}

void CDataCache::info(ostream& os)
{
	os << "-------------------------start with config-----------------------------" << endl;
	m_config.debug(os);
	if(!m_inited)
	{
		os << "not inited" << endl;
		return;
	}
	os << "-------------------------alloc(bucket) info--------------------------------" << endl;
	m_alloc.dump(os, true);
	os << "-------------------------map(node) info--------------------------------" << endl;
	m_pmap->get_head()->debug(os);
	os << "-------------------------fifo(release) info--------------------------------" << endl;
	if(m_pfifo)
		m_pfifo->get_head()->debug(os);
	else
		os << "no fifo" << endl;
	os << "-------------------------timer(write_back) info--------------------------------" << endl;
	if(m_ptimer)
		m_ptimer->get_head()->debug(os);
	else
		os << "no timer" << endl;
		
	os << "-------------------------status----------------------------" << endl;
	if(m_pstatus)
		m_pstatus->debug(os);
	else
		os << "no status" << endl;
	os << "-------------------------info_end----------------------------" << endl;
}

int CDataCache::active(unsigned int valIdx)
{
	CACHE_HASH_NODE* pval = m_pmap->get_val_pointer(valIdx);
	if(pval->attachFifoID >= 0)
	{
		unsigned int outIdx;
		if(m_pfifo->del(pval->attachFifoID, outIdx) != m_pfifo->RET_OK)
		{
			LOG(LOG_ERROR, "m_pfifo->del(datap=%u) %d %s", valIdx, m_pfifo->m_err.errcode, m_pfifo->m_err.errstrmsg);
			return -1;
		}

		//数据不一致?记下错误日志
		if(outIdx != valIdx)
		{
			LOG(LOG_ERROR,  "m_pfifo->del(datap=%u) but outIdx=%u",valIdx,outIdx);
		}

		pval->attachFifoID = -1;
	}

	if(m_pfifo->inqueue(pval->attachFifoID,	valIdx) != m_pfifo->RET_OK)
	{
		LOG(LOG_ERROR, "m_pfifo->inqueue(datap=%u) %d %s", valIdx, m_pfifo->m_err.errcode, m_pfifo->m_err.errstrmsg);
		return RET_ERROR;
	}

	return RET_OK;
}

int CDataCache::check_write_back(USER_NAME& theUser, CACHE_HASH_NODE* pval, CDataCacheWriteBack* pwrtieback)
{
	if(m_pDebug && *m_pDebug)
	{
		LOG(LOG_DEBUG, "call check_write_back");
		if(pval)
			debug_hash_node(pval);
	}
	
	if(!pwrtieback || !pval)
	{
		return RET_ERROR;
	}

	DataBlockSet* pblockSet = pwrtieback->get_obj();
	if(!pblockSet)
	{
		return RET_ERROR;
	}

	pblockSet->Clear();
	
	int firstIdx;
	FIRST_CACHE_BUCKET_HEAD* pFirst;
	vector<FIRST_CACHE_BUCKET_HEAD*> vpFirsts;
	vpFirsts.reserve(DATA_BLOCK_ARRAY_MAX);
	for(int i=0; i<DATA_BLOCK_ARRAY_MAX; ++i)
	{
		firstIdx = pval->bucketListIdxs[i];
		if(firstIdx >= 0)
		{
			m_bucketlist.get_first_head(firstIdx, pFirst);
			if(pFirst->modified())
			{
				DataBlock* pnewblock = pblockSet->add_blocks();
				if(m_bucketlist.get(firstIdx, *pnewblock)==RET_OK) //只copydata
				{
					pnewblock->set_id(i); //记录id
					vpFirsts.push_back(pFirst); // 记下需要清理的modified
				}
				else
				{
					//看错误日志吧。。
				}
			}
		}
	}

	if(pblockSet->blocks_size() == 0)
	{
		if(m_pDebug && *m_pDebug)
		{
			LOG(LOG_DEBUG, "check_write_back nothing modified");
		}
		return RET_OK;
	}

	if(pwrtieback->on_get_ok(theUser, pblockSet) == 0)
	{
		for(unsigned int i=0; i<vpFirsts.size() ; ++i)
			vpFirsts[i]->clear_modify();
	}

	if(m_pDebug && *m_pDebug)
	{
		LOG(LOG_DEBUG, "after call back");
		if(pval)
			debug_hash_node(pval);
	}

	return RET_OK;
}


int CDataCache::del(USER_NAME & user, CDataCacheWriteBack* pwrtieback)
{
	if(!m_inited)
	{
		LOG(LOG_ERROR, "%s|CDataCache not inited", user.str());
		return RET_ERROR;
	}
	//先查找用户
	unsigned int idx = 0;
	int ret = m_pmap->get_node_idx(user, idx);
	if(ret < 0)
	{
		LOG(LOG_ERROR, "%s|m_pmap->get_node_idx fail %d %s", user.str(), m_pmap->m_err.errcode, m_pmap->m_err.errstrmsg);
		return RET_ERROR;
	}
	else if(ret == 0)
	{
		return RET_OK;
	}

	CACHE_HASH_NODE* pval = m_pmap->get_val_pointer(idx);

	//检查是否需要回写, 不然可能有数据丢失
	if(pwrtieback && check_write_back(user, pval, pwrtieback) != RET_OK)
	{
		return RET_ERROR;
	}

	//取消相关的timer和fifo
	if(pval->attachTimerID > 0)
	{
		if(m_ptimer->del_timer(pval->attachTimerID) != 0)
		{
			LOG(LOG_ERROR, "%s|del writeBack timer(%u) for %s fail %d %s", user.str() , 
			pval->attachTimerID, user.str(), m_ptimer->m_err.errcode, m_ptimer->m_err.errstrmsg);
		}

		pval->attachTimerID = 0;
	}

	if(pval->attachFifoID >= 0)
	{
		unsigned int outIdx;
		if(m_pfifo->del(pval->attachFifoID, outIdx)!= m_pfifo->RET_OK)
		{
			LOG(LOG_ERROR, "%s|m_pfifo->del(datap=%u) %d %s", user.str(), idx, m_pfifo->m_err.errcode, m_pfifo->m_err.errstrmsg);
		}
		else if(outIdx != idx)
		{
			LOG(LOG_ERROR,  "%s|m_pfifo->del(datap=%u) but outIdx=%u", user.str(),idx,outIdx);
		}

		pval->attachFifoID = -1;
	}

	//关于锁的问题，del是因为长期非活跃被淘汰的,理论上锁应该已经过期了
	//data释放以及hash map 删除数据
	for(int i=0; i<DATA_BLOCK_ARRAY_MAX; ++i)
	{
		if(pval->bucketListIdxs[i] >= 0)
			m_bucketlist.free(pval->bucketListIdxs[i]);
	}
	
	ret = m_pmap->del_node(user);
	if(ret < 0)
	{
		LOG(LOG_ERROR, "%s|m_pmap->del_node fail %d %s", user.str(), m_pmap->m_err.errcode, m_pmap->m_err.errstrmsg);
	}

	return RET_OK;	
}

int CDataCache::check_release(CDataCacheWriteBack* pwrtieback)
{
	if(!m_inited)
	{
		LOG(LOG_ERROR, "CDataCache not inited");
		return RET_ERROR;
	}
	
	int ret = 0;
	unsigned int idx = 0;
	USER_NAME tmpName;
	CACHE_HASH_NODE* pval = NULL;
	int outFifoIdx = 0;
	int freeUser = m_pmap->free_num();
	int freeBucket = m_alloc.free_num();
	if(freeUser > m_config.minFreeUser &&  freeBucket > m_config.minFreeBucket)
	{
		return RET_OK;
	}

	LOG(LOG_INFO, "freeUser(%d) min(%d) freeBucket(%d) min(%d) do release",
		freeUser, m_config.minFreeUser, freeBucket, m_config.minFreeBucket);

	for(int i=0; i<m_config.releaseNum; ++i)
	{
		ret = m_pfifo->outqueue(idx,&outFifoIdx);
		if(ret == m_pfifo->RET_EMPTY)
		{
			break;
		}
		else if(ret == m_pfifo->RET_OK)
		{
			m_pstatus->releaseCnt++;
			tmpName = *(m_pmap->get_key_pointer(idx));
			pval = m_pmap->get_val_pointer(idx);
			if(pval->attachFifoID != outFifoIdx)
			{
				//记录一下
				LOG(LOG_ERROR, "outqueue(idx=%d) not pval->fifoIdx(%d)", outFifoIdx, pval->attachFifoID);
			}
			pval->attachFifoID = -1; //是从fifo中出来的，不需要在del中释放了
			del(tmpName, pwrtieback);
		}
		else
		{
			LOG(LOG_ERROR, "outqueue fail %d %s", m_pfifo->m_err.errcode, m_pfifo->m_err.errstrmsg);
		}
	}

	return RET_OK;
}

//return 见定义
//检查回写定时器中超时的节点，pcallback处理回写的过程
int CDataCache::check_write_back_timeout(CDataCacheWriteBack* pwrtieback, int& writebackcnt)
{
	vector<unsigned int> vtimerID;
	vector<unsigned int> vtimerData;
	vtimerID.reserve(100);
	vtimerData.reserve(100);
	if(!m_ptimer)
	{
		return 0;
	}
	
	int ret = m_ptimer->check_timer(vtimerID, vtimerData);
	if(ret < 0)
	{
		LOG(LOG_ERROR, "set check_timer fail %d %s", m_ptimer->m_err.errcode, m_ptimer->m_err.errstrmsg);
		return RET_ERROR;
	}

	unsigned int idx = 0;
	USER_NAME tmpName;
	CACHE_HASH_NODE* pval = NULL;
	unsigned int i;
	for(i=0; i<vtimerID.size(); ++i)
	{
		m_pstatus->timerWritebackCnt++;
		idx = vtimerData[i];
		tmpName = *(m_pmap->get_key_pointer(idx));
		pval = m_pmap->get_val_pointer(idx);

		if(pval->attachTimerID != vtimerID[i])
		{
			//记录一下
			LOG(LOG_ERROR, "timeout(idx=%u) not pval->attachTimerID(%u)", vtimerID[i], pval->attachTimerID);
		}

		pval->attachTimerID = 0; //已经timeout

		//pwrtieback肯定要有的，不然调用这个函数干嘛
		check_write_back(tmpName, pval, pwrtieback);
	}

	writebackcnt = i;

	return RET_OK;
}

int CDataCache::get_stamp(USER_NAME& user, DataBlockSet& theData)
{
	DEBUG_BLOCKSET(theData, "get_stamp begin")
	if(!m_inited)
	{
		LOG(LOG_ERROR, "CDataCache not inited");
		return RET_ERROR;
	}
	unsigned int idx = 0;
	int ret = m_pmap->get_node_idx(user, idx);
	if(m_pDebug && *m_pDebug)
		LOG(LOG_DEBUG, "copy_stamp get_node_idx=%d idx=%d", ret, idx);
	if(ret == 1)
	{
		CACHE_HASH_NODE* pval = m_pmap->get_val_pointer(idx);
		for(int i=0; i<theData.blocks_size(); ++i)
		{
			DataBlock* ptheBlock = theData.mutable_blocks(i);
			int blockId = ptheBlock->id();
			if(blockId<0 || blockId>=DATA_BLOCK_ARRAY_MAX)
			{
				LOG(LOG_ERROR, "get but block id=%d invalid", blockId);
				return RET_ERROR;
			}
		
			int firstIdx = pval->bucketListIdxs[blockId];
			FIRST_CACHE_BUCKET_HEAD * ptheFirstHead;
			if(firstIdx > 0)
			{
				m_bucketlist.get_first_head(firstIdx, ptheFirstHead);
				ptheBlock->set_stamp(ptheFirstHead->stamp);
			}
		}
	}
	
	DEBUG_BLOCKSET(theData, "get_stamp end")
	return RET_OK;
}

//获取user对应的数据
int CDataCache::get(USER_NAME& user, DataBlockSet& theData, DataBlockSet& theMissData, CDataCacheLockPool& thePool)
{
	DEBUG_BLOCKSET(theData, "get begin")

	if(thePool.attach(this, user)!=0)
	{
		return RET_ERROR;
	}

	theData.set_result(theData.FAIL);

	if(m_config.isTmp)
	{
		//不能get只能update
		LOG(LOG_ERROR, "%s|tmp cache can't get", user.str());
		return RET_ERROR;
	}
	
	if(!m_inited)
	{
		LOG(LOG_ERROR, "%s|CDataCache not inited", user.str());
		return RET_ERROR;
	}

	theMissData.Clear();
	m_pstatus->getCnt++;
	
	//先查找用户
	unsigned int idx = 0;
	int ret = m_pmap->get_node_idx(user, idx);
	if(m_pDebug && *m_pDebug)
		LOG(LOG_DEBUG, "%s|get get_node_idx=%d idx=%d", user.str(), ret, idx);
	
	if(ret < 0)
	{
		LOG(LOG_ERROR, "%s|m_pmap->get_node_idx fail %d %s", user.str(), m_pmap->m_err.errcode, m_pmap->m_err.errstrmsg);
		m_pstatus->getErr++;
		return RET_ERROR;
	}
	else if(ret == 0)
	{
		//没有数据
		m_pstatus->getNoData++;
		theData.set_result(theData.MISS);

		//for late merge
		for(int x=0; x<theData.blocks_size(); ++x)
		{
			theData.mutable_blocks(x)->set_retcode(DataBlock::MISS);
		}
		
		theMissData = theData;
		return RET_OK;
	}
	
	CACHE_HASH_NODE* pval = m_pmap->get_val_pointer(idx);
	if(m_pDebug && *m_pDebug)
	{
		ostringstream os;
		pval->debug(os);
		LOG(LOG_DEBUG, "%s", os.str().c_str());
	}

	//active
	active(idx);

	//循环获取
	int blockId;

	for(int i=0; i<theData.blocks_size(); ++i)
	{
		DataBlock* ptheBlock = theData.mutable_blocks(i);
		blockId = ptheBlock->id();
		if(blockId<0 || blockId>=DATA_BLOCK_ARRAY_MAX)
		{
			LOG(LOG_ERROR, "%s|get but block id=%d invalid", user.str(), blockId);
			m_pstatus->getErr++;
			return RET_ERROR;
		}

		if(pval->bucketListIdxs[blockId] < 0)
		{
			//没有数据
			ptheBlock->set_retcode(ptheBlock->MISS);
			DataBlock* pmiss = theMissData.add_blocks();
			*pmiss = *ptheBlock;
			continue;
		}

		ret = m_bucketlist.get(pval->bucketListIdxs[blockId], *ptheBlock);

		if(m_bucketlist.cached_lock())
		{
			thePool.push(i);
		}

		if(ret!=RET_OK || !ptheBlock->has_retcode())
		{
			m_pstatus->getErr++;
			return RET_ERROR;
		}

		if(ptheBlock->retcode() == ptheBlock->LOCKED)
		{
			m_pstatus->getLocked++;
			theData.set_result(theData.LOCKED);
			LOG(LOG_ERROR, "%s|get locked", user.str());
			return RET_ERROR;
		}
		else if(ptheBlock->retcode() == ptheBlock->NOT_MODIFIED)
		{
			m_pstatus->getNotModified++;
			continue;
		}
		else if(ptheBlock->retcode() != ptheBlock->OK)
		{
			//shit
			LOG(LOG_ERROR, "%s|recode error", user.str());
			return RET_ERROR;
		}

	}
	m_pstatus->getOK++;

	theData.set_result(theData.OK);
	DEBUG_BLOCKSET(theData, "get end")
	return RET_OK;
}

//写入user对应的数据
//theData为输入参数
int CDataCache::set(USER_NAME& user, DataBlockSet& theData)
{
	DEBUG_BLOCKSET(theData, "set begin")
	theData.set_result(theData.FAIL);

	if(m_config.isTmp)
	{
		//不能set只能update
		LOG(LOG_ERROR, "%s|tmp cache can't set", user.str());
		return RET_ERROR;
	}
	
	if(!m_inited)
	{
		LOG(LOG_ERROR, "%s|CDataCache not inited", user.str());
		return RET_ERROR;
	}

	m_pstatus->setCnt++;

	//先查找用户
	unsigned int idx = 0;
	int ret = m_pmap->get_node_idx(user, idx);
	if(m_pDebug && *m_pDebug)
		LOG(LOG_DEBUG, "%s|set get_node_idx=%d idx=%d", user.str(), ret, idx);
	if(ret < 0)
	{
		LOG(LOG_ERROR, "%s|m_pmap->get_node_idx fail %d %s", user.str(), m_pmap->m_err.errcode, m_pmap->m_err.errstrmsg);
		m_pstatus->setErr++;
		return RET_ERROR;
	}
	else if(ret == 0)
	{
		//先set一个节点
		CACHE_HASH_NODE tmp;
		tmp.clear();
		ret = m_pmap->set_node(user, tmp, NULL, &idx);
		if(m_pDebug && *m_pDebug)
			LOG(LOG_DEBUG, "%s|set set_node=%d idx=%d", user.str(),ret, idx);
		if(ret < 0)
		{
			LOG(LOG_ERROR, "%s|m_pmap->set_node fail %d %s", user.str(), m_pmap->m_err.errcode, m_pmap->m_err.errstrmsg);
			m_pstatus->setErr++;
			return RET_ERROR;
		}
	}
	
	CACHE_HASH_NODE* pval = m_pmap->get_val_pointer(idx);
	if(m_pDebug && *m_pDebug)
	{
		ostringstream os;
		pval->debug(os);
		LOG(LOG_DEBUG, "%s", os.str().c_str());
	}

	//active
	active(idx);

	int blockId;
	for(int i=0; i<theData.blocks_size(); ++i)
	{
		DataBlock* ptheBlock = theData.mutable_blocks(i);
		blockId = ptheBlock->id();

		if(blockId<0 || blockId>=DATA_BLOCK_ARRAY_MAX)
		{
			LOG(LOG_ERROR, "%s|get but block id=%d invalid", user.str(), blockId);
			m_pstatus->setErr++;
			return RET_ERROR;
		}

		ptheBlock->set_stamp(new_stamp());
		
		ret = m_bucketlist.set(pval->bucketListIdxs[blockId], *ptheBlock);
		if(ret != RET_OK || !ptheBlock->has_retcode())
		{
			m_pstatus->setErr++;
			return RET_ERROR;
		}
		
		if(ptheBlock->retcode() != ptheBlock->OK)
		{
			m_pstatus->getLocked++;
			//shit
			LOG(LOG_ERROR, "%s|recode=error", user.str());
			return RET_ERROR;
		}
		
		if(pval->attachTimerID == 0)
		{
			if(m_pDebug && *m_pDebug)
			{
				LOG(LOG_DEBUG, "%s|timer seted", user.str());
			}
			
			if(m_ptimer->set_timer_s(pval->attachTimerID, idx, m_config.writeBackTimeoutS)!=0)
			{
				LOG(LOG_ERROR, "%s|set_timer fail", user.str());
			}
		}
	}
	m_pstatus->setOK++;

	theData.set_result(theData.OK);
	DEBUG_BLOCKSET(theData, "set end")
	return RET_OK;
}

int CDataCache::update(USER_NAME& user, DataBlockSet& theData, CDataCacheLockPool& thePool)
{
	DEBUG_BLOCKSET(theData, "update begin")
	if(thePool.attach(this, user)!=0)
	{
		return RET_ERROR;
	}
	
	theData.set_result(theData.FAIL);
	
	if(!m_inited)
	{
		LOG(LOG_ERROR, "%s|CDataCache not inited", user.str());
		return RET_ERROR;
	}

	//先查找用户
	unsigned int idx = 0;
	int ret = m_pmap->get_node_idx(user, idx);
	if(m_pDebug && *m_pDebug)
		LOG(LOG_DEBUG, "%s|update get_node_idx=%d idx=%d", user.str(), ret, idx);
	if(ret < 0)
	{
		LOG(LOG_ERROR, "%s|m_pmap->get_node_idx fail %d %s", user.str(), m_pmap->m_err.errcode, m_pmap->m_err.errstrmsg);
		return RET_ERROR;
	}
	else if(ret == 0)
	{
		//先set一个节点
//LOG(LOG_ERROR, "datacache update new node");
		CACHE_HASH_NODE tmp;
		tmp.clear();
		ret = m_pmap->set_node(user, tmp, NULL, &idx);
		if(m_pDebug && *m_pDebug)
			LOG(LOG_DEBUG, "%s|update set_node=%d idx=%d", user.str(), ret, idx);
		if(ret < 0)
		{
			LOG(LOG_ERROR, "%s|m_pmap->set_node fail %d %s", user.str(), m_pmap->m_err.errcode, m_pmap->m_err.errstrmsg);
			return RET_ERROR;
		}
	}
	
	CACHE_HASH_NODE* pval = m_pmap->get_val_pointer(idx);
	if(m_pDebug && *m_pDebug)
	{
		ostringstream os;
		pval->debug(os);
		LOG(LOG_DEBUG, "%s", os.str().c_str());
	}

	//active
	active(idx);

	int blockId;
	for(int i=0; i<theData.blocks_size(); ++i)
	{
		DataBlock* ptheBlock = theData.mutable_blocks(i);
		blockId = ptheBlock->id();

		if(blockId<0 || blockId>=DATA_BLOCK_ARRAY_MAX)
		{
			LOG(LOG_ERROR, "%s|get but block id=%d invalid", user.str(),blockId);
			return RET_ERROR;
		}

		if(m_config.isTmp)
		{
			//允许不copy not modify的数据
			if(ptheBlock->has_retcode() && ptheBlock->retcode() == ptheBlock->NOT_MODIFIED)
			{
				ret = m_bucketlist.get(pval->bucketListIdxs[blockId], *ptheBlock);
				if(ret != RET_OK || ptheBlock->retcode() != ptheBlock->OK)
				{
					LOG(LOG_ERROR, "%s|fill not modified block fail, old data gone...", user.str());
					return RET_ERROR;
				}
				
				continue;
			}
		}

		if(!m_config.isTmp) //db cache需要新生成stamp
		{
			ptheBlock->set_stamp(new_stamp());
		}
		
		ret = m_bucketlist.update(pval->bucketListIdxs[blockId], *ptheBlock);
		if(m_bucketlist.cached_lock())
		{
			thePool.push(i);
		}

		if(ret != RET_OK || !ptheBlock->has_retcode())
		{
			return RET_ERROR;
		}

		if(ptheBlock->retcode() == ptheBlock->LOCKED)
		{
			theData.set_result(theData.LOCKED);
			return RET_ERROR;
		}
		else if(ptheBlock->retcode() != ptheBlock->OK)
		{
			//shit
			LOG(LOG_ERROR, "%s|recode=error", user.str());
			return RET_ERROR;
		}
	}

	theData.set_result(theData.OK);
	DEBUG_BLOCKSET(theData, "update end")
	return RET_OK;
}

void CDataCache::unlock_block(USER_NAME& user, int blockId)
{
	unsigned int idx = 0;
	int ret = m_pmap->get_node_idx(user, idx);
	if(m_pDebug && *m_pDebug)
		LOG(LOG_DEBUG, "set get_node_idx=%d idx=%d", ret, idx);
	if(ret == 1)
	{
		if(blockId<0 || blockId>=DATA_BLOCK_ARRAY_MAX)
		{
			LOG(LOG_ERROR, "%s|unlock_block but blockId=%d invalid", user.str(), blockId);
			return;
		}			

		CACHE_HASH_NODE* pval = m_pmap->get_val_pointer(idx);
		int firstIdx = pval->bucketListIdxs[blockId];
		if(firstIdx < 0)
		{
			LOG(LOG_ERROR, "%s|unlock_block but firstIdx < 0", user.str());
			return;
		}
		FIRST_CACHE_BUCKET_HEAD * ptheHead;
		m_bucketlist.get_first_head(firstIdx, ptheHead);
		ptheHead->unset_lock();
	}
	else
	{
		LOG(LOG_ERROR, "%s|unlock_block but no data", user.str());
	}
}

void CDataCache::debug_hash_node(CACHE_HASH_NODE* pval)
{
	ostringstream os;
	pval->debug(os);
	LOG(LOG_DEBUG, "%s", os.str().c_str());
	for(int i=0; i<DATA_BLOCK_ARRAY_MAX; ++i)
	{
		if(pval->bucketListIdxs[i] >= 0)
		{
			FIRST_CACHE_BUCKET_HEAD* pfirst;
			m_bucketlist.get_first_head(pval->bucketListIdxs[i], pfirst);
			os.str("");
			pfirst->debug(os);
			LOG(LOG_DEBUG, "%s", os.str().c_str());
		}
	}
}

