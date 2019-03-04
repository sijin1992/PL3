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
* cache�����ݴ洢�ṹ���Ϊ�û�Ϊkey�����ݿ�idΪ2��key�ı䳤�洢
* cache���Ϊ����̭�Ͷ�ʱ��д����̭ɾ�������û�����
* ��дֻ��д���޸ĵ����ݿ顣
* cache �ֳ�2�֣���Ӧ���߼���db������
* ǰ��cache����ʱcache�����ܱ�֤��������(��Ϊtmp cache)
* ����cache��֤���ݷֲ���Ψһֱ�������ݿ⽻����(��Ϊdb cache)
* ����ͨ��cache������isTmp�����֡�
* tmp cache��Ϊ�˽�ʡ��������(��̨����û�и��µ������)��ֻ�洢���ݿ��ʱ�����
* ֻ�е�db cache��ȷ����ʱ���һ�²���ʹ��cache��get������
* tmp cache��֧��set ������set����ֱ�Ӹ�db cache
* �����óɹ����ص���ʱ�������tmp cache (update����)��Ҳ���Բ����¡�

* db cache ֧�����ݿ������ʱ�����֧���첽��д 
* ��db cache��get���������ʱ���һ�½�����not modify��copy����
* ������û�����ݷ���miss, �����ݲ���miss��
* set db cacheǰ�����߱����Լ���֤�Ѿ���lock get�ķ�ʽ�����(���ݿ���ȫ�����µ�)
* ��Ϊcache���������������Ϣ�������޷��������ӵ����
*/


//ǰ������
class CDataCache;

//��������
#pragma pack(push)
#pragma pack(1)

//����Ͱͷ
struct CACHE_BUCKET_HEAD
{
	int bucketDataLen; //���bucket�����ݳ���
	int nextBucketIdx; //�¸�bucket������
};

//�׸�����Ͱ��ͷ
struct FIRST_CACHE_BUCKET_HEAD
{
	char modifyFlag;
	unsigned long long lock; //ʵ����ʱ��
	unsigned long long stamp; // 4�ֽ�ʱ��+4�ֽ�����
	CACHE_BUCKET_HEAD bucketHead;

	//reqLockΪ��ʱ�䳤��
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

//������hash�ڵ�
struct CACHE_HASH_NODE
{
	unsigned int attachTimerID; //�����Ķ�ʱ��д
	int attachFifoID; //�����Ļ�Ծ˳��
	int bucketListIdxs[DATA_BLOCK_ARRAY_MAX]; //bucketList ����

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

//���ڶ�ʱ��д��timer����
typedef unsigned int CACHE_TIMER_NODE;
/*
struct CACHE_TIMER_NODE
{
	unsigned int hashNodeIdx; //������hashNode
};
*/

//������̭�ǻ�Ծ��FIFO����
typedef unsigned int CACHE_FIFO_DATAP;
/*
struct CACHE_FIFO_DATAP
{
	unsigned int hashNodeIdx; //������hashNode
};
*/

//����ͳ�Ƶ���
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

//bucketList������
class CCacheBucketList
{
public:
	static unsigned int get_min_bucket_size();

	CCacheBucketList();

	//�󶨷���������ѡ��nolock
	inline void attach(CFixedsizeAllocator* palloc, bool isTmp=false)
	{
		m_palloc = palloc;
		m_isTmp = isTmp;
	}

	//����ͷ��ַ������б�Ҫ�����Ļ�
	int get_first_head(int firstIdx, FIRST_CACHE_BUCKET_HEAD*& ptheHead);

	//������
	//blockΪ�����������:
	//�������:
	//isTmp=false
	//block.has_stamp()��ѡ���еĻ���Ƚ�ʱ���
	//block.has_lock()��ѡ���еĻ��᳢�Լ���
	//����ֱ�ӷ�������
	//���&����ֵ
	// return = OK�����������
	//����ʧ��block.retcode=LOCKED ���������޸�(buff���)
	//���ݴ�û��block.retcode=NOT_MODIFIED block�����޸�(buff���)
	//��ȡ�ɹ�block.retcode=OK block.stamp()��block.buff()���޸�
	// ����return = FAIL
	int get(int firstIdx, DataBlock& block);

	//д������
	//theFirstIdx�������������
	//�����ǵ�ǰ��bucket������������������µ�����(�������ݳɹ�д��ʱ)
	//block Ϊ�����������
	//����:
	//block.has_buff()Ϊtrueʱ��block.stamp()����Ϊtrue�b
	//buff��stampͬʱд�룬�����߱�֤stampΨһ
	//(isTmp=falseʱ)has_unlock()��Ч
	//���&����ֵ
	// return = OKʱblock.retcode=OK
	int set(int& theFirstIdx, DataBlock& block);

	//���µ����ݸ���bucket
	// block.has_buff()��block.stamp()����Ϊtrue�b
	//(isTmp=falseʱ)has_lock()����Ч���ڵ���lock get miss��updateҪ��ԭ�е�lock
	// return = OKʱblock.retcode=OK or block.retcode=LOCKED
	int update(int& theFirstIdx, DataBlock& block);
	
	//ɾ��bucket��firstIdx֮�����Ч��
	int free(int firstIdx);

	//�����ϴ�get/update�������Ƿ��ȡ����
	int cached_lock()
	{
		return m_tmplock;
	}

protected:
	//�����µ����ݿ�
	int new_data(int& theFirstIdx, DataBlock& block);
	
protected:
	CFixedsizeAllocator* m_palloc;
	char m_buffer[MSG_BUFF_LIMIT];
	bool m_isTmp; //�Ƿ�����tmp cache
	bool m_tmplock;
};

//����
struct DATA_CACHE_CONFIG
{
	//ʹ�ù����ڴ�
	key_t shmKey;
	//hash map������
	unsigned int userNum;
	unsigned int hashNum;
	//fixedsize alloca������
	unsigned int bucketNum;
	unsigned int bucketSize;
	//fifo������
	unsigned int nodeNum; //=userNum
	//timer����
	unsigned int timerNum; //timer������д�ģ�ͬʱ��Ծ����Ӧ�ò��࣬userNum��1/10���˲�����
	unsigned int writeBackTimeoutS; //��дʱ����
	//��̭������
	int minFreeBucket;
	int minFreeUser;
	int releaseNum;
	//�Ƿ���Լ���
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

//��дcallback
class CDataCacheWriteBack
{
	public:
		//����һ�����õ�DataBlockSet
		virtual DataBlockSet* get_obj() = 0;
		//��ȡ�ɹ������ص������޸ĵ�����
		//���return=0 ���ݽ�����ǳ�δ�޸�
		virtual int on_get_ok(USER_NAME& user, DataBlockSet* pdataSet) = 0;
		
		virtual ~CDataCacheWriteBack() {}
};


//������

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

	//ʹ��config��ʼ��,0=ok
	int init(DATA_CACHE_CONFIG& config, bool forceFormat=false, int* pbindDebugFlag = NULL);

	//����Ƿ���Ҫ��̭�����Ծ������,
	//ʣ������ͰС��minFreeBucket����ʣ���û���С��minFreeUser���ᴥ����̭
	//numָ����̭�ĸ������ڲ�ʹ��del, pcallback���ݸ�del
	int check_release(CDataCacheWriteBack* pwrtieback = NULL);

	//return ������
	//����д��ʱ���г�ʱ�Ľڵ㣬pcallback�����д�Ĺ���
	int check_write_back_timeout(CDataCacheWriteBack* pwrtieback, int& writebackcnt);

	//�鿴info
	void info(ostream& os);

	//��cache����ȡʱ���������tmp cache ��final cache֮��ĶԱ�
	int get_stamp(USER_NAME& user, DataBlockSet& theData);

	//tmp cache ������ʹ��
	//��ȡuser��Ӧ������
	//theDataΪ�����������, ����theData������block[i].id����ȡ
	//theMissData (�������)Ϊcache��û�У���Ҫ�����ݿ�ȷ�ϵ�data
	//��ʱ��theData.result = miss (hash�ڵ㲻����)������blocks[i].retcode =miss
	//DATA_CACHE_LOCK_POOL thePool�����Ѿ��ӵ������ڵ���̨ȡ���ݵĹ����з��ͳ�ͻ�����ͷ�
	//if return = RET_OK
	//theData.result()=OK or MISS
	//if return = RET_FAIL
	//theData.result()=FAIL or LOCKED
	int get(USER_NAME& user, DataBlockSet& theData, DataBlockSet& theMissData, CDataCacheLockPool& thePool);

	//�����е����ݸ���user��Ӧ������
	//����tmp cache���Խ�ͬ��theData��NOT_MODIFY �����ݽ�����д
	//����db cache����д��ʱ�������µ�ʱ���
	//if return = RET_OK
	//theData.result()=OK 
	//if return = RET_FAIL
	//theData.result()=FAIL or LOCKED
	int update(USER_NAME& user, DataBlockSet& theData, CDataCacheLockPool& thePool);

	//tmp cache ������ʹ��
	//if return = RET_OK
	//theData.result()=OK 
	//if return = RET_FAIL
	//theData.result()=FAIL 
	int set(USER_NAME& user, DataBlockSet& theData);

	//ɾ��user��Ӧ������,�������Ծ�Լ���д�Ĺ���
	int del(USER_NAME& user, CDataCacheWriteBack* pwrtieback = NULL);

	//����ʱ�������
	inline unsigned long long new_stamp()
	{
		unsigned long long stamp = time(NULL);
		return (stamp << 32) | (seq++);
	}

	inline bool isTmp()
	{
		return m_config.isTmp;
	}

	//�ع����õ�
	void unlock_block(USER_NAME& user, int blockId);

	void debug_hash_node(CACHE_HASH_NODE* pval);

	//�����߱�ֻ֤�����ݣ���д����
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
	
	//�������ݣ���������ʱ�����Ծ�Ľ�����̭
	//get, set ���󶼽�����active
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

