#ifndef __USER_DISTRIBUTE_H__
#define __USER_DISTRIBUTE_H__
#include "net/tcpwrap.h"
#include "log/log.h"
#include "msg_define.h"
#include "ini/ini_file.h"
#include <iostream>
#include <vector>
using namespace std;


class CUserDistribute
{
public:
	struct DISTRIBUTE_UNIT
	{
		unsigned int svrID;

		int read_from_ini(CIniFile& oIni, const char* sector);
		void debug(ostream& os);
	};
	
	typedef vector<DISTRIBUTE_UNIT> SVR_IDX_VEC;
	
public:
	CUserDistribute()
	{
		m_dbtotal = 0;
	}

	inline int get_svr2(int key, unsigned int& svrID)
	{
		if(m_dbtotal == 0)
		{
			LOG(LOG_ERROR, "m_dbtotal = 0, not inited");
			return -1;
		}
		int idx =key%m_dbtotal;
		svrID = m_array[idx].svrID;
		return 0;
	}

	static inline int db(const USER_NAME & user, unsigned int maxDB)
	{
		UserHashType theHash;
		return theHash.do_hash(user)%maxDB;
	}

	static inline int table(const USER_NAME & user, unsigned int maxDB, unsigned int maxTable)
	{
		UserHashType theHash;
		maxDB = 1;
		return (theHash.do_hash(user)/maxDB)%maxTable;
	}

	inline int get_svr(const USER_NAME & user, unsigned int& svrID)
	{
		if(m_dbtotal == 0)
		{
			LOG(LOG_ERROR, "m_dbtotal = 0, not inited");
			return -1;
		}
		int idx = db(user, m_dbtotal);
		svrID = m_array[idx].svrID;
		return 0;
	}

	int init(CIniFile& oIni, const char* sector);
	void info(ostream& os);

protected:
	unsigned int m_dbtotal;
	SVR_IDX_VEC m_array;
};

#endif

