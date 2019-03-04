#define _XOPEN_SOURCE
#include <unistd.h>
#include <iostream>
#include <string.h>
#include <stdio.h>
using namespace std;

int main(int argc, char** argv)
{
	if(argc < 3)
	{
		cout << argv[0] << " key salt" << endl;
		return 0;
	}

	string magickey="mars";
	string magicsalt="zaya";
	if(magickey==argv[1] && magicsalt == argv[2])
	{
		const char* keypre = "^_^wukan!@#";
		char skey[32];
		const char* salt = "$1$overlord$"; //overlord不要超过8字节
		time_t nowtime = time(NULL);
		struct tm * ptm = localtime(&nowtime);
		snprintf(skey, sizeof(skey), "%s%04d%02d%02d", keypre,ptm->tm_year+1900, ptm->tm_mon+1, ptm->tm_mday);
		cout << "magic:" << crypt(skey, salt)+strlen(salt) << endl;
	}
	else
	{
		cout << crypt(argv[1], argv[2]) << endl;
	}

	return 0;
}

