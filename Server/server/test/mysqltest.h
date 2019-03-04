#ifndef __TEST_MYSQL_H__
#define __TEST_MYSQL_H__
/**
* mysql–‘ƒ‹≤‚ ‘
*/
#include "mysql_wrap/mysql_wrap.h"
#include "time/calculagraph.h"
#include <iostream>
#include <string.h>
#include <stdio.h>

using namespace std;


class CTestMysql
{
public:
#define START_QUERY_TIME gettimeofday(&start_t, NULL);
#define END_QUERY_TIME gettimeofday(&end_t, NULL); \
		m_interval = (end_t.tv_sec - start_t.tv_sec)*1000 + (end_t.tv_usec - start_t.tv_usec)/1000;

	class CTestMysqlTimeStat
	{
		public:
			CTestMysqlTimeStat()
			{
				cnt = 0;
				maxtime = 0;
				mintime = 0;
				totaltime =0;
			}

			void add(int ms)
			{
				++cnt;
				if(ms > maxtime)
				{
					maxtime = ms;
				}

				if(mintime ==0 || ms < mintime)
				{
					mintime = ms;
				}

				totaltime += ms;
			}

			void output(ostream& out)
			{
				out << "cnt=" << cnt << endl;
				out << "totaltime=" << totaltime << "ms" << endl;
				out << "maxtime=" << maxtime << "ms" << endl;
				out << "mintime=" << mintime << "ms" << endl;
			}
			
		public:
			int cnt;
			int maxtime;
			int mintime;
			int totaltime;
	};
	
	int init(const char* ip, const char* user, const char* passwd, const char* dbname, int port, 
			const char* sock, int maxnum, const char* tablename)
	{
		if( m_db.Connect(ip, user, passwd, dbname, port, false, sock) != 0)
		{
			cout << "db Connect fail " << m_db.GetErr() << endl;
			return -1;
		}

		m_maxnum = maxnum;

		m_tablename = tablename;

		return 0;
	}

	int do_insert(int datasize, int batchnum)
	{
		cout << "---------insert total " << m_maxnum << "----------" << endl;
		if(datasize > 200*1024)
			datasize = 200*1024;
		
		char* data = new char[datasize];
		memset(data, 'a', datasize-1);
		data[datasize -1] = 0;
		CCalculagraph cal(cout);
		CCalculagraph caltotal(cout);
		CTestMysqlTimeStat ts;
		for(int idx=1; idx<=m_maxnum; ++idx)
		{
			unsigned long sqllen = snprintf(m_sqlbuff, sizeof(m_sqlbuff), "insert into %s(user_name, user_data) values('%d','%s')",
				m_tablename.c_str(), idx, data);
			int affectedRows = 0;

			START_QUERY_TIME
			if(m_db.Query(m_sqlbuff, sqllen, NULL, &affectedRows) !=0)
				cout << "theDB->Query: " << m_db.GetErr() << endl;
			END_QUERY_TIME
			ts.add(m_interval);

			if(idx%batchnum == 0)
			{
				cout << "at " << idx << ": ";
				cal.stop();
				cal.restart();
				cout << endl;
			}
		}

		cout << "total time: ";
		caltotal.stop();
		cout << endl;
		delete[] data;

		cout << "query time stat:" << endl;
		ts.output(cout);
		
		return 0;
	}

	int do_select(int num)
	{
		cout << "-----------select " << num << "--------" << endl;
		CCalculagraph caltotal(cout);
		CTestMysqlTimeStat ts;
		for(int idx=1; idx<=num; ++idx)
		{
			unsigned long sqllen = snprintf(m_sqlbuff, sizeof(m_sqlbuff), "select * from %s where user_name='%d';",
				m_tablename.c_str(), rand()%m_maxnum);
			int affectedRows = 0;
			MysqlResult result;
			START_QUERY_TIME
			if(m_db.Query(m_sqlbuff, sqllen, &result, &affectedRows) !=0)
				cout << "theDB->Query: " << m_db.GetErr() << endl;
			END_QUERY_TIME
			ts.add(m_interval);
		}
		
		cout << "total time: ";
		caltotal.stop();
		cout << endl;

		cout << "query time stat:" << endl;
		ts.output(cout);

		return 0;
	}

	int do_update(int num, int datasizemax)
	{
		cout << "-----------update " << num << "--------" << endl;
		char* data = new char[datasizemax];
		memset(data, 'a', datasizemax-1);
		data[datasizemax -1] = 0;
		CCalculagraph caltotal(cout);
		CTestMysqlTimeStat ts;
		for(int idx=1; idx<=num; ++idx)
		{
			unsigned long sqllen = snprintf(m_sqlbuff, sizeof(m_sqlbuff), "update %s set user_data='%s' where user_name='%d';",
				m_tablename.c_str(), data, rand()%m_maxnum);
			int affectedRows = 0;
			START_QUERY_TIME
			if(m_db.Query(m_sqlbuff, sqllen, NULL, &affectedRows) !=0)
				cout << "theDB->Query: " << m_db.GetErr() << endl;
			END_QUERY_TIME
			ts.add(m_interval);
		}
		
		cout << "total time: ";
		caltotal.stop();
		cout << endl;
		delete[] data;

		cout << "query time stat:" << endl;
		ts.output(cout);

		return 0;
	}
	
protected:
	MysqlDB m_db;
	char m_sqlbuff[201*1024];
	int m_maxnum;
	timeval start_t;
	timeval end_t;
	int m_interval;
	static const int SLOW_MS=1000;
	string m_tablename;
};

#endif

