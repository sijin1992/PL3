#include "../simplejson.h"
#include <iostream>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

using namespace std;

int main(int argc, char** argv)
{
	if(argc < 2)
	{
		cout << argv[0] << " jsonFileName" << endl;
		return -1;
	}
	
	CSimpleJSON ojson;

	char jsonbuff[1024];
	int fd = open(argv[1], O_RDONLY);
	if(fd < 0)
	{
		cout << "open " << argv[1] << " fail" << endl;
		return -1;
	}

	int len = read(fd, jsonbuff, sizeof(jsonbuff));
	if(len < 0)
	{
		cout << "read " << argv[1] << " fail" << endl;
		return -1;
	}
	else if(len > (int)sizeof(jsonbuff)-1)
	{
		cout << "read " << argv[1] << " buff(" << sizeof(jsonbuff) << ") too samll" << endl;
		return -1;
	}

	jsonbuff[len] = 0;
	string strjson = jsonbuff;

	ojson.test_parse(strjson);
	
	return 0;
}

