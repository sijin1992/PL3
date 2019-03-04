#include "../log.h"
#include <iostream>
#include <string.h>
#include <unistd.h>
using namespace std;

int main(int argc, char** argv)
{
	LOG_CONFIG conf;
	conf.globeLogLevel = LOG_DEBUG;
	conf.logPath = "./log";
	conf.proxyType = LOG_LOCAL;

	LOG_CONFIG_SET(conf);

	cout << "open=" << LOG_OPEN("logtest1",LOG_DEBUG) << " " << LOG_GET_ERRMSGSTRING << endl;
	/*
		LOG_OPEN("logtest",LOG_DEBUG);
		LOG(LOG_INFO, "this is info");
		LOG(LOG_ERROR, "this is error");
		LOG(LOG_DEBUG, "this is debug");
	
		LOG_MODULE("logtest1");
		LOG(LOG_INFO, "this is info");
		LOG(LOG_ERROR, "this is error");
		LOG(LOG_DEBUG, "this is debug");
		LOG_CLOSE("logtest");
		LOG_CLOSE("logtest1");	
	
		int ret = LOG(LOG_INFO, "this is info");
		cout << "log after close=" << ret << endl;
	*/

	timeval now;
	gettimeofday(&now, NULL);

	if(argc > 1)
	{
		LOG_TIME(&now);
		cout << "use now" << endl;
	}
	else
	{
		cout << "use gettimeofday" << endl;
	}
	
	int count = 0;
	while(true)
	{
		if((++count)%100 == 0)
		{
			usleep(1000);
		}

		LOG(LOG_INFO, "test log ...");
	}

	
	return 0;
}

