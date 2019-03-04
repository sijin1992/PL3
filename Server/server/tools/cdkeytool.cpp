#include "../dbsvr/tc_wrap.h"
#include "../flagsvr/flag_svr_def.h"
#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
using namespace std;

void trip_line(string& str)
{
        size_t pos = str.rfind('\r');
        if(pos != string::npos)
                str = str.substr(0, pos);
}

int main(int argc, char** argv)
{
	if(argc < 4)
	{
		cout << argv[0] << " input_file(user per line) cdkid giftid" << endl;
		return 0;
	}

	int bucketNum = 1000000;
	int giftid = atoi(argv[3]);

	ifstream inf(argv[1]);
	if(!inf.good())
	{
		cout << "open input_file " << argv[1] << " fail" << endl;
		return 0;
	}
	
	CTCHDBWrap tchandle;
	int linenum = 0;
	char path[64] = {0};
	snprintf(path, sizeof(path), "cdkey_%d", atoi(argv[2]));
	TCHDB* tc = tchandle.open(bucketNum, path);
	if(tc == NULL)
	{
		tchandle.print_last_error();
		return -1;
	}

	CDKEY_DATA data;
	data.giftid = giftid;
	data.state = 0;
	CDKEY_DATA readdata;
	
	while(true)
	{
		 string linestr;
	        getline(inf, linestr);
	        if(inf.eof())
	        {
	                break;
	        }
	        else if(inf.fail())
	        {
			cout << "linenum[" << linenum+1 << "] fail" << endl;
			break;
	        }
	        
	        trip_line(linestr);

		istringstream instr(linestr);
		string user;
		instr >> user;
		if(instr.fail())
		{
			cout << "linenum[" << linenum+1 << "](" << linestr << ") parse fail " << endl;
			break;
		}
		
		++linenum;

		int len = tchdbget3(tc, user.c_str(), user.length(), (char*)&readdata, sizeof(readdata)); 
		if(len < 0)
		{
			if(tchdbecode(tc) != 22) 
			{
				tchandle.print_last_error();
				cout << "linenum[" << linenum+1 << "](" << linestr << ") check fail " << endl;
				return -1;
			}
		}
		else
		{
			cout << "linenum[" << linenum+1 << "](" << linestr << ") already in tc" << endl;
			return -1;
		}

		if(!tchdbput(tc, user.c_str(), user.length(), (char*)&data, sizeof(data)) )
		{
			tchandle.print_last_error();
			cout << "linenum[" << linenum+1 << "](" << linestr << ") add fail " << endl;
			return -1;
		}
	}

	cout << linenum << " user added to list" << endl;
	
	return 0;
}

