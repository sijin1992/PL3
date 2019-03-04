#include "../main_logic/neiceuser.h"
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
	if(argc < 2)
	{
		cout << argv[0] << " input_file(user per line)" << endl;
		return 0;
	}

	ifstream inf(argv[1]);
	if(!inf.good())
	{
		cout << "open input_file " << argv[1] << " fail" << endl;
		return 0;
	}
	
	CHashedUserList thelist;
	if(thelist.init("neice.user", 20000) !=0)
	{
		cout << "list init fail " << endl;
		return 0;
	}

	cout << "output to neice.user 20000" << endl;
	int linenum = 0;
	USER_NAME thekey;
	
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
		int level;
		instr >> user;
		if(instr.fail())
		{
			cout << "linenum[" << linenum+1 << "](" << linestr << ") parse fail " << endl;
			break;
		}
		
		instr >> level;
		if(instr.fail())
		{
			cout << "linenum[" << linenum+1 << "](" << linestr << ") parse fail " << endl;
			break;
		}
		
		++linenum;
	        thekey.from_str(user);
	        if(thelist.add_user(thekey, level)!=0)
	        {
	        	cout << "add user " << thekey.str() << " fail" << endl;
	        	break;
	        }
	}

	cout << linenum << " user added to list" << endl;
	
	return 0;
}

