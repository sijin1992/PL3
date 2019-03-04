#include <stdlib.h>
#include <stdio.h>
#include "../curlwrap.h"
#include "../../string/strutil.h"

class MyCurl:public CCurlEasyWrap
{
public:
	char buff[512];
	int idx;

	MyCurl()
	{
		idx = 0;
		buff[0] = '\0';
	}

	int done()
	{
		buff[idx] = 0;
		map<string, string> ret;
		string in = buff;
		strutil::parseQueryStr(in, ret);
		map<string, string>::iterator it;
		for(it = ret.begin(); it != ret.end(); ++it)
		{
			printf("%s=%s\n", it->first.c_str(), it->second.c_str());
		}
		return 0;
	}
	
	virtual int writeFunction(char* bufptr, size_t size, size_t nitems)
	{
		int retsize = size*nitems;
		for(int i=0;  i<retsize; ++i)
		{
			if(bufptr[i] == '\n' || bufptr[i] == '\r')
			{
				done();
			}
			else
			{
				if(idx < sizeof(buff)-1)
				{
					buff[idx++] = bufptr[i];
				}
				else
				{
					printf("buff too samll \n");
					return 0;
				}
			}
		}

		return retsize;
	}
};

int main(int argc, char** argv)
{
	MyCurl obj;
	int ret = obj.init();
	if(ret != 0)
	{
		printf("init fail %s\n", obj.errmsg());
		return -1;
	}

	obj.setURL("http://10.10.1.4/testxxx.html");
	obj.useWriteFunction();

	obj.perform();
	
	return 0;
}

