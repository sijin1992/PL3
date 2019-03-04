#include "mysqltest.h"
#include <stdlib.h>
#include <stdio.h>

int main(int argc, char** argv)
{
	CTestMysql theTest;

	int maxnum = 100000;
	int selectnum = 10000;
	int updatenum = 10000;
	int datalen = 100;
	char ip[16] = {""};
	char user[32] = {""};
	char passwd[64] = {""};
	char dbname[64] = {""};
	char tablename[64] = {""};
	int port = 0;
	char sock[256] = {""};

	char * p;
	p = getenv("TABLE_RCD_NUM");
	if(p)
		maxnum = atoi(p);

	p = getenv("SELECT_QUREY_NUM");
	if(p)
		selectnum = atoi(p);

	p = getenv("UPDATE_QUREY_NUM");
	if(p)
		updatenum = atoi(p);

	p = getenv("DATA_LEN");
	if(p)
		datalen = atoi(p);
		
	p = getenv("TABLE_NAME");
	if(p)
		snprintf(tablename, sizeof(tablename), "%s", p);

	p = getenv("DB_HOST");
	if(p)
		snprintf(ip, sizeof(ip), "%s", p);

	p = getenv("DB_USER");
	if(p)
		snprintf(user, sizeof(user), "%s", p);

	p = getenv("DB_PASSWD");
	if(p)
		snprintf(passwd, sizeof(passwd), "%s", p);

	p = getenv("DB_NAME");
	if(p)
		snprintf(dbname, sizeof(dbname), "%s", p);

	p = getenv("DB_SOCK");
	if(p)
		snprintf(sock, sizeof(sock), "%s", p);

	p = getenv("DB_PORT");
	if(p)
		port = atoi(p);

	if(argc < 2)
	{
		cout << argv[0] << " [insert|update|select]" << endl << endl;
		cout << "envs:" << endl;
		cout << "export TABLE_RCD_NUM=" << endl;
		cout << "export SELECT_QUREY_NUM=" << endl;
		cout << "export UPDATE_QUREY_NUM=" << endl;
		cout << "export DATA_LEN=" << endl;
		cout << "export TABLE_NAME=" << endl;
		cout << "export DB_HOST=" << endl;
		cout << "export DB_USER=" << endl;
		cout << "export DB_PASSWD=" << endl;
		cout << "export DB_NAME=" << endl;
		cout << "export DB_SOCK=" << endl;
		cout << "export DB_PORT=" << endl;
		cout << endl;
		cout << "table defines in test_db.sql" << endl;
		return 0;
	}

	if(theTest.init(ip, user, passwd, dbname, port, sock, maxnum, tablename) !=0)
		return -1;

	string cmd =argv[1];
	if(cmd == "insert")
	{
		if(theTest.do_insert(datalen, maxnum/100)!=0)
			return -1;
	}
	else if(cmd == "select")
	{
		if(theTest.do_select(selectnum)!=0)
			return -1;
	}
	else if(cmd == "update")
	{
		if(theTest.do_update(updatenum, datalen)!=0)
			return -1;
	}
	else
	{
		cout << "bad cmd: " << cmd << endl;
	}
	
	return 0;
}

