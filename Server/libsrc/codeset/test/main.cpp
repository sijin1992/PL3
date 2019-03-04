#include "../codeset.h"
#include <iostream>
#include <string.h>
using namespace std;

int main(int argc, char** argv)
{
	char utf8str[256] = {0};
	char gbstr[256] = "你是一个小色狼";
	size_t len = sizeof(utf8str);
	int ret = CCodeSet::gbk_utf8(gbstr, strlen(gbstr), utf8str, len);
	cout << "gbk_utf8 ret=" << ret << " len=" << len << " " << utf8str << endl;
	len = sizeof(gbstr);
	ret = CCodeSet::utf8_gbk(utf8str, strlen(utf8str), gbstr, len);
	cout << "utf8_gbk ret=" << ret << " len=" << len << " " << gbstr << endl;

	len = strlen(gbstr);
	gbstr[len-1] = 0;

	bool b = CCodeSet::CheckValidNameGBK(gbstr, utf8str);
	cout << "CheckValidNameGBK " << b << " " << utf8str << endl;
	
	return 0;
}

