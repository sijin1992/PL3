#ifndef __SHM_HASH_MAP_H__
#define __SHM_HASH_MAP_H__

#include "msg_define.h"
#include "struct/hash_map.h"
#include "shm/shm_wrap.h"
#include "ini/ini_file.h"
#include "log/log.h"
#include <iostream>
using namespace std;

struct SHM_HASHMAP_CONFIG
{
	unsigned int nodeNum;
	unsigned int hashNum;
	key_t shmKey;

	int read_from_ini(CIniFile& oIni, const char* sector)
	{
		if(oIni.GetInt(sector, "SHM_KEY", 0, &shmKey)!= 0)
		{
			LOG(LOG_ERROR, "%s.SHM_KEY not found", sector);
			return -1;
		}
		
		if(oIni.GetInt(sector, "USER_NUM", 0, &nodeNum)!= 0)
		{
			LOG(LOG_ERROR, "%s.USER_NUM not found", sector);
			return -1;
		}
		
		if(oIni.GetInt(sector, "HASH_NUM", 0, &hashNum)!= 0)
		{
			LOG(LOG_ERROR, "%s.HASH_NUM not found", sector);
			return -1;
		}

		return 0;
	}

	void debug(ostream& os)
	{
		os << "SHM_HASHMAP_CONFIG{" << endl;
		os << "shmKey|" << hex << shmKey << dec << endl;
		os << "nodeNum|" << nodeNum << endl;
		os << "hashNum|" << hashNum << endl;
		os << "}END SHM_HASHMAP_CONFIG" << endl;
	}
};


template<typename TVAL, typename TUSER=USER_NAME, typename THASH=UserHashType> class CShmHashMap
{
	public:
		typedef CHashMap<TUSER, TVAL, THASH> USER_HASH_MAP;
		CShmHashMap()
		{
			m_pmap = NULL;
			m_inited = false;
		}

		~CShmHashMap()
		{
			if(m_pmap)
			{
				delete m_pmap;
				m_pmap = NULL;
			}
		}

		void info(ostream& os)
		{

			if(!m_inited)
			{
				os << "not inited" << endl;
				return;
			}

			m_pmap->get_head()->debug(os);
		}

		int tryGet(key_t shmKey)
		{
			m_config.shmKey = shmKey;
			//不存在的话就不需要load了
			if(shmget(m_config.shmKey, 0, 0666)<0)
			{
				return 0;
			}

			if(m_shm.get(m_config.shmKey, 0)!=m_shm.SHM_EXIST)
			{
				LOG(LOG_ERROR, "get fail %s", m_shm.errmsg());
				return -1;
			}

			char* memStart = (char*)m_shm.get_mem();
			size_t memSize = m_shm.get_shm_size();

			if(memSize < sizeof(typename USER_HASH_MAP::HASH_MAP_HEAD))
			{
				LOG(LOG_ERROR, "memSize samll");
				return -1;
			}

			typename USER_HASH_MAP::HASH_MAP_HEAD* phead = (typename USER_HASH_MAP::HASH_MAP_HEAD*)memStart;

			m_config.nodeNum = phead->maxNodeNum;
			m_config.hashNum = phead->hashNum;

			m_pmap = new USER_HASH_MAP (memStart, memSize, m_config.nodeNum, m_config.hashNum);
			if(!m_pmap)
			{
				LOG(LOG_ERROR, "new USER_HASH_MAP fail");
				return -1;
			}

			if(!(m_pmap->valid()))
			{
				LOG(LOG_ERROR, "USER_HASH_MAP not valid %d %s", m_pmap->m_err.errcode, m_pmap->m_err.errstrmsg);
				return -1;
			}

			m_inited = true;

			return 1;
		}

		int init(CIniFile& oIni, const char * sector, int forceformat=0)
		{
			if(m_config.read_from_ini(oIni,sector)!=0)
			{
				return -1;
			}

			return init(m_config, forceformat);
		}

		int init(SHM_HASHMAP_CONFIG& config, int forceformat=0)
		{
			bool format = false;
			size_t memSize = USER_HASH_MAP::mem_size(config.nodeNum,config.hashNum);
			int ret = m_shm.get(config.shmKey, memSize);
			if(ret == m_shm.SHM_EXIST)
			{
				if(m_shm.get_shm_size() != memSize)
				{
					LOG(LOG_INFO, "getshm(key=0x%x) size not %lu formated", config.shmKey, memSize);
					if(m_shm.remove(config.shmKey)!=m_shm.SUCCESS)
					{
						LOG(LOG_ERROR, "remove(key=0x%x) fail", config.shmKey);
						return -1;
					}

					ret = m_shm.get(config.shmKey, memSize);
					format = true;
				}
			}
			else if(ret == m_shm.SUCCESS)
			{
				format = true;
			}

			if(ret == m_shm.ERROR)
			{
				LOG(LOG_ERROR, "getshm(key=%u) %s", config.shmKey, m_shm.errmsg());
				return -1;
			}

			void* memStart = m_shm.get_mem();

			if(format || forceformat)
			{
				USER_HASH_MAP::clear(memStart);
				LOG(LOG_INFO, "clear data for 0x%x because format=%d forceformat=%d",
					config.shmKey, format, forceformat);
			}
			
			m_pmap = new USER_HASH_MAP (memStart, memSize, config.nodeNum,config.hashNum);
			if(!m_pmap)
			{
				LOG(LOG_ERROR, "new USER_HASH_MAP fail");
				return -1;
			}

			if(!(m_pmap->valid()))
			{
				LOG(LOG_ERROR, "USER_HASH_MAP not valid %d %s", m_pmap->m_err.errcode, m_pmap->m_err.errstrmsg);
				return -1;
			}
			
			m_inited = true;
			return 0;
		}

		USER_HASH_MAP* get_map()
		{
			if(!m_inited)
			{
				LOG(LOG_ERROR, "not inited");
				return NULL;
			}
			return m_pmap;
		}

	public:
		SHM_HASHMAP_CONFIG m_config;
		
	protected:
		USER_HASH_MAP* m_pmap;
		bool m_inited;
		CShmWrapper m_shm;
};

#endif

