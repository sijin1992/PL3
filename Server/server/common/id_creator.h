#pragma once

#include "user_distribute.h"
#include "shm/mmap_wrap.h"
#include "log/log.h"

class CGroupIDCreator
{
	public:
		struct MAP_DATA
		{
			char magic[8];
			unsigned int dbmod;
			unsigned int id;
		};

		CGroupIDCreator()
		{
			m_data = NULL;
		}
		
		int init(const char* mapfile, unsigned int dbmod, unsigned int start=1)
		{
			if(dbmod >= 100)
			{
				LOG(LOG_ERROR, "dbmod %u >= 100 not supported", dbmod);
				return -1;
			}
			m_dbmod = dbmod;

			int isnew = 0;
			if(m_map.map(mapfile, sizeof(MAP_DATA),isnew)!=0)
			{
				LOG(LOG_ERROR, "map(%s) fail: %s", mapfile, m_map.errmsg());
				return -1;
			}

			m_data = (MAP_DATA*) m_map.get_mem();

			if(isnew)
			{
				snprintf(m_data->magic, sizeof(m_data->magic), "%s", "ID$%#_#");
				m_data->dbmod = dbmod;
				m_data->id = start;
			}
			else
			{
				if(strncmp(m_data->magic, "ID$%#_#", sizeof(m_data->magic))!=0)
				{
					LOG(LOG_ERROR, "map(%s) fail: magic not right", mapfile);
					return -1;
				}

				if(m_data->dbmod > dbmod)
				{
					LOG(LOG_ERROR, "new dbmod %u < old %u, not allowed", dbmod, m_data->dbmod);
					return -1;
				}
				else if(m_data->dbmod < dbmod)
				{
					//×Ô¶¯Éý¼¶
					LOG(LOG_INFO, "auto update dbmod from %u to %u", m_data->dbmod , dbmod);
					m_data->dbmod = dbmod;
					m_data->id = start;
				}
				else 
				{
					if(m_data->id < start)
					{
						LOG(LOG_INFO, "auto update id from %u to %u", m_data->id, start);
						m_data->id = start;
					}
				}
			}
			
			return 0;
		}
		
		string createID(const USER_NAME& hint)
		{
			unsigned int idx = CUserDistribute::db(hint, m_dbmod);
			char buff[32] = {0};
			snprintf(buff, sizeof(buff), "%u%02u%02u", m_data->id, m_dbmod, idx);
			++(m_data->id);
			return buff;
		}
		
	protected:
		CMmapWrap m_map;
		unsigned int m_dbmod;
		MAP_DATA* m_data;
};

