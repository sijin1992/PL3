#include "../dbsvr/tc_wrap.h"
#include "../flagsvr/flag_svr_def.h"
#include <iostream>
#include <string>
using namespace std;

int main(int argc, char** argv)
{
	if(argc < 4)
	{
		cout << argv[0] << " file get $cdkey" << endl;
		//cout << argv[0] << " file set $cdkey" << endl;
		//cout << argv[0] << " file reset $cdkey" << endl;
		return 0;
	}

	string cmd = argv[2];
	string cdkey = argv[3];

	CDKEY_DATA readdata;
	CTCHDBWrap tchandle;
	int bucketNum = 1000000;
	TCHDB* tc = tchandle.open(bucketNum, argv[1]);
	if(tc == NULL)
	{
		tchandle.print_last_error();
		return -1;
	}

	if(cmd == "get")
	{
		int len = tchdbget3(tc, cdkey.c_str(), cdkey.length(), (char*)&readdata, sizeof(readdata)); 
		if(len < 0)
		{
			if(tchdbecode(tc) != 22) 
			{
				tchandle.print_last_error();
			}
			else
			{
				cout << "no data" << endl;
			}
		}
		else
		{
			cout << "gift id="<< readdata.giftid << ", state=" << readdata.state << endl;
		}
	}
	/*
	else if(cmd == "set")
	{

		if(!tchdbput(tc, user.c_str(), user.length(), (char*)&data, sizeof(data)) )
		{
			tchandle.print_last_error();
			cout << "linenum[" << linenum+1 << "](" << linestr << ") add fail " << endl;
			return -1;
		}
	}*/

	return 0;
}

