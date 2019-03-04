#include "user_distribute.h"

int CUserDistribute::DISTRIBUTE_UNIT::read_from_ini	(CIniFile& oIni, const char* sector)
{
	char sbuff[32] = {0};
	if(oIni.GetString(sector, "SVR_ID", "", sbuff, sizeof(sbuff))!=0)
	{
		LOG(LOG_ERROR, "%s.SVR_ID not found", sector);
		return -1;
	}
	
	if(CTcpSocket::str_to_addr(sbuff, svrID) != 0)
	{
		LOG(LOG_ERROR, "%s.SVR_ID(%s) not valid", sector, sbuff);
		return -1;
	}

	return 0;
}

void CUserDistribute::DISTRIBUTE_UNIT::debug(ostream& os)
{
	os << "DISTRIBUTE_UNIT{" << endl;
	os << "svrID|" << CTcpSocket::addr_to_str(svrID) << endl;
	os << "}END DISTRIBUTE_UNIT" << endl;
}

int CUserDistribute::init(CIniFile& oIni, const char* sector)
{
	m_dbtotal = 0;
	if(oIni.GetInt(sector, "DBSVR_TOTAL", 0, &m_dbtotal)!=0)
	{
		LOG(LOG_ERROR, "%s.DBSVR_TOTAL not found",sector);
		return -1;
	}

	char sectorBuff[64] = {0};
	for(unsigned int i=0; i<m_dbtotal; ++i)
	{
		snprintf(sectorBuff, sizeof(sectorBuff), "%s_%d", sector, i);
		DISTRIBUTE_UNIT tmp;
		if(tmp.read_from_ini(oIni, sectorBuff)!=0)
		{
			return -1;
		}

		m_array.push_back(tmp);
	}

	return 0;
}

void CUserDistribute::info(ostream& os)
{
	for(unsigned int i=0; i<m_array.size(); ++i)
	{
		os << "idx=" << i << "|db=" << CTcpSocket::addr_to_str(m_array[i].svrID) << endl;
	}
}


