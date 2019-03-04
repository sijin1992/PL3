#ifndef __DB_DATA_CACHE_H__
#define __DB_DATA_CACHE_H__

#include "common/msg_define.h"
#include "struct/hash_map.h"
#include "struct/fixedsize_allocator.h"
#include "struct/timer.h"
#include "struct/fifo_queue.h"
#include "shm/shm_wrap.h"
#include "ini/ini_file.h"
#include "proto/datablock.pb.h"
#include <iostream>
#include <time.h>
#include <vector>
#include "log/log.h"

using namespace std;

/*
* cache的数据存储结构设计为用户为key，数据块id为2级key的变长存储
* cache设计为有淘汰和定时回写，淘汰删除整个用户数据
* 回写只回写有修改的数据块。
* cache 分成2种，对应到逻辑和db服务器
* 前者cache是临时cache，不能保证数据最新(称为tmp cache)
* 后者cache保证数据分布是唯一直接与数据库交互，(称为db cache)
* 两者通过cache的配置isTmp来区分。
* tmp cache是为了节省网络流量(后台数据没有更新的情况下)，只存储数据块和时间戳。
* 只有到db cache中确认了时间戳一致才能使用cache的get操作。
* tmp cache不支持set 操作，set请求直接给db cache
* 可以用成功返回的新时间戳更新tmp cache (update操作)，也可以不更新。

* db cache 支持数据块的锁和时间戳，支持异步回写 
* 对db cache的get操作，如果时间戳一致将返回not modify不copy数据
* 缓存中没有数据返回miss, 空数据不是miss。
* set db cache前调用者必须自己保证已经用lock get的方式获得锁(数据块是全量更新的)
* 因为cache本身不保存调用者信息，所以无法甄别锁的拥有者
*/


//前置申明
class CDataCache;

//紧密排列
#pragma pack(push)
#pragma pack(1)

//数据桶头
struct CACHE_BUCKET_HEAD
{
	int bucketDataLen; //这个bucket的数据长度
	int nextBucketIdx; //下个bucket的索引
};

//首个数据桶的头
struct FIRST_CACHE_BUCKET_HEAD
{
	char modifyFlag;
	unsigned long long lock; //实质是时间
	unsigned long long stamp; // 4字节时间+4字节序列
	CACHE_BUCKET_HEAD bucketHead;

	//reqLock为锁时间长度
	inline bool set_lock(unsigned long long  reqLock)
	{
		unsigned long long sec = time(NULL);
		if(lock == 0 || lock < sec)
		{
			lock = sec+reqLock;
			return true;
		}

		if (lock > 36000000)
		{
			LOG(LOG_INFO, "lock error lock=%d,now=%d,reqLock=%d ", lock, sec, reqLock);
			lock = 0;
			return set_lock(reqLock);
		}

		return false;
	}

	inline void unset_lock()
	{
		lock = 0;
	}

	inline bool modified()
	{
		return modifyFlag != 0;
	}

	inline void set_modify()
	{
		modifyFlag = 1;
	}

	inline void clear_modify()
	{
		modifyFlag = 0;
	}

	void debug(ostream& os)
	{
		os << "FIRST_CACHE_BUCKET_HEAD{" << endl;
		os << "modifyFlag|" << (int)modifyFlag << endl;
		os << "stamp|" << stamp << endl;
		os << "bucketHead|len=" << bucketHead.bucketDataLen << ",next=" << bucketHead.nextBucketIdx << endl;
		os << "}END FIRST_CACHE_BUCKET_HEAD" << endl;
	}
};

//索引的hash节点
struct CACHE_HASH_NODE
{
	unsigned int attachTimerID; //关联的定时回写
	int attachFifoID; //关联的活跃顺序
	int bucketListIdxs[DATA_BLOCK_ARRAY_MAX]; //bucketList 数组

	inline void clear()
	{
		attachTimerID = 0;
		attachFifoID = -1;
		clearBucketListIdx();
	}

	inline void clearBucketListIdx()
	{
		for(int i=0; i<DATA_BLOCK_ARRAY_MAX; ++i)
		{
			bucketListIdxs[i] = -1;
		}
	}

	inline void debug(ostream& os)
	{
		os << "CACHE_HASH_NODE{" << endl;
		os << "attachTimerID|" << attachTimerID << endl;
		os << "attachFifoID|" << attachFifoID << endl;
		os << "bucketListIdxs|";
		for(unsigned int i=0; i<DATA_BLOCK_ARRAY_MAX; ++i)
		{
			if(i != 0)
				os << ",";
			os << bucketListIdxs[i];
		}
		os << endl;
		os << "}END CACHE_HASH_NODE" << endl;
	}
};

//用于定时回写的timer数据
typedef unsigned int CACHE_TIMER_NODE;
/*
struct CACHE_TIMER_NODE
{
	unsigned int hashNodeIdx; //关联的hashNode
};
*/

//用于淘汰非活跃的FIFO数据
typedef unsigned int CACHE_FIFO_DATAP;
/*
struct CACHE_FIFO_DATAP
{
	unsigned int hashNodeIdx; //关联的hashNode
};
*/

//用于统计的类
struct DATA_CACHE_STATUS
{
	int isFormatStart;
	time_t startTime;
	int shmID;
	unsigned long long getCnt;
	unsigned long long getOK;
	unsigned long long getNoData;
	unsigned long long getLocked;
	unsigned long long getNotModified;
	unsigned long long getErr;
	unsigned long long setCnt;
	unsigned long long setFillRcdToCacheCnt;
	unsigned long long setOK;
	unsigned long long setHasData;
	unsigned long long setErr;
	unsigned long long timerWritebackCnt;
	unsigned long long releaseCnt;
	unsigned long long writebackCnt;
	char reserve[256];
	
	inline void debug(ostream& os)
	{
		os << "DB_CACHE_STATUS{" << endl;
		os << "isFormatStart|" << isFormatStart << endl;
		os << "startTime|" << startTime << endl;
		os << "shmID|" << shmID << endl;
		os << "getCnt|" << getCnt << endl;
		os << "getOK|" << getOK << endl;
		os << "getNoData|" << getNoData << endl;
		os << "getLocked|" << getLocked << endl;
		os << "getNotModified|" << getNotModified << endl;
		os << "getErr|" << getErr << endl;
		os << "setCnt|" << setCnt << endl;
		os << "setFillRcdToCacheCnt|" << setFillRcdToCacheCnt << endl;
		os << "setOK|" << setOK << endl;
		os << "setHasData|" << setHasData << endl;
		os << "setErr|" << setErr << endl;
		os << "timerWritebackCnt|" << timerWritebackCnt << endl;
		os << "releaseCnt|" << releaseCnt << endl;
		os << "writebackCnt|" << writebackCnt << endl;
		os << "}END DB_CACHE_STATUS" << endl;
	}
};


#pragma pack(pop)

//bucketList操作类
class CCacheBucketList
{
public:
	static unsigned int get_min_bucket_size();

	CCacheBucketList();

	//绑定分配器，和选项nolock
	inline void attach(CFixedsizeAllocator* palloc, bool isTmp=false)
	{
		m_palloc = palloc;
		m_isTmp = isTmp;
	}

	//返回头地址，如果有必要操作的话
	int get_first_head(int firstIdx, FIRST_CACHE_BUCKET_HEAD*& ptheHead);

	//读数据
	//block为输入输出参数:
	//输入组合:
	//isTmp=false
	//block.has_stamp()可选，有的话会比较时间戳
	//block.has_lock()可选，有的话会尝试加锁
	//否则直接返回数据
	//输出&返回值
	// return = OK包括以下情况
	//加锁失败block.retcode=LOCKED 其他不做修改(buff清空)
	//数据戳没变block.retcode=NOT_MODIFIED block不做修改(buff清空)
	//获取成功block.retcode=OK block.stamp()，block.buff()被修改
	// 否则return = FAIL
	int get(int firstIdx, DataBlock& block);

	//写入数据
	//theFirstIdx是输入输出参数
	//输入是当前的bucket首索引，输出可能是新的索引(当有数据成功写入时)
	//block 为输入输出参数
	//输入:
	//block.has_buff()为true时，block.stamp()必须为true
	//buff和stamp同时写入，调用者保证stamp唯一
	//(isTmp=false时)has_unlock()有效
	//输出&返回值
	// return = OK时block.retcode=OK
	int set(int& theFirstIdx, DataBlock& block);

	//用新的数据更新bucket
	// block.has_buff()和block.stamp()必须为true
	//(isTmp=false时)has_lock()将有效，在调用lock get miss后，update要带原有的lock
	// return = OK时block.retcode=OK or block.retcode=LOCKED
	int update(int& theFirstIdx, DataBlock& block);
	
	//删除bucket，firstIdx之后就无效了
	int free(int firstIdx);

	//返回上次get/update过程中是否获取了锁
	int cached_lock()
	{
		return m_tmplock;
	}

protected:
	//返回新的数据块
	int new_data(int& theFirstIdx, DataBlock& block);
	
protected:
	CFixedsizeAllocator* m_palloc;
	char m_buffer[MSG_BUFF_LIMIT];
	bool m_isTmp; //是否属于tmp cache
	bool m_tmplock;
};

//配置
struct DATA_CACHE_CONFIG
{
	//使用共享内存
	key_t shmKey;
	//hash map的配置
	unsigned int userNum;
	unsigned int hashNum;
	//fixedsize alloca的配置
	unsigned int bucketNum;
	unsigned int bucketSize;
	//fifo的配置
	unsigned int nodeNum; //=userNum
	//timer配置
	unsigned int timerNum; //timer用来回写的，同时活跃数据应该不多，userNum的1/10就了不起了
	unsigned int writeBackTimeoutS; //回写时间间隔
	//淘汰的配置
	int minFreeBucket;
	int minFreeUser;
	int releaseNum;
	//是否忽略加锁
	bool isTmp;

	DATA_CACHE_CONFIG()
	{
		shmKey = 0;
		userNum = 0;
		hashNum = 0;
		bucketNum = 0;
		bucketSize = 0;
		nodeNum = 0;
		timerNum = 0;
		writeBackTimeoutS = 0;
		minFreeBucket = 0;
		minFreeUser= 0;
		releaseNum = 0;
		isTmp = false;
	}

	void debug(ostream& os)
	{
		os << "DB_CACHE_CONFIG{" << endl;
		os << "shmKey|" << hex << shmKey << dec << endl;
		os << "userNum|" << userNum << endl;
		os << "hashNum|" << hashNum << endl;
		os << "bucketNum|" << bucketNum << endl;
		os << "bucketSize|" << bucketSize << endl;
		os << "nodeNum|" << nodeNum << endl;
		os << "timerNum|" << timerNum << endl;
		os << "writeBackTimeoutS|" << writeBackTimeoutS << endl;
		os << "minFreeBucket|" << minFreeBucket << endl;
		os << "minFreeUser|" << minFreeUser << endl;
		os << "releaseNum|" << releaseNum << endl;
		os << "isTmp|" << isTmp << endl;
		os << "}END DB_CACHE_CONFIG" << endl;
	} 

	int read_from_ini(const char* file, const char* sectorName);
	int read_from_ini(CIniFile& oIni, const char* sectorName);
};

//回写callback
class CDataCacheWriteBack
{
	public:
		//返回一个可用的DataBlockSet
		virtual DataBlockSet* get_obj() = 0;
		//获取成功，返回的是有修改的数据
		//如果return=0 数据将被标记成未修改
		virtual int on_get_ok(USER_NAME& user, DataBlockSet* pdataSet) = 0;
		
		virtual ~CDataCacheWriteBack() {}
};


//缓存类

typedef CHashMap<USER_NAME, CACHE_HASH_NODE, UserHashType> DATA_CACHE_MAP;
typedef CFIFOQueue<CACHE_FIFO_DATAP> DATA_CACHE_FIFO;
typedef CTimerPool<CACHE_TIMER_NODE> DATA_CACHE_TIMER;
typedef vector<int> DATA_CACHE_LOCK_POOL;

class CDataCacheLockPool;


class CDataCache
{
public:
	CDataCache();
	~CDataCache();
	
	const static int RET_OK = 0;
	const static int RET_ERROR = -1;
	const static int RET_BUFF_SMALL = -2;

	//使用config初始化,0=ok
	int init(DATA_CACHE_CONFIG& config, bool forceFormat=false, int* pbindDebugFlag = NULL);

	//检查是否需要淘汰最早活跃的数据,
	//剩余数据桶小于minFreeBucket或者剩余用户数小于minFreeUser都会触发淘汰
	//num指定淘汰的个数，内部使用del, pcallback传递给del
	int check_release(CDataCacheWriteBack* pwrtieback = NULL);

	//return 见定义
	//检查回写定时器中超时的节点，pcallback处理回写的过程
	int check_write_back_timeout(CDataCacheWriteBack* pwrtieback, int& writebackcnt);

	//查看info
	void info(ostream& os);

	//从cache中提取时间戳，用于tmp cache 和final cache之间的对比
	int get_stamp(USER_NAME& user, DataBlockSet& theData);

	//tmp cache 不允许使用
	//获取user对应的数据
	//theData为输入输出参数, 按照theData包含的block[i].id来拉取
	//theMissData (会先清空)为cache中没有，需要到数据库确认的data
	//此时，theData.result = miss (hash节点不存在)或者是blocks[i].retcode =miss
	//DATA_CACHE_LOCK_POOL thePool所有已经加的锁，在到后台取数据的过程中发送冲突用来释放
	//if return = RET_OK
	//theData.result()=OK or MISS
	//if return = RET_FAIL
	//theData.result()=FAIL or LOCKED
	int get(USER_NAME& user, DataBlockSet& theData, DataBlockSet& theMissData, CDataCacheLockPool& thePool);

	//用已有的数据更新user对应的数据
	//对于tmp cache而言将同步theData有NOT_MODIFY 的数据将被填写
	//对于db cache而言写入时将创建新的时间戳
	//if return = RET_OK
	//theData.result()=OK 
	//if return = RET_FAIL
	//theData.result()=FAIL or LOCKED
	int update(USER_NAME& user, DataBlockSet& theData, CDataCacheLockPool& thePool);

	//tmp cache 不允许使用
	//if return = RET_OK
	//theData.result()=OK 
	//if return = RET_FAIL
	//theData.result()=FAIL 
	int set(USER_NAME& user, DataBlockSet& theData);

	//删除user对应的数据,并清除活跃以及回写的关联
	int del(USER_NAME& user, CDataCacheWriteBack* pwrtieback = NULL);

	//锁和时间戳操作
	inline unsigned long long new_stamp()
	{
		unsigned long long stamp = time(NULL);
		return (stamp << 32) | (seq++);
	}

	inline bool isTmp()
	{
		return m_config.isTmp;
	}

	//回滚锁用的
	void unlock_block(USER_NAME& user, int blockId);

	void debug_hash_node(CACHE_HASH_NODE* pval);

	//调用者保证只读数据，不写数据
	inline DATA_CACHE_MAP* getmap()
	{
		return m_pmap;
	}

	inline CCacheBucketList* getbucklist()
	{
		return &m_bucketlist;
	}

protected:
	#define DEBUG_BLOCKSET(set, pos) 	//if(m_pDebug && *m_pDebug){debug_blockset(set, pos);}
	inline void debug_blockset(DataBlockSet& set, const char* pos)
	{
		LOG(LOG_DEBUG, "%s DataBlockSet=", pos);
		LOG(LOG_DEBUG, "%s", set.DebugString().c_str());
	}
	
	inline void lock_pool_push(DATA_CACHE_LOCK_POOL& thePool, unsigned int blockIdx)
	{
		thePool.push_back(blockIdx);
	}
	
	//激活数据，数据满的时候最不活跃的将被淘汰
	//get, set 请求都将触发active
	int active(unsigned int valIdx);
	int check_write_back(USER_NAME& user, CACHE_HASH_NODE* pval, CDataCacheWriteBack* pwrtieback);
	
protected:
	unsigned int seq;
	DATA_CACHE_MAP* m_pmap;
	CFixedsizeAllocator m_alloc;
	DATA_CACHE_FIFO* m_pfifo;
	DATA_CACHE_TIMER* m_ptimer;
	bool m_inited;
	CShmWrapper m_shm;
	DATA_CACHE_CONFIG m_config;
	DATA_CACHE_STATUS* m_pstatus;
	CCacheBucketList m_bucketlist;
	int* m_pDebug;
};

class CDataCacheLockPool
{
public:
	CDataCacheLockPool()
	{
		m_pmaster = NULL;
	}

	inline int attach(CDataCache* pmaster, USER_NAME& user)
	{
		if(m_pmaster == NULL)
		{
			m_pmaster = pmaster;
			m_user = user;
		}
		else
		{
			if(m_pmaster!=pmaster || m_user!=user)
			{
				LOG(LOG_ERROR, "attach deferent master or user");
				return -1;
			}
		}

		return 0;
	}

	inline void clear()
	{
		m_pmaster = NULL;
		m_pool.clear();
	}

	inline void push(int blockIdx)
	{
		if(m_pmaster)
			m_pool.push_back(blockIdx);
	}

	inline void rollback()
	{
		if(m_pmaster)
		{
			for(unsigned int i=0; i<m_pool.size(); ++i)
			{
				m_pmaster->unlock_block(m_user, m_pool[i]);
			}
			clear();
		}
	}

protected:
	USER_NAME m_user;
	DATA_CACHE_LOCK_POOL m_pool;
	CDataCache* m_pmaster;
};


#endif

