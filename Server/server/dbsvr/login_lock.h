#ifndef __LOGIN_LOCK_H__
#define __LOGIN_LOCK_H__

/*
* 互斥登录用的，dbsvr的数据是根据user唯一分布的，所以挂在dbsvr上
* login的时候，踢掉非同一台前端svr登录的，logout去掉锁
*/

#include "common/msg_define.h"
#include "struct/hash_map.h"
#include "shm/shm_wrap.h"
#include "ini/ini_file.h"
#include <iostream>
#include "time.h"
#include "net/tcpwrap.h"

struct LOGIN_LOCK_NODE
{
	unsigned int svrID;
};


struct LOGIN_LOCK_CONFIG
{
	void debug(ostream& os)
	{
		os << "LOGIN_LOCK_CONFIG{" << endl;
		os << "shmKey|" << hex << shmKey << dec << endl;
		os << "userNum|" << userNum << endl;
		os << "hashNum|" << hashNum << endl;
		os << "}END LOGIN_LOCK_CONFIG" << endl;
	} 

	int read_from_ini(CIniFile& oIni, const char* sectorName)
	{
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

		return 0;
	}

	key_t shmKey;
	unsigned int userNum;
	unsigned int hashNum;
};

typedef CHashMap<USER_NAME, LOGIN_LOCK_NODE, UserHashType> LOGIN_LOCK_MAP;

class CLoginLock
{
public:
	static const int RET_OK = 0;
	static const int RET_FAIL = -1;
	static const int RET_LOGOUT = -2;
	static const int RET_IGNORE = -3;
public:
	CLoginLock()
	{
		m_pmap = NULL;
		m_inited = false;
	}

	~CLoginLock()
	{
		if(m_pmap)
			delete m_pmap;
	}

	int init(LOGIN_LOCK_CONFIG& config, bool forceFormat)
	{
		bool format;
		size_t totalSize = LOGIN_LOCK_MAP::mem_size(config.userNum, config.hashNum);
		if(forceFormat)
		{
			if(m_shm.remove(config.shmKey)!=m_shm.SUCCESS)
			{
				LOG(LOG_ERROR, "forceFormat remove(key=0x%x) fail", config.shmKey);
				return RET_FAIL;
			}
		}
		
		int ret = m_shm.get(config.shmKey,totalSize);
		if(ret == m_shm.SHM_EXIST)
		{
			if(m_shm.get_shm_size() != totalSize)
			{
				LOG(LOG_ERROR, "getshm(key=0x%x) size not %lu", config.shmKey, totalSize);
				return RET_FAIL;
			}
		}
		else if(ret == m_shm.ERROR)
		{
			LOG(LOG_ERROR, "getshm(key=%u) %s", config.shmKey, m_shm.errmsg());
			return RET_FAIL;
		}
		else
		{
			format = true;
		}

		char* start = (char*)(m_shm.get_mem());
		m_pmap = new LOGIN_LOCK_MAP(start, totalSize, config.userNum, config.hashNum);
		if(!m_pmap) 
		{
			LOG(LOG_ERROR, "new CHashMap fail");
			return RET_FAIL;
		}
		
		if(!(m_pmap->valid()))
		{
			LOG(LOG_ERROR, "CHashMap not valid %d %s", m_pmap->m_err.errcode, m_pmap->m_err.errstrmsg);
			return RET_FAIL;
		}

		m_inited = true;

		return RET_OK;
	}

	int on_login(USER_NAME& user, unsigned int loginSvrID, unsigned int& lastSvrID)
	{
		if(!m_inited)
		{
			LOG(LOG_ERROR, "not inited");
			return RET_FAIL;
		}

		LOGIN_LOCK_NODE* pval;
		if(get_val_point(user, pval) != 0)
			return RET_FAIL;

		if(pval->svrID != 0 && pval->svrID != loginSvrID)
		{
			lastSvrID = pval->svrID;
			return RET_LOGOUT;
		}
		
		pval->svrID = loginSvrID;
		return RET_OK;
	}

	int get_loginsvr(USER_NAME& user, unsigned int& svrID)
	{
		if(!m_inited)
		{
			LOG(LOG_ERROR, "not inited");
			return RET_FAIL;
		}

		unsigned int theIdx;
		int ret = m_pmap->get_node_idx(user,theIdx);
		if(ret < 0)
		{
			LOG(LOG_ERROR, "m_pmap->get_node_idx(%s) fail %d %s", user.str(), m_pmap->m_err.errcode, m_pmap->m_err.errstrmsg);
			return RET_FAIL;
		}
		else if(ret == 0)
		{
			svrID = 0;
		}
		else
		{
			LOGIN_LOCK_NODE* pval = m_pmap->get_val_pointer(theIdx);
			svrID = pval->svrID;
		}
		
		return RET_OK;
	}

	int on_replace (USER_NAME& user, unsigned int loginSvrID, unsigned int logoutSvrID)
	{
		if(!m_inited)
		{
			LOG(LOG_ERROR, "not inited");
			return RET_FAIL;
		}

		LOGIN_LOCK_NODE* pval;
		if(get_val_point(user, pval) != 0)
			return RET_FAIL;

		if(pval->svrID != 0 && pval->svrID != logoutSvrID)
		{
			LOG(LOG_ERROR, "on_replace pval->svrID=%u but logoutSvr=%u",pval->svrID,logoutSvrID);
			return RET_FAIL;
		}
		
		pval->svrID = loginSvrID;
		return RET_OK;
	}

	int on_logout(USER_NAME& user, unsigned int logoutSvrID)
	{
		if(!m_inited)
		{
			LOG(LOG_ERROR, "not inited");
			return RET_FAIL;
		}

		unsigned int theIdx;
		int ret = m_pmap->get_node_idx(user,theIdx);
		if(ret < 0)
		{
			LOG(LOG_ERROR, "m_pmap->get_node_idx(%s) fail %d %s", user.str(), m_pmap->m_err.errcode, m_pmap->m_err.errstrmsg);
			return RET_FAIL;
		}
		else if(ret == 1)
		{
			LOGIN_LOCK_NODE* pval = m_pmap->get_val_pointer(theIdx);
			if(pval->svrID != logoutSvrID && pval->svrID != 0)
			{
				LOG(LOG_ERROR, "onlogout pval->svrID=%u but logoutSvr=%u",pval->svrID,logoutSvrID);
				return RET_IGNORE;
			}

			ret = m_pmap->del_node(user, NULL);
			if(ret < 0)
			{
				LOG(LOG_ERROR, "m_pmap->del_node(%s) fail %d %s", user.str(), m_pmap->m_err.errcode, m_pmap->m_err.errstrmsg);
				return RET_FAIL;
			}
		}

		return RET_OK;
	}

	void info(ostream& out)
	{
		if(m_pmap)
		{
			m_pmap->get_head()->debug(out);
		}
	}

	void info(ostream& out, const char* username)
	{
		if(m_inited)
		{
			USER_NAME user;
			user.str(username, strlen(username));
			unsigned int theIdx;
			int ret = m_pmap->get_node_idx(user,theIdx);
			if(ret == 0)
			{
				out << "no login info" << endl;
			}
			else if(ret > 0)
			{
				LOGIN_LOCK_NODE* pval = m_pmap->get_val_pointer(theIdx);
				out << "login at svr[" << pval->svrID << ":" << CTcpSocket::addr_to_str(pval->svrID) << "]" << endl;
			}
		}
	}

protected:
	inline int get_val_point(USER_NAME& user, LOGIN_LOCK_NODE*& pval)
	{
		unsigned int theIdx;
		int ret = m_pmap->get_node_idx(user,theIdx);
		if(ret < 0)
		{
			LOG(LOG_ERROR, "m_pmap->get_node_idx(%s) fail %d %s", user.str(), m_pmap->m_err.errcode, m_pmap->m_err.errstrmsg);
			return -1;
		}
		else if(ret == 0)
		{
			LOGIN_LOCK_NODE newNode;
			newNode.svrID = 0;
			ret = m_pmap->set_node(user, newNode, NULL, &theIdx);
			if(ret < 0)
			{
				LOG(LOG_ERROR, "m_pmap->set_node_idx(%s) fail %d %s", user.str(), m_pmap->m_err.errcode, m_pmap->m_err.errstrmsg);
				return -1;
			}
		}

		pval = m_pmap->get_val_pointer(theIdx);
		return 0;
	}

protected:
	LOGIN_LOCK_MAP* m_pmap;
	CShmWrapper m_shm;
	bool m_inited;
};

#endif

