#ifndef __SESSION_MAP_H__
#define __SESSION_MAP_H__

/*
* CSessionMap 使用共享内存的hashmap
* 存储的玩家数据量跟conncet容量一致
*/

#include "struct/hash_map.h"
#include "shm/shm_wrap.h"
#include "log/log.h"
#include "common/msg_define.h"

void get_inner_username(USER_NAME &inner_name, USER_NAME &real_name, const char *sid)
{
	char sid_buf[16] = {0};
	size_t sid_len = strlen(sid);
	unsigned int i = 0;
	if(sid_len < 5)
	{
		for(; i < (5 - sid_len); ++i)
			sid_buf[i] = '0';
		strncpy(sid_buf + i, sid, 5-i);
	}
	else
	{
		strncpy(sid_buf, sid, 5);
	}
	char t_name[USER_NAME_LEN] = {0};
	snprintf(t_name, USER_NAME_LEN, "%s%s", real_name.str(), sid_buf);
	inner_name.str(t_name, USER_NAME_LEN);
	LOG(LOG_DEBUG,"real_name:%s,sid:%s,inner_name:%s|", real_name.str(),sid, t_name);
}

void get_real_username(USER_NAME &real_name, USER_NAME &inner_name)
{	
	char t_name[USER_NAME_BUFF_LEN] = {0};		
	inner_name.str(t_name);
	size_t name_len = strlen(t_name);
	if(name_len > 5)
	{	
		char *c_sid = t_name + (name_len - 5);
		*c_sid = 0;
	}
	real_name.from_str(t_name);		
}

class CSessionMap
{
public:
	
	enum USER_STATE
	{
		USER_STATE_AUTHED = 1
	};
	
	struct USER_ENTRY
	{
		USER_NAME userName;
		USER_KEY userKey;
		unsigned long long sessionID;
		int fd;
		int state;
		char sid[16];		// 在哪个服
		int s_platform;
		time_t lastActiveTime;
	};

	//user鉴权状态
	
	typedef CHashMap<USER_NAME, USER_ENTRY, UserHashType> USER_MAP;
	typedef CHashMap<unsigned long long, USER_NAME> SESSION_MAP;

public:
	CSessionMap()
	{
		m_puserMap = NULL;
		m_inited = false;
	}
	
	~CSessionMap()
	{
		if(m_puserMap==NULL)
		{
			delete m_puserMap;
			m_puserMap = NULL;
		}
	}

	inline USER_MAP* get_user_map()
	{
		return m_puserMap;
	}

	inline SESSION_MAP* get_session_map()
	{
		return m_psessionMap;
	}
	
	int init(unsigned int shmKey, size_t userNumMax, size_t hashNum)
	{
		bool format = false;
		size_t sessionSize = SESSION_MAP::mem_size(userNumMax, hashNum);
		size_t userSize = USER_MAP::mem_size(userNumMax, hashNum);
		size_t totalSize = sessionSize+userSize;
		int ret = m_shm.get(shmKey,totalSize);
		if(ret == m_shm.SHM_EXIST)
		{
			if(m_shm.get_shm_size() != totalSize)
			{
				LOG(LOG_INFO, "getshm(key=0x%x) size not "PRINTF_FORMAT_FOR_SIZE_T, shmKey, totalSize);
				if(m_shm.remove(shmKey)!=m_shm.SUCCESS)
				{
					LOG(LOG_ERROR, "remove(key=0x%x) fail", shmKey);
					return -1;
				}
				
				ret = m_shm.get(shmKey, totalSize);
				format = true;
			}
		}
		else if(ret == m_shm.SUCCESS)
		{
			format = true;
		}

		if(ret == m_shm.ERROR)
		{
			LOG(LOG_ERROR, "getshm(key=%u) %s", shmKey, m_shm.errmsg());
			return -1;
		}


		char* start = (char*)(m_shm.get_mem());
		if(format)
		{
			USER_MAP::clear(start);
			SESSION_MAP::clear(start+userSize);
		}
		m_puserMap = new USER_MAP(start, userSize, userNumMax, hashNum);
		m_psessionMap = new SESSION_MAP(start+userSize, sessionSize, userNumMax, hashNum);

		if(m_puserMap==NULL || m_psessionMap == NULL )
		{
			LOG(LOG_ERROR, "new map fail");
			return -1;
		}

		if(!m_puserMap->valid())
		{
			LOG(LOG_ERROR, "m_puserMap fail %d %s", m_puserMap->m_err.errcode, 
				m_puserMap->m_err.errstrmsg);
			return -1;
		}
		
		if(!m_psessionMap->valid())
		{
			LOG(LOG_ERROR, "m_psessionMap fail %d %s", m_psessionMap->m_err.errcode, 
				m_psessionMap->m_err.errstrmsg);
			return -1;
		}

		m_inited = true;
		
		return 0;
	}


	//检查链接对用户是否已经鉴权过了
	//checkResult 返回结果
	//0=ok, -1=fail
	int check_authed(unsigned long long sessionID, int fd, USER_NAME& userName, bool& checkResult,
		char *sid, int * platform)
	{
		USER_ENTRY entry;
		checkResult = false;
		int ret = get_user(userName, entry);
		if(ret < 0)
		{
			return -1;
		}
		else if(ret == 1)
		{
			if(sessionID == entry.sessionID && fd == entry.fd && entry.state == USER_STATE_AUTHED)
			{
				checkResult = true;
				entry.lastActiveTime = time(NULL);
			}

			if(sid != NULL)
			{
				memcpy(sid, entry.sid, sizeof(entry.sid));
			}
			if(platform != NULL)
			{
				*platform = entry.s_platform;
			}
		}
		else
		{
			LOG(LOG_ERROR, "%s not in authed map", userName.str());
			return false;
		}

		return 0;
	}

	//通过userName查找链接，回包使用
	//sessionID返回查找到的id，=0没找到,=1找到
	//0=ok, -1=fail
	int find_session(USER_NAME& userName, unsigned long long &sessionID, int &fd)
	{
		USER_NAME real_name;
		get_real_username(real_name, userName);
		USER_ENTRY entry;
		sessionID = 0;
		
		int ret = get_user(real_name, entry);
		if(ret < 0)
		{
			return -1;
		}
		else if(ret == 1)
		{
			sessionID = entry.sessionID;
			fd = entry.fd;
		}
		
		return ret;
	}

	//根据sessionID查找userName
	//return =1的时候userName
	inline int force_close_session(unsigned long long sessionID, USER_NAME& userName, char *sid)
	{
		int ret = del_session(sessionID, &userName);
		if(ret < 0)
		{
			return -1;
		}
		else if(ret == 0)
		{
			return 0;
		}

		USER_ENTRY entry;
		get_user(userName, entry);
		memcpy(sid, entry.sid, sizeof(entry.sid));
		
		unsigned long long needCloseSession;
		int needCloseFd;
		del_authed_user(userName,needCloseSession,needCloseFd, sessionID);
		if(needCloseSession != sessionID)
		{
			LOG(LOG_INFO, "force_close_session(%llu) but entry session = %llu", sessionID, needCloseSession);
		}
		
		return 1;
	}

	//用户已经下线
	//needCloseSession 返回需要关闭的链接,needCloseSession==0则不需要删
	//deletedsession是在调用force_close_session时填写的，防止重复删session
	//0=ok, -1=fail
	int del_authed_user(USER_NAME& userName, unsigned long long &needCloseSession, int& needCloseFd, unsigned long long deletedsession = 0)
	{
		USER_ENTRY oldEntry;
		needCloseSession =0 ;
		int ret = del_user(userName, &oldEntry);
		if(ret < 0)
		{
			return -1;
		}
		else if(ret == 1)
		{
			needCloseSession = oldEntry.sessionID;
			needCloseFd = oldEntry.fd;

			if(needCloseSession != deletedsession)
			{
				ret = del_session(needCloseSession, NULL);
				if(ret < 0)
				{
					LOG(LOG_INFO, "del_session for %llu should ok", needCloseSession);
				}
			}
		}

		return 0;
	}

	//插入已鉴权的用户
	//needCloseSession 返回需要关闭的链接
	//0=ok, -1=fail
	int set_authed_user(USER_NAME& userName, USER_KEY& key, unsigned long long sessionID, int fd, 
		unsigned long long &needCloseSession,int& needCloseFd, const char *sid, int s_platform = 0)
	{
		USER_ENTRY oldEntry;
		USER_ENTRY newEntry;
		needCloseSession = 0;
		newEntry.sessionID = sessionID;
		newEntry.fd = fd;
		newEntry.userName = userName;
		newEntry.userKey = key;
		newEntry.state = USER_STATE_AUTHED;
		size_t sid_len = strlen(sid);
		unsigned int i = 0;
		if(sid_len < 5)
		{
			for(; i < (5 - sid_len); ++i)
				newEntry.sid[i] = '0';
			strncpy(newEntry.sid + i, sid, 5-i);
		}
		else
		{
			strncpy(newEntry.sid, sid, 5);
		}
		newEntry.s_platform = s_platform;
		newEntry.lastActiveTime = time(NULL);

		//设置user新的鉴权信息
		int ret = set_user(userName, newEntry, &oldEntry);
		if(ret < 0)
		{
			return -1;
		}

		if(ret == 1)
		{
			//存在老的登录鉴权信息，并且不是从这个链接来的
			if(oldEntry.sessionID != sessionID)
			{
				//不能从多个链接上登录
				//从索引中删除旧session
				//并通知外面关闭之
				needCloseSession = oldEntry.sessionID; 
				needCloseFd = oldEntry.fd;

				if(del_session(oldEntry.sessionID, NULL) < 0)
				{
					LOG(LOG_INFO, "set_authed_user del old session(%llu) fail", oldEntry.sessionID);
				}
			}
		}

		//不管以前session有没有都set一下
		USER_NAME oldName;
		ret = set_session(sessionID,userName,&oldName);
		if(ret < 0)
		{
			//失败回滚
			del_user(userName);
			return -1;
		}
		else if(ret == 1)
		{
			if(oldName != userName)
			{
				//这里可能是同一条链接用了多个user登录...
				//主动关闭的logout会丢失
				LOG(LOG_INFO, "set_authed_user set_session() ignore old user %s", oldName.str());
			}
		}
	
		return 0;
	}


	/* =0 no exist =1 ok <0 fail*/
	int get_user(USER_NAME& stName, USER_ENTRY& entry)
	{
		int ret = m_puserMap->get_node(stName, entry);
		if(ret < 0)
		{
			LOG(LOG_ERROR, "m_puserMap->get_node(%s) fail %d %s", 
				stName.str(),m_puserMap->m_err.errcode, m_puserMap->m_err.errstrmsg);
			return -1;
		}
		
		return ret;
	}

	/*=0 set new =1 set old <0 fail*/
	int set_user(USER_NAME& stName, USER_ENTRY& entry, USER_ENTRY* pold_entry = NULL)
	{
		int ret = m_puserMap->set_node(stName, entry, pold_entry);
//LOG(LOG_INFO, "MAP|user|set|%d|%s", ret, stName.str());
		if(ret < 0)
		{
			LOG(LOG_ERROR, "m_puserMap->set_node(%s) fail %d %s", 
				stName.str(),m_puserMap->m_err.errcode, m_puserMap->m_err.errstrmsg);
			return -1;
		}
		
		return ret;
		
	}

	/*=0 not exist  =1 ok <0 fail*/
	int del_user(USER_NAME& stName, USER_ENTRY* pold_entry = NULL)
	{
		int ret = m_puserMap->del_node(stName, pold_entry);
//LOG(LOG_INFO, "MAP|user|del|%d|%s", ret, stName.str());
		if(ret < 0)
		{
			LOG(LOG_ERROR, "m_puserMap->set_node(%s) fail %d %s", 
				stName.str(), m_puserMap->m_err.errcode, m_puserMap->m_err.errstrmsg);
			return -1;
		}
		
		return ret;
	}

	/* =0 no exist =1 ok <0 fail*/
	int get_session(unsigned long long sessionID, USER_NAME& name)
	{
		int ret = m_psessionMap->get_node(sessionID, name);
		if(ret < 0)
		{
			LOG(LOG_ERROR, "m_psessionMap->get_node(%llu) fail %d %s", 
				sessionID, m_psessionMap->m_err.errcode, m_psessionMap->m_err.errstrmsg);
			return -1;
		}

		return ret;
	}

	/*=0 set new =1 set old <0 fail*/
	int set_session(unsigned long long sessionID, USER_NAME& name, USER_NAME *poldName)
	{
		int ret = m_psessionMap->set_node( sessionID, name, poldName);
//LOG(LOG_INFO, "MAP|session|set|%d|%s", ret, name.str());
		if(ret < 0)
		{
			LOG(LOG_ERROR, "m_psessionMap->set_node(%llu) fail %d %s", 
				sessionID, m_psessionMap->m_err.errcode, m_psessionMap->m_err.errstrmsg);
			return -1;
		}

		return ret;
	}

	/*=0 not exist	=1 ok <0 fail*/
	int del_session(unsigned long long sessionID, USER_NAME *poldName)
	{
		int ret = m_psessionMap->del_node(sessionID, poldName);
//LOG(LOG_INFO, "MAP|session|del|%d|xxx", ret);
		if(ret < 0)
		{
			LOG(LOG_ERROR, "m_psessionMap->det_node(%llu) fail %d %s", 
				sessionID, m_psessionMap->m_err.errcode, m_psessionMap->m_err.errstrmsg);
			return -1;
		}

		return ret;
	}

public:
	class CSessionUserVisitor: public CHashMapVisitor<USER_NAME, USER_ENTRY>
	{
	public:
		CSessionUserVisitor()
		{
			m_count = 0;
		}
		virtual ~CSessionUserVisitor(){}
		virtual int call(const USER_NAME& key, USER_ENTRY& val, int callTimes) 
		{
			if(TIMEOUT+val.lastActiveTime < time(NULL))
			{
				//除掉
				shouldDelete = true;
				m_sessionMap->del_node(val.sessionID);
				++m_count;
			}
	
			return 0;
		}
	public:
		int TIMEOUT;
		int m_count;
		SESSION_MAP* m_sessionMap;
	};

	class CSessionMapVisitor: public CHashMapVisitor<unsigned long long, USER_NAME>
		{
		public:
			CSessionMapVisitor()
			{
				m_count = 0;
			}
			virtual ~CSessionMapVisitor(){}
			virtual int call(const unsigned long long& key, USER_NAME& val, int callTimes) 
			{
				int ret = m_userMap->get_node(val, m_tmpEntry);
				if(ret==0)
				{
					shouldDelete = true;
					++m_count;
				}
				else if(ret == 1)
				{
					if(m_tmpEntry.sessionID != key)
					{
						shouldDelete = true;
						++m_count;
					}
				}
					
				return 0;
			}
		public:
			int m_count;
			USER_MAP* m_userMap;
			USER_ENTRY m_tmpEntry;
		};


	int cleanTimeoutNode(int timeout)
	{
		if(!m_inited)
			return -1;
		
		CSessionUserVisitor visitor;
		visitor.TIMEOUT = timeout;
		visitor.m_sessionMap = m_psessionMap;
		m_puserMap->for_each_node(&visitor);
		LOG(LOG_INFO,"SESSION_USER_TIMEOUT|count=%d", visitor.m_count);

		CSessionMapVisitor mapv;
		mapv.m_userMap = m_puserMap;
		m_psessionMap->for_each_node(&mapv);
		LOG(LOG_INFO,"SESSION_MAP_INVALID|count=%d", mapv.m_count);
		return 0;
	}

protected:
	SESSION_MAP* m_psessionMap;
	USER_MAP* m_puserMap;
	CShmWrapper m_shm;
	bool m_inited;
};

#endif

