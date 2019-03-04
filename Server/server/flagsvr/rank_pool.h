#ifndef __RANK_POOL_H__
#define __RANK_POOL_H__

#include "ini/ini_file.h"
#include "common/msg_define.h"
#include "shm/shm_wrap.h"
#include "shm/mmap_wrap.h"
#include "log/log.h"
#include <map>
#include <stdlib.h>
#include <sys/time.h>
#include <string.h>
#include "proto/rank.pb.h"

using namespace std;

struct EXT_RAND_HEAD
{
	time_t timestamp;
	char reserve[256];

	void format(time_t nowtime=0)
	{
		if(nowtime == 0)
			timestamp = time(NULL);
		else
			timestamp = nowtime;
	}
};

//前三个字段必须和RANK_UNIT一致
//排序用到
struct EXT_RANK_UNIT
{
	USER_NAME user;
	int key;
	timeval thetime;
	unsigned int extlen;
	char extdata[1024];
};

struct RAND_HEAD
{
	int total;
	int used;
	int order; // 1=ascending升序 0=descending降序

	void format(int atotal, int aorder)
	{
		total=atotal;
		order=aorder;
		used = 0;
	}

	bool check(int atotal, int aorder)
	{
		return (total==atotal && order==aorder);
	}
};

struct RANK_UNIT
{
	USER_NAME user;
	int key;
	timeval thetime;
};

int qsort_callback_biger(const void * pa, const void * pb);

int qsort_callback_smaller(const void * pa, const void * pb);

class CRankPool
{
public:
		CRankPool()
		{
			m_init = false;
			m_exthead = NULL;
			m_order = 0;
			m_stable = true;
		}

		//ext head + rankunit
		int ext_init(const char* mapfile, int unittotal, int forceformat=0, int order=0)
		{
			m_mapfilepath = mapfile;
			m_rankunittotal = unittotal;
			m_order = order;
			int isnew = 0;
			bool format = false;
			size_t memSize = sizeof(EXT_RAND_HEAD) + sizeof(RAND_HEAD) + sizeof(RANK_UNIT)*m_rankunittotal;
			int ret = m_mmap.map(m_mapfilepath.c_str(), memSize, isnew);
			if(ret != 0)
			{
				LOG(LOG_ERROR, "m_mmap(file=%s) %s", m_mapfilepath.c_str(), m_mmap.errmsg());
				return -1;
			}
			
			if(isnew == 1)
				format = true;
			
			char* memStart = m_mmap.get_mem();
			m_exthead = (EXT_RAND_HEAD*)memStart;
			m_head = (RAND_HEAD*)(memStart + sizeof(EXT_RAND_HEAD));
			m_units = (RANK_UNIT*)(memStart + sizeof(EXT_RAND_HEAD) + sizeof(RAND_HEAD));
			if(format || forceformat)
			{
				LOG(LOG_INFO, "format=%d, forceformat=%d", format, forceformat);
				m_exthead->format();
				m_head->format(m_rankunittotal, m_order);
			}
			else if(!m_head->check(m_rankunittotal, m_order))
			{
				LOG(LOG_ERROR, "head check fail(%d,%d)!=(%d,%d)", m_rankunittotal, m_order,
					m_head->total, m_head->order);
				if(m_rankunittotal == m_head->total && m_head->order!=0 && m_head->order!=1)
				{
					m_head->order = m_order; //修复之，之前有过m_order没初始化的情况
					LOG(LOG_INFO, "%s, repaired order to %d", m_mapfilepath.c_str(), m_order);
				}
				else
				{
					return -1;
				}
			}

			LOG(LOG_INFO, "ext inited time=%ld, usernum=%d", m_exthead->timestamp, m_head->used);
			
			return 0;
		}

		//ext head + ext rankunit
		int ext_init2(const char* mapfile, int unittotal, int forceformat=0, int order=0)
		{
			m_mapfilepath = mapfile;
			m_rankunittotal = unittotal;
			m_order = order;
			int isnew = 0;
			bool format = false;
			size_t memSize = sizeof(EXT_RAND_HEAD) + sizeof(RAND_HEAD) + sizeof(EXT_RANK_UNIT)*m_rankunittotal;
			int ret = m_mmap.map(m_mapfilepath.c_str(), memSize, isnew);
			if(ret != 0)
			{
				LOG(LOG_ERROR, "m_mmap(file=%s) %s", m_mapfilepath.c_str(), m_mmap.errmsg());
				return -1;
			}
			
			if(isnew == 1)
				format = true;
			
			char* memStart = m_mmap.get_mem();
			m_exthead = (EXT_RAND_HEAD*)memStart;
			m_head = (RAND_HEAD*)(memStart + sizeof(EXT_RAND_HEAD));
			m_extunits = (EXT_RANK_UNIT*)(memStart + sizeof(EXT_RAND_HEAD) + sizeof(RAND_HEAD));
			if(format || forceformat)
			{
				LOG(LOG_INFO, "format=%d, forceformat=%d, m_mapfilepath:%s", format, forceformat, m_mapfilepath.c_str());
				m_exthead->format();
				m_head->format(m_rankunittotal, m_order);
			}
			else if(!m_head->check(m_rankunittotal, m_order))
			{
				LOG(LOG_ERROR, "head check fail m_(%d,%d)!= head_(%d,%d)", m_rankunittotal, m_order,
					m_head->total, m_head->order);
				if(m_rankunittotal == m_head->total && m_head->order!=0 && m_head->order!=1)
				{
					m_head->order = m_order; //修复之，之前有过m_order没初始化的情况
					LOG(LOG_INFO, "%s, repaired order to %d", m_mapfilepath.c_str(), m_order);
				}
				else
				{
					return -1;
				}
			}

			LOG(LOG_INFO, "ext inited time=%ld, usernum=%d", m_exthead->timestamp, m_head->used);
			
			return 0;
		}
		
		int init(const char* mapfile, int unittotal, int forceformat=0, int order=0)
		{
			m_mapfilepath = mapfile;
			m_rankunittotal = unittotal;
			m_order = order;
			int isnew = 0;
			bool format = false;
			size_t memSize = sizeof(RAND_HEAD) + sizeof(RANK_UNIT)*m_rankunittotal;
			int ret = m_mmap.map(m_mapfilepath.c_str(), memSize, isnew);
			if(ret != 0)
			{
				LOG(LOG_ERROR, "m_mmap(file=%s) %s", m_mapfilepath.c_str(), m_mmap.errmsg());
				return -1;
			}

			if(isnew == 1)
				format = true;

			char* memStart = m_mmap.get_mem();

			m_head = (RAND_HEAD*)memStart;
			m_units = (RANK_UNIT*)(memStart + sizeof(RAND_HEAD));
			if(format || forceformat)
				m_head->format(m_rankunittotal, m_order);
			else if(!m_head->check(m_rankunittotal, m_order))
			{
				LOG(LOG_ERROR, "head check fail(m_total:%d, m_order:%d, old_total:%d, old_order:%d)", m_rankunittotal, m_order, m_head->total, m_head->order);
				return -1;
			}

			m_init = true;
			return 0;
		}

		int init(CIniFile& oIni, const char* sector, int forceformat=0)
		{
			if(oIni.GetInt(sector, "SHM_KEY", 0, &m_shmKey)!= 0)
			{
				LOG(LOG_ERROR, "%s.SHM_KEY not found", sector);
				return -1;
			}

			if(m_shmKey == 0)
			{
				//当作mmap file 处理
				char buff[256] = {0};
				if(oIni.GetString(sector, "SHM_KEY", "", buff, sizeof(buff) )!= 0)
				{
					LOG(LOG_ERROR, "%s.SHM_KEY not found", sector);
					return -1;
				}
				m_mapfilepath = buff;
			}
			
			if(oIni.GetInt(sector, "TOTAL", 0, &m_rankunittotal)!= 0)
			{
				LOG(LOG_ERROR, "%s.TOTAL not found", sector);
				return -1;
			}

			oIni.GetInt(sector, "ORDER", 0, &m_order);

			bool format = false;
			size_t memSize = sizeof(RAND_HEAD) + sizeof(RANK_UNIT)*m_rankunittotal;

			int ret = 0;
			char* memStart = NULL;
			if(m_shmKey != 0)
			{
				ret = m_shm.get(m_shmKey, memSize);
				if(ret == m_shm.SHM_EXIST)
				{
					if(m_shm.get_shm_size() != memSize)
					{
						LOG(LOG_INFO, "getshm(key=0x%x) size not %lu formated", m_shmKey, memSize);
						if(m_shm.remove(m_shmKey)!=m_shm.SUCCESS)
						{
							LOG(LOG_ERROR, "remove(key=0x%x) fail", m_shmKey);
							return -1;
						}

						ret = m_shm.get(m_shmKey, memSize);
						format = true;
					}
				}
				else if(ret == m_shm.SUCCESS)
				{
					format = true;
				}

				if(ret == m_shm.ERROR)
				{
					LOG(LOG_ERROR, "getshm(key=%u) %s", m_shmKey, m_shm.errmsg());
					return -1;
				}
				memStart = (char*)(m_shm.get_mem());
			}
			else
			{
				//use mmap
				int isnew = 0;
				ret = m_mmap.map(m_mapfilepath.c_str(), memSize, isnew);
				if(ret != 0)
				{
					LOG(LOG_ERROR, "m_mmap(file=%s) %s", m_mapfilepath.c_str(), m_mmap.errmsg());
					return -1;
				}

				if(isnew == 1)
					format = true;
				memStart = m_mmap.get_mem();
			}
			
			m_head = (RAND_HEAD*)memStart;
			m_units = (RANK_UNIT*)(memStart + sizeof(RAND_HEAD));
			if(format || forceformat)
				m_head->format(m_rankunittotal, m_order);
			else if(!m_head->check(m_rankunittotal, m_order))
			{
				LOG(LOG_ERROR, "head check fail(%d,%d)", m_rankunittotal, m_order);
				return -1;
			}

			m_init = true;
			return 0;
		}

		bool copy(CRankPool* p)
		{
			if(m_head->total != p->head()->total)
			{
				return false;
			}
			*m_head = *(p->head());
			for(int i=0; i<m_head->used; ++i)
			{
				m_units[i] = *(p->val(i));
			}

			return true;
		}

		inline bool campare_first(int key, int oldkey)
		{
			if(m_head->order)
			{
				return key < oldkey;
			}
			else
			{
				return key > oldkey;
			}
		}

		void add_unit(USER_NAME& user, int key)
		{
			if(m_head->used >= m_head->total) 
			{
				int minidx = m_head->total - 1;
				if( m_stable ) //固定
				{
					if(!campare_first(key, m_units[minidx].key))
					{
						//onthing changed
						return;
					}
					int replaceidx = find(user);
					if(replaceidx < 0) //没有在以前的列表中
					{
						m_units[minidx].key = key;
						m_units[minidx].user = user;
						gettimeofday(&(m_units[minidx].thetime), NULL);
					}
					else
					{
						if(!campare_first(key, m_units[replaceidx].key))
						{
							//onthing changed
							return;
						}
						m_units[replaceidx].key = key;
						gettimeofday(&(m_units[replaceidx].thetime), NULL);
					}
				}
				else //浮动
				{
					int replaceidx = find(user);
					if(replaceidx < 0) //没有在以前的列表中
					{
						if(!campare_first(key, m_units[minidx].key))
						{
							//onthing changed
							return;
						}
						m_units[minidx].key = key;
						m_units[minidx].user = user;
						gettimeofday(&(m_units[minidx].thetime), NULL);
					}
					else
					{
						m_units[replaceidx].key = key;
						gettimeofday(&(m_units[replaceidx].thetime), NULL);
					}
				}

				//重新排序
				sort();
			}
			else
			{
				int replaceidx = find(user);
				if(replaceidx < 0)
				{
					replaceidx = (m_head->used)++;
					m_units[replaceidx].key = key;
					m_units[replaceidx].user = user;
					gettimeofday(&(m_units[replaceidx].thetime), NULL);
				}
				else 
				{
					if(!campare_first(key, m_units[replaceidx].key) && m_stable)
					{
						//onthing changed
						return;
					}
					m_units[replaceidx].key = key;
					gettimeofday(&(m_units[replaceidx].thetime), NULL);
				}

				//重新排序
				sort();
			}
		}

		void add_unit_ext(USER_NAME& user, int key, RankExtData* pdata)
		{
			if(m_head->used >= m_head->total) 
			{
				int minidx = m_head->total - 1;
				if( m_stable ) //固定
				{
					if(!campare_first(key, m_extunits[minidx].key))
					{
						//onthing changed
						return;
					}
					int replaceidx = find_ext(user);
					if(replaceidx < 0) //没有在以前的列表中
					{
						m_extunits[minidx].key = key;
						m_extunits[minidx].user = user;
						copy_ext_val(pdata, &(m_extunits[minidx]));
						gettimeofday(&(m_extunits[minidx].thetime), NULL);
					}
					else
					{
						copy_ext_val(pdata, &(m_extunits[replaceidx]));
						if(!campare_first(key, m_extunits[replaceidx].key))
						{
							//onthing changed
							return;
						}
						m_extunits[replaceidx].key = key;
						gettimeofday(&(m_extunits[replaceidx].thetime), NULL);
					}
				}
				else
				{
					int replaceidx = find_ext(user);
					if(replaceidx < 0) //没有在以前的列表中
					{
						if(!campare_first(key, m_extunits[minidx].key))
						{
							//onthing changed
							return;
						}
						m_extunits[minidx].key = key;
						m_extunits[minidx].user = user;
						copy_ext_val(pdata, &(m_extunits[minidx]));
						gettimeofday(&(m_extunits[minidx].thetime), NULL);
					}
					else
					{
						copy_ext_val(pdata, &(m_extunits[replaceidx]));
						m_extunits[replaceidx].key = key;
						gettimeofday(&(m_extunits[replaceidx].thetime), NULL);
					}
				}

				//重新排序
				sort_ext();
			}
			else
			{
				int replaceidx = find_ext(user);
				if(replaceidx < 0)
				{
					replaceidx = (m_head->used)++;
					m_extunits[replaceidx].key = key;
					m_extunits[replaceidx].user = user;
					copy_ext_val(pdata, &(m_extunits[replaceidx]));
					gettimeofday(&(m_extunits[replaceidx].thetime), NULL);
				}
				else 
				{
					copy_ext_val(pdata, &(m_extunits[replaceidx]));
					if(!campare_first(key, m_extunits[replaceidx].key) && m_stable)
					{
						//onthing changed
						return;
					}
					m_extunits[replaceidx].key = key;
					gettimeofday(&(m_extunits[replaceidx].thetime), NULL);
				}

				//重新排序
				sort_ext();
			}
		}

		int remove_unit(USER_NAME& user)
		{
			int removeIdx = find(user);
			if(removeIdx < 0) //没有在以前的列表中
			{
				return 0;
			}

			int lastIdx = 0;
			if(m_head->used >= m_head->total) 
			{
				lastIdx = m_head->total - 1;
			}
			else
			{
				lastIdx = m_head->used - 1;
			}

			if( lastIdx != removeIdx )
			{
				m_units[removeIdx].key = m_units[lastIdx].key;
				m_units[removeIdx].user = m_units[lastIdx].user;
				m_units[removeIdx].thetime = m_units[lastIdx].thetime;
			}

			m_head->used--;

			//重新排序
			sort();
			return 1;
		}

		int remove_unit_ext(USER_NAME& user)
		{
			int removeIdx = find_ext(user);
			if(removeIdx < 0) //没有在以前的列表中
			{
				return 0;
			}

			int lastIdx = 0;
			if(m_head->used >= m_head->total) 
			{
				lastIdx = m_head->total - 1;
			}
			else
			{
				lastIdx = m_head->used - 1;
			}

			if( lastIdx != removeIdx )
			{
				m_extunits[removeIdx].key = m_extunits[lastIdx].key;
				m_extunits[removeIdx].user = m_extunits[lastIdx].user;
				m_extunits[removeIdx].thetime = m_extunits[lastIdx].thetime;
				copy_ext_val_unit(m_extunits + removeIdx, m_extunits + lastIdx);
			}

			m_head->used--;

			//重新排序
			sort_ext();
			return 1;
		}

		inline int size()
		{
			return m_head->used;
		}

		inline bool inited()
		{
			return m_init;
		}

		inline EXT_RAND_HEAD* exthead()
		{
			return m_exthead;
		}

		inline RAND_HEAD* head()
		{
			return m_head;
		}

		RANK_UNIT* val(int i)
		{
			return &(m_units[i]);
		}

		EXT_RANK_UNIT* val_ext(int i)
		{
			return &(m_extunits[i]);
		}

		void sort()
		{
			if(m_head->used > 0)
			{
				if(m_head->order == 0)
				{
					qsort(m_units, m_head->used, sizeof(RANK_UNIT), qsort_callback_biger);		
				}
				else
				{
					qsort(m_units, m_head->used, sizeof(RANK_UNIT), qsort_callback_smaller);		
				}
			}
		}

		void sort_ext()
		{
			if(m_head->used > 0)
			{
				if(m_head->order == 0)
				{
					qsort(m_extunits, m_head->used, sizeof(EXT_RANK_UNIT), qsort_callback_biger);		
				}
				else
				{
					qsort(m_extunits, m_head->used, sizeof(EXT_RANK_UNIT), qsort_callback_smaller);		
				}
			}
		}

		void clear()
		{
			if( m_exthead != NULL )
			{
				m_exthead->format();
			}
			if( m_head != NULL )
			{
				m_head->format(m_rankunittotal, m_order);
			}
		}

		void set_stable(bool stable)
		{
			m_stable = stable;
		}

		void debug(ostream& os)
		{
			os << "CRankPool::CONFIG{" << endl;
			os << "shmKey|" << hex << m_shmKey << dec << endl;
			os << "}END CRankPool::CONFIG" << endl;
		}


		
		
	protected:
		inline int find(USER_NAME& user)
		{			
			for(int i=0; i<m_head->used; ++i)
			{
				if(user == m_units[i].user)
				{
					return i;
				}
			}

			return -1;
		}
		
		inline int find_ext(USER_NAME& user)
		{			
			for(int i=0; i<m_head->used; ++i)
			{
				if(user == m_extunits[i].user)
				{
					return i;
				}
			}

			return -1;
		}

		inline int copy_ext_val(RankExtData* pdata, EXT_RANK_UNIT* punits)
		{
			if(pdata == NULL)
			{
				punits->extlen = 0;
			}
			else
			{
				if(!pdata->SerializeToArray(punits->extdata, sizeof(punits->extdata)))
				{
					punits->extlen = 0;
					LOG(LOG_ERROR, "extdata SerializeToArray fail, maybe too long");
					return -1;
				}
				
				punits->extlen = pdata->GetCachedSize();
			}

			return 0;
		}
		inline int copy_ext_val_unit(EXT_RANK_UNIT *pTarUnit, EXT_RANK_UNIT* pSrcUnit)
		{
			if( pTarUnit == NULL )
			{
				return -1;
			}
			if(pSrcUnit == NULL)
			{
				pTarUnit->extlen = 0;
			}
			else
			{
				memcpy(pTarUnit->extdata, pSrcUnit->extdata, pSrcUnit->extlen);
				pTarUnit->extlen = pSrcUnit->extlen;
			}
			return 0;
		}
		
	protected:
		key_t m_shmKey;
		string m_mapfilepath;
		int m_rankunittotal;
		int m_order;
		CShmWrapper m_shm;
		CMmapWrap m_mmap;
		RAND_HEAD* m_head;
		RANK_UNIT* m_units;
		EXT_RAND_HEAD* m_exthead;
		EXT_RANK_UNIT* m_extunits;
		bool m_init;
		bool m_stable; //是否是固排行，不降低
};

#endif

