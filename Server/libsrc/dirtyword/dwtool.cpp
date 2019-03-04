#include "dirtyword.h"
#include <iostream>
#include <stdlib.h>
#include <string.h>
using namespace std;

int main(int argc, char** argv)
{
	if(argc < 3)
	{
		cout << argv[0] << " dirtyWordFile srcStr" << endl;
		return -1;
	}

	CDirtyWord dw;
	if(dw.init(argv[1], CDirtyWord::CODE_TYPE_GBK)!=0)
	{
		return -1;
	}

	//dw.debug(cout);
	int arglen = strlen(argv[2]);
	size_t bufflen = arglen*2+1;
	char* buff = new char[bufflen];
	char* outbuff = new char[bufflen];
	size_t buffFree = bufflen-1;
	if(CCodeSet::gbk_utf8(argv[2], arglen, buff, buffFree)!=0)
	{
		cout << "gbk to utf8 fail" << endl;
		return -1;
	}
	
	int datalen = bufflen-1-buffFree;
	buff[datalen] = 0;

	cout << "result: " << dw.filterUtf8(buff, datalen, buff) << endl;

	buffFree = bufflen - 1;
	if(CCodeSet::utf8_gbk(buff, datalen, outbuff, buffFree)!=0)
	{
		cout << "utf8 to gbk fail" << endl;
		return -1;
	}
	outbuff[bufflen-1-buffFree] = 0;
	cout << outbuff << endl;

	return 0;
}

