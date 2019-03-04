#ifndef __SELECT_SERVER_H__
#define __SELECT_SERVER_H__
#include <vector>
#include <string>

using namespace std;

class CServerSelector
{
protected:
	struct SERVER_INFO
	{
		SERVER_INFO(const string& theip, bool dis=false)
		{
			ip = theip;
			disable = dis;
			count = 0;
		}

		string ip;
		bool disable;
		int count;
	};

	struct SERVER_SETS
	{
		SERVER_SETS(int setidx, const string& sethost)
		{
			idx = setidx;
			host = sethost;
			nowidx = 0;
		}

		int idx;
		vector<SERVER_INFO> servers;
		int nowidx;
		string host;
	};
	
public:
	CServerSelector()
	{
	}
	
	//return idx
	bool get_server(int setidx, string& ip, string& host, bool atlestone = true)
	{
		SERVER_SETS* ptheset = NULL;
		for(unsigned int ii=0; ii<m_serversets.size(); ++ii)
		{
			if(m_serversets[ii].idx == setidx)
			{
				ptheset = &(m_serversets[ii]);
				break;
			}
		}

		if(ptheset == NULL)
		{
			if(m_serversets.size() == 0)
				return false;
			else
				ptheset = &(m_serversets[0]); //使用默认的
		}
		
		int size = ptheset->servers.size();
		if(size == 0)
			return false;

		for(int i=0; i<size; ++i)
		{
			ptheset->nowidx = (ptheset->nowidx+1)%size;
			SERVER_INFO& server = ptheset->servers[ptheset->nowidx];
			if(!server.disable)
			{
				ip = server.ip;
				host = ptheset->host;
				return true;
			}
			else
			{
				if(server.count -- <= 0)
				{
					ip = server.ip;
					host = ptheset->host;
					server.disable = false;
					server.count = 0;
					return true;
				}
			}
		}

		if(atlestone)
		{
			//没有符合要求的随便找一个试试
			SERVER_INFO& server = ptheset->servers[ptheset->nowidx];
			ip = server.ip;
			host = ptheset->host;
			server.disable = false;
			server.count = 0;
			return true;
		}

		return false;
	}

	void disable_server(int setidx, const string& ip, int count=1000)
	{
		SERVER_SETS* ptheset = NULL;
		for(unsigned int ii=0; ii<m_serversets.size(); ++ii)
		{
			if(m_serversets[ii].idx == setidx)
			{
				ptheset = &(m_serversets[ii]);
				break;
			}
		}

		if(ptheset == NULL)
		{
			return;
		}
		
		for(unsigned int i=0; i<ptheset->servers.size(); ++i)
		{
			if(ip == ptheset->servers[i].ip)
			{
				//允许重复
				ptheset->servers[i].disable = true;
				ptheset->servers[i].count = count;
			}
		}
	}

	void add_server(int setidx, const string& ip, const string& sethost)
	{
		SERVER_SETS* ptheset = NULL;
		for(unsigned int ii=0; ii<m_serversets.size(); ++ii)
		{
			if(m_serversets[ii].idx == setidx)
			{
				ptheset = &(m_serversets[ii]);
				break;
			}
		}

		if(ptheset == NULL)
		{
			SERVER_SETS newsets(setidx, sethost);
			m_serversets.push_back(newsets);
			ptheset = &(m_serversets[m_serversets.size()-1]);
		}

		
		ptheset->servers.push_back(SERVER_INFO(ip));
	}

protected:
	vector<SERVER_SETS> m_serversets;
};

#endif

