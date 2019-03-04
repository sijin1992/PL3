#ifndef __LINKER_CONFIG_H__
#define __LINKER_CONFIG_H__
#include "ini/ini_file.h"
#include "log/log.h"
#include "net/tcpwrap.h"
#include <vector>
#include <iostream>
#include <string.h>

using namespace std;

struct LINKER_CONF_QUEUE
{
	unsigned int queueID;
	unsigned int svrID;
	bool active;

	int read_from_ini(CIniFile& oIni, const char* sector)
	{
		if(oIni.GetInt(sector, "QUEUE_GLOBE_ID", 0, &queueID)!=0)
		{
			LOG(LOG_ERROR, "%s.QUEUE_GLOBE_ID not found",sector);
			return -1;
		}

		char sbuff[32] = {0};
		if(oIni.GetString(sector, "BIND_SVR", "", sbuff, sizeof(sbuff))!=0)
		{
			LOG(LOG_ERROR, "%s.BIND_SVR not found", sector);
			return -1;
		}

		if(CTcpSocket::str_to_addr(sbuff, svrID) != 0)
		{
			LOG(LOG_ERROR, "%s.BIND_SVR(%s) not valid", sector, sbuff);
			return -1;
		}

		int iactive;
		if(oIni.GetInt(sector, "ACTIVE", 0, &iactive)!=0)
		{
			LOG(LOG_ERROR, "%s.ACTIVE not found",sector);
			return -1;
		}

		if(iactive)
			active = true;
		else
			active = false;

		return 0;
	}

	void debug(ostream& os)
	{
		os << "LINKER_CONF_QUEUE{" << endl;
		os << "queueID|" << queueID << endl;
		os << "svrID|" << CTcpSocket::addr_to_str(svrID) << endl;
		os << "active|" << active << endl;
		os << "}END LINKER_CONF_QUEUE" << endl;
	}
};

struct LINKER_CONF_DES
{
	int port;
	char ip[32];
	unsigned int svrID;

	int read_from_ini(CIniFile& oIni, const char* sector)
	{
		if(oIni.GetInt(sector, "DES_PORT", 0, &port)!=0)
		{
			LOG(LOG_ERROR, "%s.DES_PORT not found",sector);
			return -1;
		}

		memset(ip, 0x0, sizeof(ip));
		if(oIni.GetString(sector, "DES_IP", "", ip, sizeof(ip))!=0)
		{
			LOG(LOG_ERROR, "%s.DES_IP not found", sector);
			return -1;
		}

		char sbuff[32] = {0};
		if(oIni.GetString(sector, "BIND_SVR", "", sbuff, sizeof(sbuff))!=0)
		{
			LOG(LOG_ERROR, "%s.BIND_SVR not found", sector);
			return -1;
		}

		if(CTcpSocket::str_to_addr(sbuff, svrID) != 0)
		{
			LOG(LOG_ERROR, "%s.BIND_SVR(%s) not valid", sector, sbuff);
			return -1;
		}

		return 0;
	}

	void debug(ostream& os)
	{
		os << "LINKER_CONF_DES{" << endl;
		os << "ip|" << ip << endl;
		os << "port|" << port << endl;
		os << "svrID|" << CTcpSocket::addr_to_str(svrID) << endl;
		os << "}END LINKER_CONF_DES" << endl;
	}
};

struct LINKER_SVR_SET
{
	unsigned int id;
	int aliveTimeout;
	vector<unsigned int> vSvrIDs;
	int read_from_ini(CIniFile& oIni, const char* sectorPre, unsigned int theid)
	{
		char sector[32] = {0};
		snprintf(sector, sizeof(sector), "%s_%d", sectorPre, theid);
		int svrIDNum = 0;
		if(oIni.GetInt(sector, "SVR_TOTAL", 0, &svrIDNum)!=0)
		{
			LOG(LOG_ERROR, "%s.SVR_TOTAL not found",sector);
			return -1;
		}

		char sbuff[32] = {0};
		if(oIni.GetString(sector, "ID", "", sbuff, sizeof(sbuff))!=0)
		{
			LOG(LOG_ERROR, "%s.ID not found", sector);
			return -1;
		}

		if(CTcpSocket::str_to_addr(sbuff, id) != 0)
		{
			LOG(LOG_ERROR, "%s.ID(%s) not valid", sector, sbuff);
			return -1;
		}

		vSvrIDs.clear();
		char sItemName[32] = {0};
		unsigned int svrID;
		for(int i=0; i<svrIDNum; ++i)
		{
			snprintf(sItemName, sizeof(sItemName), "SVR_ID_%d", i);
			if(oIni.GetString(sector, sItemName, "", sbuff, sizeof(sbuff))!=0)
			{
				LOG(LOG_ERROR, "%s.%s not found", sector, sItemName);
				return -1;
			}
			
			if(CTcpSocket::str_to_addr(sbuff, svrID) != 0)
			{
				LOG(LOG_ERROR, "%s.%s(%s) not valid", sector, sItemName, sbuff);
				return -1;
			}

			vSvrIDs.push_back(svrID);

			if(oIni.GetInt(sector, "ALIVE_TIME_OUT_MS", 0, &aliveTimeout)!=0)
			{
				LOG(LOG_ERROR, "%s.ALIVE_TIME_OUT_MS not found",sector);
				return -1;
			}
			
		}

		return 0;
	}
	
	void debug(ostream& os)
	{
		os << "LINKER_SVR_SET{" << endl;
		os << "aliveTimeout|" << aliveTimeout << endl;
		os << "id|" << CTcpSocket::addr_to_str(id) << endl;
		os << "svrIDs|";
		for(unsigned int i=0; i<vSvrIDs.size(); ++i)
		{
			if(i!=0)
				os << ",";
			os << CTcpSocket::addr_to_str(vSvrIDs[i]);
		}
		os << endl;
		os << "}END LINKER_SVR_SET" << endl;
	}	
};

struct LINKER_CONF_CMD
{
	int type; //0=random 1=broadcast 2=alive
	//unsigned int svrSet;
	unsigned int cmd;
	unsigned int mask;
	int read_from_ini(CIniFile& oIni, const char* sector, int theType)
	{
		type = theType;

		if(oIni.GetInt(sector, "CMD", 0, &cmd)!=0)
		{
			LOG(LOG_ERROR, "%s.CMD not found",sector);
			return -1;
		}
/*
		if(oIni.GetInt(sector, "SVR_SET", 0, &svrSet)!=0)
		{
			LOG(LOG_ERROR, "%s.SVR_SET not found", sector);
			return -1;
		}
*/
		char sbuff[32] = {0};
		if(oIni.GetString(sector, "MASK", "", sbuff, sizeof(sbuff))!=0)
		{
			LOG(LOG_ERROR, "%s.MASK not found", sector);
			return -1;
		}

		if(CTcpSocket::str_to_addr(sbuff, mask) != 0)
		{
			LOG(LOG_ERROR, "%s.MASK(%s) not valid", sector, sbuff);
			return -1;
		}

		return 0;
	}

	void debug(ostream& os)
	{
		os << "LINKER_CONF_CMD{" << endl;
		os << "cmd|0x" << hex << cmd << dec << endl;
		os << "type|" << type << endl;
		os << "mask|" << CTcpSocket::addr_to_str(mask) << endl;
		os << "}END LINKER_CONF_CMD" << endl;
	}
};

typedef vector<LINKER_CONF_QUEUE> CONF_QUEUE_POOL;
typedef vector<LINKER_CONF_DES> CONF_DES_POOL;
typedef vector<LINKER_CONF_CMD> CONF_CMD_POOL;
typedef vector<LINKER_SVR_SET*> CONF_SVRSET_POOL;

class CLinkerConfig
{
public:
	int read_from_ini(CIniFile& oIni, const char* sectorTL="TCP_LINKER")
	{
		queueConf.clear();
		desConf.clear();
		cmdConf.clear();
		svrSetConf.clear();
		int tmp;
		int i;
		char sector[32] = {0};
		LINKER_CONF_QUEUE tmpQueue;
		LINKER_CONF_DES tmpDes;
		LINKER_CONF_CMD tmpCmd;
		
		if(oIni.GetInt(sectorTL, "LISTEN_PORT", 0, &listenPort)!=0)
		{
			LOG(LOG_ERROR, "%s.LISTEN_PORT not found", sectorTL);
			return -1;
		}

		if(oIni.GetInt(sectorTL, "READ_LIMIT_PER_QUEUE", 0, &readlimitPerQueue)!=0)
		{
			LOG(LOG_ERROR, "%s.READ_LIMIT_PER_QUEUE not found", sectorTL);
			return -1;
		}
		
		memset(listenIP, 0x0, sizeof(listenIP));
		if(oIni.GetString(sectorTL, "LISTEN_IP", "", listenIP, sizeof(listenIP))!=0)
		{
			LOG(LOG_ERROR, "%s.LISTEN_IP not found", sectorTL);
			return -1;
		}


		
		if(oIni.GetInt(sectorTL, "MSG_QUEUE_TOTAL", 0, &tmp)!=0)
		{
			LOG(LOG_ERROR, "%s.MSG_QUEUE_TOTAL not found", sectorTL);
			return -1;
		}

		for(i=0; i<tmp; ++i)
		{
			snprintf(sector, sizeof(sector), "MSG_QUEUE_%d", i);
			if(tmpQueue.read_from_ini(oIni,  sector) != 0)
				return -1;
			queueConf.push_back(tmpQueue);
		}

		if(oIni.GetInt(sectorTL, "DES_TOTAL", 0, &tmp)!=0)
		{
			LOG(LOG_ERROR, "%s.DES_TOTAL not found", sectorTL);
			return -1;
		}
		
		for(i=0; i<tmp; ++i)
		{
			snprintf(sector, sizeof(sector), "DES_%d", i);
			if(tmpDes.read_from_ini(oIni,  sector) != 0)
				return -1;
			desConf.push_back(tmpDes);
		}

		oIni.GetInt(sectorTL, "RANDOM_CMD_TOTAL", 0, &tmp);
	/*	if(oIni.GetInt(sectorTL, "RANDOM_CMD_TOTAL", 0, &tmp)!=0)
		{
			LOG(LOG_ERROR, "%s.RANDOM_CMD_TOTAL not found", sectorTL);
			return -1;
		}*/
		
		for(i=0; i<tmp; ++i)
		{
			snprintf(sector, sizeof(sector), "RANDOM_CMD_%d", i);
			if(tmpCmd.read_from_ini(oIni, sector, 0) != 0)
				return -1;
			cmdConf.push_back(tmpCmd);
		}

		oIni.GetInt(sectorTL, "BROADCAST_CMD_TOTAL", 0, &tmp);
	/*	if(oIni.GetInt(sectorTL, "BROADCAST_CMD_TOTAL", 0, &tmp)!=0)
		{
			LOG(LOG_ERROR, "%s.BROADCAST_CMD_TOTAL not found", sectorTL);
			return -1;
		}	*/	

		for(i=0; i<tmp; ++i)
		{
			snprintf(sector, sizeof(sector), "BROADCAST_CMD_%d", i);
			if(tmpCmd.read_from_ini(oIni, sector, 1) != 0)
				return -1;
			cmdConf.push_back(tmpCmd);
		}

		oIni.GetInt(sectorTL, "ALIVE_CMD_TOTAL", 0, &tmp);
	/*	if(oIni.GetInt(sectorTL, "ALIVE_CMD_TOTAL", 0, &tmp)!=0)
		{
			LOG(LOG_ERROR, "%s.ALIVE_CMD_TOTAL not found", sectorTL);
			return -1;
		}	*/	

		for(i=0; i<tmp; ++i)
		{
			snprintf(sector, sizeof(sector), "ALIVE_CMD_%d", i);
			if(tmpCmd.read_from_ini(oIni, sector, 2) != 0)
				return -1;
			cmdConf.push_back(tmpCmd);
		}

		unsigned int total = 0;
		oIni.GetInt(sectorTL, "SVRSET_TOTAL", 0, &total);
		if(check_svrset_conf(oIni, total) != 0)
			return -1;

		return 0;
	}

	~CLinkerConfig()
	{
		CONF_SVRSET_POOL::iterator svrSetIt;
		for(svrSetIt = svrSetConf.begin(); svrSetIt != svrSetConf.end(); ++svrSetIt)
		{
			delete *svrSetIt;
		}
	}

	void debug(ostream& os)
	{
		CONF_QUEUE_POOL::iterator queueIt;
		CONF_DES_POOL::iterator desIt;
		CONF_CMD_POOL::iterator cmdIt;
		CONF_SVRSET_POOL::iterator svrSetIt;
		os << "CLinkerConfig{" << endl;
		os << "listenIP|" << listenIP << endl;
		os << "listenPort|" << listenPort << endl;
		os << "readlimitPerQueue|" << readlimitPerQueue << endl;

		os << "-------------- queue -----------" << endl;
		for(queueIt = queueConf.begin(); queueIt != queueConf.end(); ++queueIt)
		{
			queueIt->debug(os);
		}
		
		os << "-------------- des svr -----------" << endl;
		for(desIt = desConf.begin(); desIt != desConf.end(); ++desIt)
		{
			desIt->debug(os);
		}
		
		os << "-------------- commands -----------" << endl;
		for(cmdIt = cmdConf.begin(); cmdIt != cmdConf.end(); ++cmdIt)
		{
			cmdIt->debug(os);
		}

		os << "-------------- svr set -----------" << endl;
		for(svrSetIt = svrSetConf.begin(); svrSetIt != svrSetConf.end(); ++svrSetIt)
		{
			(*svrSetIt)->debug(os);
		}
		
		os << "}END CLinkerConfig" << endl;
	}

protected:
	int check_svrset_conf(CIniFile& oIni, unsigned int total)
	{
		LINKER_SVR_SET* ptmpSvrSet;
		for(unsigned int i=0; i<total; ++i)
		{
			ptmpSvrSet = new LINKER_SVR_SET;
			if(!ptmpSvrSet)
			{
				LOG(LOG_ERROR, "new LINKER_SVR_SET fail");
				return -1;
			}
			
			if(ptmpSvrSet->read_from_ini(oIni, "SVR_SET", i)!=0)
				return -1;
			svrSetConf.push_back(ptmpSvrSet);
		}

		return 0;
	}
	
public:
	CONF_QUEUE_POOL queueConf;
	CONF_DES_POOL desConf;
	CONF_CMD_POOL cmdConf;
	CONF_SVRSET_POOL svrSetConf;
	char listenIP[32];
	int listenPort;
	int readlimitPerQueue;
};

#endif

