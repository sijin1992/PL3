#include "../dbsvr/leitaimap.h"
#include <stdlib.h>
#include <iostream>
using namespace std;
int main(int argc, char** argv)
{
	if(argc < 2)
	{
		cout << argv[0] << ": leitailvl" << endl;
		return -1;
	}

	int leitailvl = atoi(argv[1]);
	int num = LEITAI_NUM_MAX*LEITAI_USERNUM_FULL/LEITAI_RCDS_PER_NODE;
	
	CLeitaimap leitai;
	int ret = leitai.init(leitailvl, num, num);
	if(ret != 0)
	{
		cout << "init fail" << endl;
		return -1;
	}

	LEITAI_HEAD* phead = leitai.get_head();

	for(int i=0; i<1000; ++i)
	{
		char buff[8] = {0};
		snprintf(buff, sizeof(buff), "u%d", i+1);
		USER_NAME user;
		user.from_str(buff);
		int rank;
		ret = leitai.insert_user(0, user,1,10,rank);
		if(ret != 0)
		{
			cout << "insert user " << user.to_str() << " fail" << endl;
			return -1;
		}
		cout << "insert user " << user.to_str() << " rank=" << rank << endl;
	}

	int rankRet1;
	int rankRet2;
	USER_NAME user1;
	USER_NAME user2;
	user1.from_str("u109");
	user2.from_str( "u100");
	ret = leitai.exchange_rank(0,user1 , 100, user2, 91, rankRet1, rankRet2, 12);
	if(ret != 0)
	{
		cout << "exchange fail" << endl;
		return -1;
	}

	cout << "exchang ok rank1=" << rankRet1 << " rank2=" << rankRet2 << endl;
	
	return 0;
}

