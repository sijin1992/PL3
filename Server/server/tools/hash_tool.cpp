#include "common/user_distribute.h"
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
using namespace std;

int main(int argc, char** argv)
{
	if(argc < 4)
	{
		cout << argv[0] << " user dbModulesNum tableModulesNum" << endl;
		return 0;
	}
	USER_NAME user;
	user.from_str(argv[1]);
	int dbMod = atoi(argv[2]);
	int tableMod = atoi(argv[3]);
	int tableIdx = CUserDistribute::table(user, dbMod, tableMod);
	int dbIdx = CUserDistribute::db(user, dbMod);
	cout << "in db_" << dbIdx << " table_" << tableIdx << endl;

/*
	USER_NAME_BYTE bytename;
	user.tobyte(bytename);
	string akey;
	akey.assign((char*)bytename.val, sizeof(bytename.val));
	cout << "user=" << user.str() << " hex:" << CBinaryUtil::bin_hex(user.val, sizeof(user.val), " ")<< endl;
	cout << "bytename hex:" << CBinaryUtil::bin_hex(bytename.val, sizeof(bytename.val), " ")<< endl;
	cout << "akey:" << akey << endl;
	USER_NAME newName;
	newName.frombyte(bytename);
	cout << "newName=" << newName.str() << " hex:" << CBinaryUtil::bin_hex(newName.val, sizeof(newName.val), " ")<< endl;
*/
	return 0;
}
